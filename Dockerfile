FROM ghcr.io/google/garf:latest
COPY --from=ghcr.io/astral-sh/uv:0.5.18 /uv /bin/
ENV UV_SYSTEM_PYTHON=1
WORKDIR /app
ADD requirements.txt .
RUN uv pip install -r requirements.txt --require-hashes --no-deps
ADD queries/ queries/
ADD scripts/ scripts/
ADD workflow-config.yaml .
ADD run-docker.sh .
ENV WORKFLOW_FILE=/app/workflow-config.yaml
ENTRYPOINT ["sh", "/app/run-docker.sh"]
CMD ["-w", "/app/workflow-config.yaml", "-l", "local"]
