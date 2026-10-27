import urllib.request
import json

API = "http://localhost:8000"
ids = ["7cc9db12-1c8a-4415-afdd-8cdd26c5ee76", "22eba30a-d991-40d5-800b-78228ac99544"]

for espacio_id in ids:
    data = json.dumps({"deporte": "Vóley"}).encode("utf-8")
    req = urllib.request.Request(
        f"{API}/espacios/{espacio_id}",
        data=data,
        headers={"Content-Type": "application/json"},
        method="PATCH",
    )
    with urllib.request.urlopen(req) as resp:
        print(espacio_id, resp.status, resp.read().decode("utf-8"))
