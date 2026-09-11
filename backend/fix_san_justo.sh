#!/bin/bash
# Actualiza Sede San Justo (ex-Haedo) y sus canchas con datos reales del Figma.
# Corrido una sola vez contra la base de Render vía el backend local.
set -e

API="http://localhost:8000"
SEDE_ID="421faa77-c67d-463e-8f60-a8da01d3f7c4"

echo "== Sede San Justo: dirección y horario =="
curl -s -X PATCH "$API/sedes/$SEDE_ID" \
  -H "Content-Type: application/json" \
  -d '{"direccion": "Av. Casanova 320", "hora_apertura": "08:00:00", "hora_cierre": "23:00:00"}'
echo

echo "== Fútbol 5 - Cancha 1 =="
curl -s -X PATCH "$API/espacios/7597aeb6-65fb-4f7f-b038-f76e0c68086e" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "SanJusto_Casanova_Futbol_F5_Cancha_1",
    "deporte": "Fútbol",
    "subcategoria": "Fútbol 5",
    "ambiente": "Indoor",
    "iluminada": false,
    "precio_por_hora": 4200,
    "hora_apertura": "08:00:00",
    "hora_cierre": "23:00:00"
  }'
echo

echo "== Fútbol 5 - Cancha 2 =="
curl -s -X PATCH "$API/espacios/b7ba1b78-951f-40a6-a9d3-e90408a81350" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "SanJusto_Casanova_Futbol_F5_Cancha_2",
    "deporte": "Fútbol",
    "subcategoria": "Fútbol 5",
    "ambiente": "Outdoor",
    "iluminada": true,
    "precio_por_hora": 3600,
    "hora_apertura": "08:00:00",
    "hora_cierre": "22:00:00"
  }'
echo

echo "== Fútbol 8 - Cancha 1 (nueva) =="
curl -s -X POST "$API/espacios" \
  -H "Content-Type: application/json" \
  -d '{
    "sede_id": "'"$SEDE_ID"'",
    "nombre": "SanJusto_Casanova_Futbol_F8_Cancha_1",
    "deporte": "Fútbol",
    "subcategoria": "Fútbol 8",
    "ambiente": "Outdoor",
    "iluminada": true,
    "precio_por_hora": 6500,
    "hora_apertura": "09:00:00",
    "hora_cierre": "21:00:00",
    "activo": true
  }'
echo

echo "== Tenis Sintético - Cancha 1 =="
curl -s -X PATCH "$API/espacios/28eb3938-ad0e-4fa8-92fb-c62950951672" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "SanJusto_Casanova_Tenis_Sint_Cancha_1",
    "deporte": "Tenis",
    "subcategoria": "Sintético",
    "ambiente": "Indoor",
    "iluminada": true,
    "precio_por_hora": 3200,
    "hora_apertura": "08:00:00",
    "hora_cierre": "23:00:00"
  }'
echo

echo "== Tenis Cancha 2 (sobrante, se borra) =="
curl -s -X DELETE "$API/espacios/6fa588f3-f556-4f13-bc00-ec640417544f"
echo

echo "== Golf Driving Range =="
curl -s -X PATCH "$API/espacios/b60609a4-f2ef-41f2-87a2-4dd9c9944dc4" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "SanJusto_Casanova_Golf_DrivingRange_1",
    "deporte": "Golf",
    "subcategoria": "Driving Range",
    "ambiente": "Outdoor",
    "iluminada": true,
    "precio_por_hora": 1500,
    "hora_apertura": "08:00:00",
    "hora_cierre": "20:00:00"
  }'
echo

echo "== Golf 9 Hoyos (nueva) =="
curl -s -X POST "$API/espacios" \
  -H "Content-Type: application/json" \
  -d '{
    "sede_id": "'"$SEDE_ID"'",
    "nombre": "SanJusto_Casanova_Golf_9Hoyos_1",
    "deporte": "Golf",
    "subcategoria": "9 Hoyos",
    "ambiente": "Outdoor",
    "iluminada": false,
    "precio_por_hora": 4500,
    "hora_apertura": "08:00:00",
    "hora_cierre": "18:00:00",
    "activo": true
  }'
echo

echo "== Listo. Verificando estado final =="
curl -s "$API/espacios?sede_id=$SEDE_ID" | python3 -m json.tool
