# sbx-toolkit

Two tools for running AI coding agents in [Docker Sandboxes](https://github.com/docker/sbx-releases):

- **`sbx-setup`** — set up your local sandbox environment (like applying dotfiles, run once per machine)
- **`sbx-start`** — start a sandbox in any project (reads `.sbx.toml`, one command)

---

## The mental model

Think of it like dotfiles.

Your dotfiles define your shell, editor, and git config — set up once when you get a new machine, shared across every project. You update them when your preferences change, not as part of any project workflow.

`sbx-setup` works the same way for AI sandboxes. It builds a local image with your agent config (`~/.claude`), tool versions (via [mise](https://github.com/jdx/mise)), and any system packages you need — then makes it available to every sandbox on your machine. Every project's `.sbx.toml` just references it by name.

```
Your machine
├── ~/.claude/          ← your agent instructions, commands, plugins
├── mise.toml           ← your preferred tool versions
│
└── sbx-setup           ← run once to bake these into a local image
        ↓
    localhost:5000/sbx-toolkit:mise-claude-code   ← your sandbox environment
        ↓
    used by every project on this machine via .sbx.toml
```

### When to run sbx-setup

- Setting up a new machine
- After updating `~/.claude` (new instructions, plugins, commands)
- After changing your preferred tool versions

**Not** on every project, not in CI, not as part of a build pipeline.

### What lives where

| Thing | Where | Why |
|---|---|---|
| Agent instructions, plugins, commands | `~/.claude` → baked into image via `sbx-setup` | Personal, machine-level |
| Tool versions (node, python, go…) | `mise.toml` in project → read by mise at runtime | Project-level, committed |
| Sandbox settings (agent, network, secrets) | `.sbx.toml` in project → read by `sbx-start` | Project-level, committed |
| Secret values | OS keychain via `sbx secret set` | Never on disk or in images |

---

## Quick start

### 1. Install sbx-start

```bash
curl -fsSL https://raw.githubusercontent.com/maxkrivich/sbx-toolkit/main/install.sh | bash
```

### 2. Set up your local sandbox environment

```bash
git clone https://github.com/maxkrivich/sbx-toolkit
cd sbx-toolkit

# Basic setup — mise template, claude agent
./sbx-setup --agent claude-code

# With your ~/.claude config baked in (recommended)
./sbx-setup --agent claude-code --config ~/.claude

# With a custom Dockerfile
./sbx-setup --dockerfile ./my-template/Dockerfile --agent claude-code
```

After running, `sbx-setup` prints the `template =` line to paste into your `.sbx.toml`.

### 3. Add `.sbx.toml` to your project

```bash
cp .sbx.toml.example /your/project/.sbx.toml
# edit: paste the template image printed by sbx-setup
```

### 4. Start

```bash
cd /your/project
sbx-start
```

---

## sbx-setup

Builds your local sandbox environment and makes it available to sbx.
Run this once per machine, and again whenever you update your agent config.

```
./sbx-setup [options]

Options:
  --template <name>      Template from templates/ (default: mise)
  --dockerfile <path>    Custom Dockerfile (overrides --template)
  --agent <variant>      Base image variant (default: claude-code)
  --tag <image:tag>      Output image tag (auto-generated if omitted)
  --config <path>        Agent config dir to bake in (e.g. ~/.claude)
  --config-target <path> Where config lands in image (default: /home/agent/.claude)
  --registry <host:port> Registry to use (default: localhost:5000)
  --no-push              Build only, skip push
  --dry-run              Print commands without running
```

### Examples

```bash
# Minimal
./sbx-setup

# With your claude config
./sbx-setup --config ~/.claude

# Codex instead of claude
./sbx-setup --agent codex --config ~/.codex --config-target /home/agent/.codex

# Custom Dockerfile
./sbx-setup --dockerfile ./templates/my-stack/Dockerfile --agent claude-code

# Preview without running
./sbx-setup --config ~/.claude --dry-run
```

### Updating your environment

When you change `~/.claude`, just re-run:

```bash
./sbx-setup --config ~/.claude
```

This rebuilds and repushes the image. Next time you run `sbx-start` in any
project, sbx pulls the updated image automatically.

---

## sbx-start

Reads `.sbx.toml` from the current directory and starts a sandbox. Handles
network policy, secret checks, and custom allow/block rules before handing
off to `sbx`.

```bash
sbx-start           # start sandbox
sbx-start --dry-run # preview without running
sbx-start --help
```

### `.sbx.toml` reference

Commit this file to your project repo. All fields under `[sandbox]`.

| Field | Required | Default | Description |
|---|---|---|---|
| `agent` | ✅ | — | `claude`, `codex`, `kiro`, `shell`, etc. |
| `template` | ✅ | — | Paste the exact image reference printed by `sbx-setup` |
| `network_policy` | | `balanced` | `open`, `balanced`, or `locked-down` |
| `branch` | | — | `auto` or branch name. Omit for direct mode. |
| `required_secrets` | | — | Secret names to check. Missing ones warn, don't block. |
| `allowed_domains` | | — | Extra domains to allow on top of base policy. |
| `blocked_domains` | | — | Domains to block even if base policy allows them. |
| `extra_workspaces` | | — | Extra paths to mount into the sandbox. |

See [`.sbx.toml.example`](./.sbx.toml.example) for a fully annotated example.

### Network policy layering

```
network_policy  (base)
      ↓
allowed_domains (additive)
      ↓
blocked_domains (always wins)
```

### Secrets

Secret values are never in `.sbx.toml`. `required_secrets` lists only names.
`sbx-start` checks `sbx secret ls` and warns if any are missing:

```
WARNING: The following secrets are not set:
  - GITHUB_TOKEN  (run: sbx secret set GITHUB_TOKEN)
```

Set once per machine — stored in OS keychain, injected by sbx proxy at runtime:

```bash
sbx secret set GITHUB_TOKEN
```

---

## Templates

Templates are Dockerfiles under `templates/`. Two are provided out of the box:

| Template | Description |
|---|---|
| `base` | Thinnest valid starting point. Extend this when you want full control. |
| `mise` | Adds [mise](https://github.com/jdx/mise) for polyglot version management. Reads `mise.toml` / `.tool-versions` automatically. |

### Writing your own

Create `templates/my-template/Dockerfile` and extend the official base directly:

```dockerfile
ARG AGENT=claude-code
FROM docker/sandbox-templates:${AGENT}
ARG AGENT=claude-code

USER root
RUN apt-get update && apt-get install -y my-tool \
    && rm -rf /var/lib/apt/lists/*
USER agent
```

Then set it up:

```bash
./sbx-setup --template my-template --agent claude-code
```

See [`templates/README.md`](./templates/README.md) for full guidance and examples.

---

## Onboarding a new developer

```bash
# 1. Install sbx
#    https://github.com/docker/sbx-releases

# 2. Install sbx-start
curl -fsSL https://raw.githubusercontent.com/your-org/sbx-toolkit/main/install.sh | bash

# 3. Set up your local sandbox environment
git clone https://github.com/maxkrivich/sbx-toolkit
cd sbx-toolkit
./sbx-setup --agent claude-code --config ~/.claude

# 4. Set secrets (sbx-start will tell you exactly which ones are needed)
sbx secret set ANTHROPIC_API_KEY

# 5. Start any project
cd /your/project
sbx-start
```

---

## Repo structure

```
sbx-toolkit/
├── sbx-setup              # Machine setup — builds your local sandbox environment
├── sbx-start              # Project runner — reads .sbx.toml, starts sandbox
├── install.sh             # curl installer for sbx-start
├── .sbx.toml.example      # Copy into your project and fill in
├── templates/
│   ├── mise/
│   │   └── Dockerfile     # mise version manager
│   └── README.md          # How to write your own template
└── README.md
```

---

## Contributing

Issues and PRs welcome. Design goals:

- **Zero opinions forced** — every default can be overridden
- **No runtime dependencies** — pure bash, no jq, python, or node required
- **Dotfiles-style UX** — setup once, forget about it, update when you need to
- **Safe by default** — secrets never touch the filesystem or image layers

---

## License

MIT
