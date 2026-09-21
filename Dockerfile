FROM python:3.11-slim-bookworm

ENV PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    SESSION_DIR=/app/data

RUN apt-get update \
 && apt-get install -y --no-install-recommends ffmpeg aria2 gcc libc6-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt \
 && apt-get purge -y gcc libc6-dev && apt-get autoremove -y

COPY bot.py .
RUN mkdir -p /app/data /app/downloads /app/temp /app/torrents

CMD ["python", "bot.py"]
