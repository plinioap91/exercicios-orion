FROM python:3.12-slim AS base

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8000

FROM base AS dev

COPY src/ .

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000", "--reload", "--reload-dir", "/app"]

FROM base AS prod

RUN useradd --uid 10001 --user-group --no-create-home appuser

COPY --chown=appuser:appuser src/ .

USER appuser

CMD ["uvicorn", "app:app", "--host", "0.0.0.0", "--port", "8000"]
