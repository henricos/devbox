# Agent context: devbox

## What this repository is

A Docker image that packages a complete set of development tools (Node, Python, git, gh, Docker CLI, Postgres client, Playwright, etc.) into a persistent, SSH-accessible workstation. The image is designed to run 24/7 in a homelab environment and is published to GHCR via GitHub Actions. No AI application (Claude Code or any other) comes pre-installed — that is left to whoever runs the container.

## Context and references

Before deciding on conventions, flows or rules, check `docs/`. What is documented there is normative: it prevails over assumptions and must be followed. If a decision changes something already documented, update the corresponding document.

For general orientation:

- `README.md` — high-level view for humans; points to `docs/` when something needs detail.
- `docs/` — architectural and technical decisions and cross-cutting procedures of the project.

## Tool-agnostic AI strategy

This project adopts a tool-agnostic strategy so that any AI coding tool can load the same operational rules without duplicating instructions.

**Editable source of truth:** `AGENTS.md` — operational rules common to any agent.

Compatibility files such as `CLAUDE.md` are only pointers to that source of truth. Never edit a pointer directly when the intent is to change a rule — edit `AGENTS.md` instead.

**How each tool loads the instructions:**

- **Claude Code** — loads the rules through `CLAUDE.md`, which includes `@AGENTS.md` and must not be edited directly.
- **Cursor** — reads `AGENTS.md` as its native instructions file.
- **Codex CLI / other tools** — read `AGENTS.md` directly.

## Language

The repository is written entirely in **English**: code, comments, configuration, documentation (`README.md`, `docs/`), commit messages, and operator-facing runtime output (logs, `echo` messages, CLI errors, test output).

Chat communication with the operator follows the operator's language (pt-BR).

In pt-BR text for humans (chat), avoid overusing the em dash ("—") to interleave asides mid-sentence; prefer commas or parentheses, as a pt-BR copywriter normally would. This is not a ban: the em dash remains correct in dialogue, titles and occasional emphasis; the problem is repetitive, unidiomatic use. In Markdown lists and bullets, use a hyphen ("-").

## Tests

This repository has no application code — the "test" is validating that the built image works as expected. All functional verification happens through the smoke test in `test/smoke.sh`: it builds the image locally, starts a container, confirms `sshd` is up, that the expected tools are present under the correct user, and tears the container down. See `docs/testing.md` for exactly what is validated and when to run it. Running the smoke test is a mandatory precondition of the release flow (`docs/release.md`).

## Commits

- Messages always in **English**.
- **Conventional Commits** format: `type: concise subject` (subject up to ~72 characters).
- Valid types: `feat`, `fix`, `docs`, `refactor`, `chore`.
- Subject and body in the imperative mood, describing what the commit does: `add`, `fix`, `update`, `remove`, `refactor`, `document`.
- Body required, with a short paragraph summarizing the goal of the change and a bullet list describing the changes made.
- Before running `git push`, present the proposal and wait for explicit operator approval.
- Use explicit files in `git add`; never broad staging like `git add .`.
- If there are files unrelated to the task outside staging, ask the operator what to do. Never mention pending files in the commit message.
- **NEVER** add AI authorship or attribution trailers (e.g. `Co-Authored-By`, as Claude Code inserts by default), regardless of the tool in use.
- `git push` may be blocked by the tool's sandbox. If that happens, run the push outside the sandbox — do not delegate it to the operator because of a network failure.
