#!/bin/bash
# genera logs de nube simulados cada 2 segundos

ARCHIVO="cloud-logs/eventos-nube.json"
NIVELES=("INFO" "WARNING" "ERROR")
ACCIONES=("LoginUsuario" "SubirArchivo" "EliminarArchivo" "ReiniciarServicio" "ErrorConexion")

while true; do
  NIVEL=${NIVELES[$RANDOM % 3]}
  ACCION=${ACCIONES[$RANDOM % 5]}
  FECHA=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  echo "{\"eventTime\":\"$FECHA\",\"eventName\":\"$ACCION\",\"severity\":\"$NIVEL\",\"user\":\"sebastian\"}" >> $ARCHIVO

  sleep 2
done
