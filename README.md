# Kubernetes Temelleri ve Uygulamalı Yönetim Eğitimi — Lab Deposu

3 günlük Kubernetes eğitiminin tüm lab dosyaları (YAML, Dockerfile, script'ler) ve tarayıcıdan çalışan hazır ortam (GitHub Codespaces).

📘 **Ana doküman:** [docs/Ogrenci-Kurulum-ve-Lab-Kilavuzu.md](docs/Ogrenci-Kurulum-ve-Lab-Kilavuzu.md) — kurulum, tüm lab adımları ve açıklamalar.

---

## 1. Başlarken — iki yoldan birini seçin

### Yol 1 (Varsayılan): Kendi bilgisayarınızda

1. Kılavuzun **Bölüm 1–4**'üne göre ortamınızı kurun (Windows / macOS / Linux).
2. Depoyu **tam olarak `~/k8s-lab` klasörüne** klonlayın — kılavuzdaki tüm `cd ~/k8s-lab/...` komutları bu yola göre yazılmıştır:

   ```bash
   git clone https://github.com/sauddade/k8s-egitim.git ~/k8s-lab
   cd ~/k8s-lab
   ```

3. Cluster'ı başlatın, imajları indirin, doğrulayın:

   ```bash
   bash scripts/start-cluster.sh          # 8 GB RAM'li makinede: bash scripts/start-cluster.sh dusuk
   docker login                           # ücretsiz Docker Hub hesabı
   bash scripts/preload-images.sh
   bash scripts/verify-setup.sh           # çıktının ekran görüntüsünü eğitmene gönderin
   ```

> **Windows Yol C (Git Bash + Hyper-V/VirtualBox):** `MINIKUBE_DRIVER=hyperv bash scripts/start-cluster.sh` (veya `virtualbox`).

### Yol 2 (Yedek): GitHub Codespaces — sadece tarayıcı

Bilgisayarınıza kurulum yapamıyorsanız (admin yetkisi yok, WSL2/Docker engelli):

1. Kişisel GitHub hesabınızla giriş yapın.
2. Bu sayfada **Code → Codespaces → ⋯ → New with options** → Machine type: **4-core** → **Create codespace**.
3. İlk açılış 5–8 dk sürer; Docker, minikube, kubectl, helm kurulur ve cluster **otomatik başlar**.
4. Terminalde: `kubectl get nodes` → `Ready` görmelisiniz. Ardından: `bash scripts/preload-images.sh`

Bilmeniz gerekenler:
- `~/k8s-lab` yolu otomatik olarak bu depoya bağlanır — kılavuzdaki komutlar aynen çalışır.
- Ücretsiz kota (kişisel hesap): ayda 120 core-saat ≈ 4-core makinede 30 saat. **Her gün sonunda codespace'i durdurun:** github.com/codespaces → ⋯ → *Stop codespace*.
- Tarayıcıda açmak istediğiniz servisler için `kubectl port-forward` kullanın; port **PORTS** sekmesinde görünür → 🌐 simgesine tıklayın.
- `minikube service` ve `minikube tunnel` yerine her zaman `kubectl port-forward` kullanın.

---

## 2. Klasör Yapısı

| Klasör / Dosya | İçerik | Kılavuz |
|---|---|---|
| `scripts/start-cluster.sh` | Standart cluster: Calico CNI + metrics-server + ingress | Bölüm 6 |
| `scripts/preload-images.sh` | Eğitim imajlarını önceden indirip minikube'e yükler | Bölüm 6 |
| `scripts/verify-setup.sh` | Kurulum doğrulama | Bölüm 7 |
| `scripts/build-demo-images.sh` | `k8s-demo-app:v1 / v2 / v3-bad` imajlarını üretir | Lab 3.0 |
| `scripts/cleanup.sh` | Gün sonu temizliği (`gun1` / `gun2` / `gun3`) | Bölüm 12 |
| `day1/` | `app.py`, `Dockerfile`, `Dockerfile.multistage`, `Dockerfile.leaky`, `docker-compose.yml`, `deployment.yaml`, `my-app.yaml` | Lab 1.2 – 1.10 |
| `day2/` | Service, Ingress, NetworkPolicy, PV/PVC, StatefulSet, RBAC dosyaları + `create-user-ayse.sh` | Lab 2.4 – 2.11 |
| `day3/` | Helm values, rollout/probe, blue-green, resource/OOM, quota, log, PSA dosyaları | Lab 3.1 – 3.9 |
| `final/` | Final senaryosu için çalışma klasörünüz | Bölüm 11 |
| `.devcontainer/` | GitHub Codespaces yapılandırması | — |

Lab dosyaları kılavuzdaki `cat > dosya.yaml << 'EOF'` bloklarıyla **birebir aynıdır**. İsterseniz kılavuzdaki komutla dosyayı yeniden oluşturabilir, isterseniz doğrudan depodaki dosyayı kullanabilirsiniz:

```bash
cd ~/k8s-lab/day2
kubectl apply -f web-with-svc.yaml
```

---

## 3. 🔐 Güvenlik Notları

- `day1/Dockerfile.leaky` ve `day2/hostpath-escape.yaml` **kasıtlı olarak güvensizdir** — sadece eğitim cluster'ında, eğitim amacıyla kullanın.
- `day2/create-user-ayse.sh` özel anahtar üretir; `*.key`, `*.crt`, `*.csr` dosyaları `.gitignore` ile commit dışıdır. Fork'unuza yanlışlıkla eklemeyin.
- Codespace'e şirket verisi veya kimlik bilgisi koymayın.
- Lab'larda kullanılan şifreler (`s3cr3t`, `SuperGizli123` vb.) örnektir; gerçek sistemlerde kullanmayın.

---

## 4. Sık Karşılaşılan Sorunlar

| Belirti | Çözüm |
|---|---|
| `Docker Desktop has only XXXX MB memory` / bellek hatası | Docker'a ayrılan belleği artırın veya `bash scripts/start-cluster.sh dusuk` |
| `x509: certificate signed by unknown authority` | Kurumsal SSL inspection — kılavuz Bölüm 1.4 |
| `toomanyrequests` (Docker Hub) | `docker login` + `bash scripts/preload-images.sh` |
| NetworkPolicy hiçbir şeyi engellemiyor | Cluster Calico'suz başlatılmış: `minikube delete && bash scripts/start-cluster.sh` |
| Windows'ta `bash\r: command not found` | Depo CRLF ile klonlanmış: `git config --global core.autocrlf false` ve yeniden klonlayın |
| Git Bash'te `/etc/...` yolları bozuluyor | `export MSYS_NO_PATHCONV=1` (kılavuz Bölüm 2.3) |
