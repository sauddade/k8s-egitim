# Lab 1.2 — Temel Dockerfile
# Base image (sürümü sabitlenmiş — :latest kullanmıyoruz)
FROM python:3.11-slim

# Çalışma dizini ayarla
WORKDIR /app

# Önce bağımlılıklar: app.py değiştiğinde bu katman cache'den gelir
RUN pip install --no-cache-dir flask==3.0.3

# Uygulama kodunu kopyala
COPY app.py .

# Build-time parametreler (Gün 3'te v2 ve hatalı v3 sürümlerini üretmek için)
ARG APP_VERSION=1.0
ARG BROKEN=false
ENV APP_VERSION=${APP_VERSION} BROKEN=${BROKEN}

# 🔐 Root olmayan kullanıcı — NUMERİK UID (Kubernetes runAsNonRoot bunu doğrulayabilir)
RUN useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin appuser
USER 10001

# Container'ın dinlediği port (dokümantif — gerçekte publish etmez)
EXPOSE 5000

# Container başladığında çalışacak komut
CMD ["python", "app.py"]
