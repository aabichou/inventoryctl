FROM ghcr.io/astral-sh/uv:bookworm-slim

RUN uv tool install inventoryctl

ENTRYPOINT ["inventoryctl"]