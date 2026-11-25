# Final Senaryosu — Çalışma Klasörü

Görev listesi ve doğrulama komutları: `docs/Ogrenci-Kurulum-ve-Lab-Kilavuzu.md` → **Bölüm 11**.

YAML dosyalarınızı bu klasöre yazın. `day1/`, `day2/`, `day3/` klasörlerindeki dosyaları başlangıç noktası olarak kopyalayabilirsiniz.

Yardımcı komutlar:

```bash
kubectl explain deployment.spec.template.spec.securityContext
kubectl create deployment final-app --image=k8s-demo-app:v1 --dry-run=client -o yaml > 02-deploy.yaml
kubectl create service clusterip final-svc --tcp=80:5000 --dry-run=client -o yaml
```
