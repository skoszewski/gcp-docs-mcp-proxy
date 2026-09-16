FROM python:3.12-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends tini jq \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY proxy.py .
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh

EXPOSE 8989

ENTRYPOINT ["tini", "--", "./entrypoint.sh"]
