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
  let tools = [...originalTools];
  const pi = {
    registerCommand(name, { handler }) { commands[name] = handler; },
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
    model: { provider: "provider", id: "model" },
    thinkingLevel: "high",
    sessionManager: { getEntries: () => entries },
    async waitForIdle() {},
    ui: {
      setStatus() {},
      notify(text) { notifications.push(text); },
      async editor() { return "Task: fix bug\nChecks: make test passed"; },
    },
  };
  workflow(pi);
  return { commands, events, messages, notifications, pi, ctx };
}

test("plan limits model tools, keeps the prompt in chat and restores the prior selection", async () => {
  const entries = [];
  const { commands, events, messages, pi, ctx } = fixture(entries);
  await commands.plan("Fix the bug", ctx);
  assert.deepEqual(pi.getActiveTools(), ["read", "grep", "find"]);
  assert.match(messages[0], /Task: Fix the bug/);
  assert.equal(events.tool_call({ toolName: "ls" }).block, true);
  assert.equal(events.tool_call({ toolName: "bash" }).block, true);
  assert.equal(events.tool_call({ toolName: "codemode" }).block, true);
  assert.equal(events.tool_call({ toolName: "read" }), undefined);
  assert.equal(events.input({ text: "/implement" }, ctx).action, "handled");
  pi.setActiveTools(["bash"]);
  events.before_agent_start({ systemPromptOptions: { promptGuidelines: [] } });
  assert.deepEqual(pi.getActiveTools(), ["read", "grep", "find"]);

  const resumed = fixture(entries);
  resumed.events.session_start({}, resumed.ctx);
  assert.deepEqual(resumed.pi.getActiveTools(), ["read", "grep", "find"]);
  await resumed.commands["plan-exit"]("", resumed.ctx);
  assert.deepEqual(resumed.pi.getActiveTools(), originalTools);
  assert.equal(resumed.events.input({ text: "/implement" }, resumed.ctx), undefined);
  assert.deepEqual(resumed.messages, []);
});

test("review uses the tracked diff and check evidence without triggering an implementation turn", async () => {
  const { commands, messages, pi, ctx } = fixture();
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
  await commands["review-independent"]("main", ctx);
  assert.deepEqual(calls[0], ["git", ["rev-parse", "--verify", "--end-of-options", "main^{commit}"]]);
  assert.deepEqual(calls[1][1].slice(-2), [hash, "--"]);
  assert.deepEqual(calls[2][1].slice(0, 13), ["--print", "--no-session", "--no-extensions", "--no-mcp", "--no-skills",
    "--no-prompt-templates", "--no-context-files", "--tools", "read,grep,find,ls", "--model", "provider/model", "--thinking", "high"]);
  assert.deepEqual(messages, [{ customType: "independent-review", display: true, content: "## Independent review\n\nNo findings." }]);
  await assert.rejects(readFile(evidence), { code: "ENOENT" });
});

test("review stops before calling Pi when the diff is empty or the user cancels", async () => {
  const { commands, notifications, pi, ctx } = fixture();
  let diff = "";
  pi.exec = async (command, args) => {
    assert.equal(command, "git");
    return { code: 0, stdout: args[0] === "rev-parse" ? hash : diff };
  };
  ctx.ui.editor = async () => undefined;
  await commands["review-independent"]("", ctx);
  assert.match(notifications[0], /No tracked changes/);
  diff = "some tracked changes";
  await commands["review-independent"]("", ctx);
  assert.equal(notifications.length, 1);
});
