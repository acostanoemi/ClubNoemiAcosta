$base = "http://localhost:8000"

$sedes = Invoke-RestMethod -Uri "$base/sedes" -Method Get
$castelar = $sedes | Where-Object { $_.nombre -eq "Castelar" }
Write-Output "Sede Castelar: $($castelar.id)"

$espacios = Invoke-RestMethod -Uri "$base/espacios" -Method Get
$deCastelar = $espacios | Where-Object { $_.sede_id -eq $castelar.id }

$tenis = @($deCastelar | Where-Object { $_.deporte -eq "Tenis" })
$voley = @($deCastelar | Where-Object { $_.deporte -eq "Voley" })
$hockey = @($deCastelar | Where-Object { $_.deporte -eq "Hockey" })

Write-Output "--- Antes de tocar nada ---"
Write-Output "Tenis encontrados: $($tenis.Count)"
$tenis | ForEach-Object { Write-Output "  $($_.id) | $($_.nombre) | $($_.precio_por_hora)" }
Write-Output "Voley encontrados: $($voley.Count)"
$voley | ForEach-Object { Write-Output "  $($_.id) | $($_.nombre) | $($_.precio_por_hora)" }
Write-Output "Hockey encontrados: $($hockey.Count)"
$hockey | ForEach-Object { Write-Output "  $($_.id) | $($_.nombre) | $($_.precio_por_hora)" }
Write-Output "---------------------------"

if ($tenis.Count -ne 2 -or $voley.Count -lt 1 -or $hockey.Count -ne 1) {
    Write-Output "CANTIDAD INESPERADA - paro aca, avisale a Claude antes de seguir."
    exit
}

# Tenis 1 -> Polvo de Ladrillo
Invoke-RestMethod -Uri "$base/espacios/$($tenis[0].id)" -Method Patch -ContentType "application/json" -Body (@{
    nombre = "Castelar_Rivadavia_Tenis_Polvo_Cancha_1"
    precio_por_hora = 2700
    subcategoria = "Polvo de Ladrillo"
    ambiente = "Outdoor"
    iluminada = $true
    hora_apertura = "08:00:00"
    hora_cierre = "23:00:00"
} | ConvertTo-Json)

# Tenis 2 -> Cemento
Invoke-RestMethod -Uri "$base/espacios/$($tenis[1].id)" -Method Patch -ContentType "application/json" -Body (@{
    nombre = "Castelar_Rivadavia_Tenis_Cemento_Cancha_1"
    precio_por_hora = 3100
    subcategoria = "Cemento"
    ambiente = "Indoor"
    iluminada = $false
    hora_apertura = "08:00:00"
    hora_cierre = "23:00:00"
} | ConvertTo-Json)

# Voley existente -> Playa
Invoke-RestMethod -Uri "$base/espacios/$($voley[0].id)" -Method Patch -ContentType "application/json" -Body (@{
    nombre = "Castelar_Rivadavia_Voley_Playa_Cancha_1"
    precio_por_hora = 2200
    subcategoria = "Voley Playa"
    ambiente = "Outdoor"
    iluminada = $true
    hora_apertura = "09:00:00"
    hora_cierre = "21:00:00"
} | ConvertTo-Json)

# Voley nuevo -> Indoor Parquet
Invoke-RestMethod -Uri "$base/espacios" -Method Post -ContentType "application/json" -Body (@{
    sede_id = $castelar.id
    nombre = "Castelar_Rivadavia_Voley_Indoor_Cancha_1"
    deporte = "Voley"
    precio_por_hora = 2600
    subcategoria = "Indoor Parquet"
    ambiente = "Indoor"
    iluminada = $true
    hora_apertura = "09:00:00"
    hora_cierre = "22:00:00"
    activo = $true
} | ConvertTo-Json)

# Hockey -> Hockey 11
Invoke-RestMethod -Uri "$base/espacios/$($hockey[0].id)" -Method Patch -ContentType "application/json" -Body (@{
    nombre = "Castelar_Rivadavia_Hockey_H11_Cancha1"
    precio_por_hora = 5000
    subcategoria = "Hockey 11"
    ambiente = "Outdoor"
    iluminada = $true
    hora_apertura = "08:00:00"
    hora_cierre = "22:00:00"
} | ConvertTo-Json)

Write-Output "Listo. Corre GET /espacios para confirmar."