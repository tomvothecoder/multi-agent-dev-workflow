import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import workflow from "../global/pi/workflow.ts";

const originalTools = ["bash", "edit", "read", "mcp__test__mutate"];
const hash = "a".repeat(40);

function fixture(entries = []) {
  const commands = {};
  const events = {};
  const messages = [];
  const notifications = [];
  const delegates = {};
  let tools = [...originalTools];
  const pi = {
    registerCommand(name, { handler }) { commands[name] = handler; },
    registerTool({ name, execute }) { delegates[name] = (params, ctx) => execute("id", params, undefined, undefined, ctx); },
    on(name, handler) { events[name] = handler; },
    getActiveTools: () => tools,
    getAllTools: () => ["read", "grep", "find", "ls", "bash", "edit"].map(name => ({
      name, sourceInfo: { path: name === "ls" ? "override.ts" : `builtin:${name}` },
    })),
    setActiveTools(names) { tools = names; },
    appendEntry(customType, data) { entries.push({ type: "custom", customType, data }); },
    sendUserMessage(text) { messages.push(text); },
    sendMessage(message) { messages.push(message); },
  };
  const ctx = {
    hasUI: true,
    cwd: "/worktree",
    modelRegistry: { getAvailable: () => [
      { provider: "openai-codex", id: "gpt-6.2-sol" },
      { provider: "github-copilot", id: "claude-opus-5.5" },
    ] },
    sessionManager: { getEntries: () => entries, getBranch: () => entries },
    async waitForIdle() {},
    ui: {
      setStatus() {},
      notify(text) { notifications.push(text); },
    },
  };
  workflow(pi);
  return { commands, delegates, events, messages, notifications, pi, ctx };
}

test("plan limits model tools, keeps the prompt in chat and restores the prior selection", async () => {
  const entries = [];
  const { commands, delegates, events, messages, pi, ctx } = fixture(entries);
  await commands.plan("Fix the bug", ctx);
  assert.deepEqual(pi.getActiveTools(), ["read", "grep", "find"]);
  assert.match(messages[0], /Task: Fix the bug/);
  assert.equal(events.tool_call({ toolName: "ls" }).block, true);
  assert.equal(events.tool_call({ toolName: "bash" }).block, true);
  assert.equal(events.tool_call({ toolName: "codemode" }).block, true);
  assert.equal(events.tool_call({ toolName: "read" }), undefined);
  assert.equal((await events.input({ text: "/implement" }, ctx)).action, "handled");
  await assert.rejects(delegates.explorer({ question: "Where?" }, ctx), /disabled in plan mode/);
  pi.setActiveTools(["bash"]);
  events.before_agent_start({ systemPromptOptions: { promptGuidelines: [] } });
  assert.deepEqual(pi.getActiveTools(), ["read", "grep", "find"]);

  const resumed = fixture(entries);
  resumed.events.session_start({}, resumed.ctx);
  assert.deepEqual(resumed.pi.getActiveTools(), ["read", "grep", "find"]);
  await resumed.commands["plan-exit"]("", resumed.ctx);
  assert.deepEqual(resumed.pi.getActiveTools(), originalTools);
  resumed.pi.exec = async () => ({ code: 0, stdout: hash });
  assert.equal(await resumed.events.input({ text: "/implement" }, resumed.ctx), undefined);
  assert.deepEqual(resumed.messages, []);
});

test("review uses the tracked diff and check evidence without triggering an implementation turn", async () => {
  const { delegates, events, messages, pi, ctx } = fixture();
  const calls = [];
  let evidence;
  pi.exec = async (command, args, options) => {
    calls.push([command, args]);
    assert.equal(options.cwd, ctx.cwd);
    if (args[0] === "rev-parse") return { code: 0, stdout: `${hash}\n` };
    if (command === "git") return { code: 0, stdout: "diff --git a/file b/file\n+changed" };
    evidence = args.find(arg => arg.startsWith("@")).slice(1);
    const text = await readFile(evidence, "utf8");
    assert.match(text, /Checks: make test passed/);
    assert.match(text, /\+changed/);
    return { code: 0, stdout: "No findings." };
  };
  await events.input({ text: "/implement" }, ctx);
  const result = await delegates.reviewer({ task: "fix bug", checks: "make test passed" }, ctx);
  assert.deepEqual(calls[0], ["git", ["rev-parse", "--verify", "--end-of-options", "HEAD^{commit}"]]);
  assert.equal(calls[1][1].at(-1), `${hash}^{commit}`);
  assert.deepEqual(calls[2][1].slice(-2), [hash, "--"]);
  assert.deepEqual(calls[3][1].slice(0, 13), ["--print", "--no-session", "--no-extensions", "--no-mcp", "--no-skills",
    "--no-prompt-templates", "--no-context-files", "--tools", "read,grep,find,ls", "--model", "github-copilot/claude-opus-5.5", "--thinking", "high"]);
  assert.deepEqual(result.content, [{ type: "text", text: "No findings." }]);
  assert.deepEqual(messages, []);
  await assert.rejects(readFile(evidence), { code: "ENOENT" });
});

test("review rejects missing evidence and empty or truncated diffs", async () => {
  const { delegates, pi, ctx } = fixture();
  let truncated = false;
  pi.exec = async (command, args) => {
    assert.equal(command, "git");
    if (args[0] === "rev-parse") {
      assert.equal(args.at(-1), "main^{commit}");
      return { code: 0, stdout: hash };
    }
    return { code: 0, stdout: "", truncated };
  };
  await assert.rejects(delegates.reviewer({ task: "fix", checks: " " }, ctx), /actual checks/);
  const review = { task: "fix", checks: "skipped: docs only", base: "main" };
  await assert.rejects(delegates.reviewer(review, ctx), /No tracked changes/);
  truncated = true;
  await assert.rejects(delegates.reviewer(review, ctx), /exceeds 100 KB/);
});

test("explorer uses GPT-6.2 with read-only tools and reports a failed child", async () => {
  const { delegates, pi, ctx } = fixture();
  pi.exec = async (command, args) => {
    assert.equal(command, "pi");
    assert.deepEqual(args.slice(7, 13), ["--tools", "read,grep,find,ls", "--model", "openai-codex/gpt-6.2-sol", "--thinking", "low"]);
    assert.equal(await readFile(args[13].slice(1), "utf8"), "Where is it?");
    return { code: 1, stdout: "" };
  };
  await assert.rejects(delegates.explorer({ question: "Where is it?" }, ctx), /Delegation with openai-codex\/gpt-6\.2-sol failed/);
  ctx.modelRegistry.getAvailable = () => [];
  pi.exec = async () => assert.fail("Must not launch an unavailable model");
  await assert.rejects(delegates.explorer({ question: "Where is it?" }, ctx), /is unavailable/);
});
