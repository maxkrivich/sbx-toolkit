# templates/mise/Dockerfile
#
# Extends the official sandbox base with mise (https://github.com/jdx/mise).
# This is the toolchain-bearing option for projects that want automatic
# activation of mise.toml / .tool-versions.
#
# Build:
#   docker build --build-arg AGENT=claude-code -f templates/mise/Dockerfile .
#
# Extend this in your own Dockerfile:
#   FROM my-org/sandbox:mise
#   USER root
#   RUN apt-get update && apt-get install -y my-tool
#   USER agent

ARG AGENT=claude-code
FROM docker/sandbox-templates:${AGENT}

ARG AGENT=claude-code
ARG CONFIG_TARGET=/home/agent/.claude

LABEL org.opencontainers.image.description="sbx-toolkit mise template (${AGENT})"

USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

USER agent

RUN curl https://mise.run | sh
RUN echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bashrc \
 && echo 'eval "$(~/.local/bin/mise activate bash)"' >> ~/.bash_profile
RUN mkdir -p ~/.config/mise \
 && printf '[settings]\ntrusted_config_paths = ["/workspace"]\n' \
    >> ~/.config/mise/config.toml

# Copy optional agent config (e.g. ~/.claude, ~/.codex).
# The build script normalises the source to agent-config/ in the build context.
# If no config is provided, this is an empty directory and has no effect.
COPY --chown=agent:agent agent-config/ ${CONFIG_TARGET}/
