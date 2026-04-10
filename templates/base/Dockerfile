# templates/base/Dockerfile
#
# The thinnest possible sbx-compatible base layer.
# Extends the official sandbox template for a given agent.
# No opinions beyond what sbx requires.
#
# Build:
#   docker build --build-arg AGENT=claude-code -t my-org/sandbox:base .
#   docker build --build-arg AGENT=claude-code -f templates/base/Dockerfile .
#
# Extend this in your own Dockerfile:
#   FROM my-org/sandbox:base
#   USER root
#   RUN apt-get update && apt-get install -y my-tool
#   USER agent

ARG AGENT=claude-code
FROM docker/sandbox-templates:${AGENT}

# Re-declare so it's available in the build stage
ARG AGENT=claude-code

LABEL org.opencontainers.image.description="sbx-toolkit base template (${AGENT})"
