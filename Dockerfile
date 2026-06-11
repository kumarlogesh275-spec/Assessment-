FROM python:3.12-slim AS builder

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir --target=/install -r requirements.txt

FROM python:3.12-slim

# 1. Create the system user and group
RUN addgroup --system appgroup && adduser --system --ingroup appgroup appuser
WORKDIR /app

# 2. Fix permissions by adding --chown=appuser:appgroup here 👈
COPY --from=builder --chown=appuser:appgroup /install /install
COPY --chown=appuser:appgroup app.py .

ENV PYTHONPATH=/install 

# 3. Prevent Python from trying to write .pyc files to folders it shouldn't
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

USER appuser
EXPOSE 5000
CMD ["python", "app.py"]