FROM ghcr.io/astral-sh/uv:bookworm-slim

RUN uv tool install inventoryctl==0.2.0

ENTRYPOINT ["inventoryctl"]