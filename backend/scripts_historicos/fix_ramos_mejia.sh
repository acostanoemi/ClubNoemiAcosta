#!/bin/bash
# Actualiza Sede Ramos Mejía y sus canchas con datos reales del Figma.
# Corrido una sola vez contra la base de Render vía el backend local.
set -e

API="http://localhost:8000"
SEDE_ID="fad51eb7-a3d8-405e-ab93-ef440566907a"

echo "== Sede Ramos Mejía: nombre y dirección =="
curl -s -X PATCH "$API/sedes/$SEDE_ID" \
  -H "Content-Type: application/json" \
  -d '{"nombre": "Ramos Mejía", "direccion": "Calle Belgrano 1240"}'
echo

echo "== Fútbol 5 - Cancha 1 =="
curl -s -X PATCH "$API/espacios/4902cc11-6599-4df9-9ff1-7943ff2084c3" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "RamosMejia_Belgrano_Futbol_F5_Cancha_1",
    "deporte": "Fútbol",
    "subcategoria": "Fútbol 5",
    "ambiente": "Indoor",
    "iluminada": false,
    "precio_por_hora": 4000,
    "hora_apertura": "09:00:00",
    "hora_cierre": "22:00:00"
  }'
echo

echo "== Fútbol 11 - Cancha 1 =="
curl -s -X PATCH "$API/espacios/9296f4f7-c3d3-4c0f-8694-f118a8dbcd6c" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "RamosMejia_Belgrano_Futbol_F11_Cancha_1",
    "deporte": "Fútbol",
    "subcategoria": "Fútbol 11",
    "ambiente": "Outdoor",
    "iluminada": true,
    "precio_por_hora": 8000,
    "hora_apertura": "09:00:00",
    "hora_cierre": "22:00:00"
  }'
echo

echo "== Hockey 7 - Cancha 1 =="
curl -s -X PATCH "$API/espacios/bfe09c02-0953-4231-b8ab-273ca03a23b1" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "RamosMejia_Belgrano_Hockey_H7_Cancha_1",
    "deporte": "Hockey",
    "subcategoria": "Hockey 7",
    "ambiente": "Outdoor",
    "iluminada": true,
    "precio_por_hora": 3500,
    "hora_apertura": "08:00:00",
    "hora_cierre": "22:00:00"
  }'
echo

echo "== Vóley Indoor - Cancha 1 =="
curl -s -X PATCH "$API/espacios/b594bdbc-c65b-4490-bd10-1b2d6f95e982" \
  -H "Content-Type: application/json" \
  -d '{
    "nombre": "RamosMejia_Belgrano_Voley_Indoor_Cancha_1",
    "deporte": "Vóley",
    "subcategoria": "Indoor Parquet",
    "ambiente": "Indoor",
    "iluminada": true,
    "precio_por_hora": 2800,
    "hora_apertura": "08:00:00",
    "hora_cierre": "23:00:00"
  }'
echo

echo "== Listo. Verificando estado final =="
curl -s "$API/espacios?sede_id=$SEDE_ID" | python3 -m json.tool
