#!/bin/bash
# Actualiza Sede Morón y sus canchas con datos reales del Figma.
# Corrido una sola vez contra la base de Render vía el backend local.
set -e

API="http://localhost:8000"
SEDE_ID="378b6dec-bc98-4664-8ef2-ed6952a14d7d"

echo "== Sede Morón: nombre y dirección =="
curl -s -X PATCH "$API/sedes/$SEDE_ID" \
  -H "Content-Type: application/json" \
  -d '{"nombre": "Morón", "direccion": "Av. Rivadavia 17500"}'
echo

echo "== Fútbol 5 - Cancha 1 =="
curl -s -X PATCH "$API/espacios/55be2bbf-26fe-429e-a6b3-11cf70de9df3" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Moron_Rivadavia_Futbol_F5_Cancha_1",
    "deporte": "Fútbol",
    "subcategoria": "Fútbol 5",
    "ambiente": "Outdoor",
    "iluminada": true,
    "precio_por_hora": 3800,
    "hora_apertura": "08:00:00",
    "hora_cierre": "23:00:00"
  }'
echo

echo "== Fútbol 5 - Cancha 2 =="
curl -s -X PATCH "$API/espacios/2da25c26-7a1b-4a2c-9c25-1f5695c00105" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Moron_Rivadavia_Futbol_F5_Cancha_2",
    "deporte": "Fútbol",
    "subcategoria": "Fútbol 5",
    "ambiente": "Indoor",
    "iluminada": false,
    "precio_por_hora": 4200,
    "hora_apertura": "08:00:00",
    "hora_cierre": "23:00:00"
  }'
echo

echo "== Fútbol 7 - Cancha 1 (nueva) =="
curl -s -X POST "$API/espacios" \
  -H "Content-Type: application/json" \
  -d '{
    "sede_id": "'"$SEDE_ID"'",
    "nombre": "Moron_Rivadavia_Futbol_F7_Cancha_1",
    "deporte": "Fútbol",
    "subcategoria": "Fútbol 7",
    "ambiente": "Outdoor",
    "iluminada": true,
    "precio_por_hora": 5500,
    "hora_apertura": "08:00:00",
    "hora_cierre": "22:00:00",
    "activo": true
  }'
echo

echo "== Fútbol 11 - Cancha 1 (nueva) =="
curl -s -X POST "$API/espacios" \
  -H "Content-Type: application/json" \
  -d '{
    "sede_id": "'"$SEDE_ID"'",
    "nombre": "Moron_Rivadavia_Futbol_F11_Cancha_1",
    "deporte": "Fútbol",
    "subcategoria": "Fútbol 11",
    "ambiente": "Outdoor",
    "iluminada": true,
    "precio_por_hora": 9000,
    "hora_apertura": "09:00:00",
    "hora_cierre": "21:00:00",
    "activo": true
  }'
echo

echo "== Tenis Polvo de Ladrillo - Cancha 1 =="
curl -s -X PATCH "$API/espacios/af12bc3f-952d-4adf-824b-9a69ee56b735" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Moron_Rivadavia_Tenis_Polvo_Cancha_1",
    "deporte": "Tenis",
    "subcategoria": "Polvo de Ladrillo",
    "ambiente": "Outdoor",
    "iluminada": true,
    "precio_por_hora": 2500,
    "hora_apertura": "08:00:00",
    "hora_cierre": "23:00:00"
  }'
echo

echo "== Tenis Polvo de Ladrillo - Cancha 2 =="
curl -s -X PATCH "$API/espacios/a058eb59-689b-429e-a5dd-dc5781d70b95" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "Moron_Rivadavia_Tenis_Polvo_Cancha_2",
    "deporte": "Tenis",
    "subcategoria": "Polvo de Ladrillo",
    "ambiente": "Outdoor",
    "iluminada": false,
    "precio_por_hora": 2500,
    "hora_apertura": "08:00:00",
    "hora_cierre": "22:00:00"
  }'
echo

echo "== Tenis Cemento - Cancha 1 (nueva) =="
curl -s -X POST "$API/espacios" \
  -H "Content-Type: application/json" \
  -d '{
    "sede_id": "'"$SEDE_ID"'",
    "nombre": "Moron_Rivadavia_Tenis_Cemento_Cancha_1",
    "deporte": "Tenis",
    "subcategoria": "Cemento",
    "ambiente": "Indoor",
    "iluminada": true,
    "precio_por_hora": 3000,
    "hora_apertura": "08:00:00",
    "hora_cierre": "23:00:00",
    "activo": true
  }'
echo

echo "== Listo. Verificando estado final =="
curl -s "$API/espacios?sede_id=$SEDE_ID" | python3 -m json.tool
