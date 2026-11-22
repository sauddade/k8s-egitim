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
