# Templates

Templates are Dockerfiles that extend the official `docker/sandbox-templates`
base images. Each template defines what tools are pre-installed in every sandbox.

## Provided templates

| Template | Description |
|---|---|
| `base` | Thinnest valid starting point. No opinionated tooling. |
| `mise` | Adds [mise](https://github.com/jdx/mise) for polyglot version management. Accepts an optional agent config directory. |

## Building a template

Use `sbx-setup` from the repo root:

```bash
# Build the mise template for claude
./sbx-setup --template mise --agent claude-code --dry-run

# Build the base template for codex
./sbx-setup --template base --agent codex --dry-run

# Build a custom template from any path
./sbx-setup --dockerfile ./my-templates/custom/Dockerfile --agent claude-code --dry-run
```

## Writing your own template

Create a new directory under `templates/` with a `Dockerfile`:

```
templates/
└── my-template/
    └── Dockerfile
```

### Rules

**Prefer extending the official base directly for new templates:**

```dockerfile
# Extend official base directly
ARG AGENT=claude-code
FROM docker/sandbox-templates:${AGENT}
ARG AGENT=claude-code   # re-declare after FROM
```

**Switch to `root` for system packages, back to `agent` before the end:**

```dockerfile
USER root
RUN apt-get update && apt-get install -y my-tool \
    && rm -rf /var/lib/apt/lists/*
USER agent
```

**Install user-level tools as `agent`:**

```dockerfile
USER agent
RUN curl -something | sh   # installs to ~/.local/
```

**Never hardcode secrets or credentials** in the Dockerfile. Use `sbx secret set`
on the host and let the sbx proxy inject them.

Use `mise` when the template should manage project tool versions automatically.
Use `base` when you want the thinnest possible image and will install tools
yourself in an extension layer.

### Example: Rust + protobuf template

```dockerfile
ARG AGENT=claude-code
FROM docker/sandbox-templates:${AGENT}
ARG AGENT=claude-code

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    protobuf-compiler \
    && rm -rf /var/lib/apt/lists/*

USER agent
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/home/agent/.cargo/bin:${PATH}"
```

### Example: Extend mise template with extra tools

```dockerfile
FROM my-org/sandbox:mise   # inherits mise + agent config

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    postgresql-client \
    redis-tools \
    && rm -rf /var/lib/apt/lists/*
USER agent
```

## Agent / template mapping

The `AGENT` build arg must match a valid `docker/sandbox-templates` tag.
The sbx agent name (used in `sbx run`) is derived by stripping `-code` and `-docker` suffixes.

| `AGENT=` | `sbx run` agent | Notes |
|---|---|---|
| `claude-code` | `claude` | Default |
| `claude-code-docker` | `claude` | Includes Docker Engine inside sandbox |
| `codex` | `codex` | |
| `codex-docker` | `codex` | |
| `kiro-docker` | `kiro` | |
| `shell` | `shell` | No agent, just bash |
