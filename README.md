# observabilidad-stack-infra

Práctica Final Integradora: stack de observabilidad de código abierto levantado por completo con Docker Compose, que cubre los tres pilares:

| Pilar | Herramientas |
|---|---|
| Métricas | Prometheus, Node Exporter, SNMP Exporter y un agente SNMP simulado (`router_sim`) |
| Logs | Loki y Promtail (pipeline JSON sobre logs de nube simulados) |
| Trazas | OpenTelemetry Collector, Jaeger y la aplicación de prueba HotROD |
| Visualización y alertas | Grafana (dashboard y alertas provisionados) y un receptor de webhook |

Curso: Taller Observabilidad Infraestructura con Stack Open Source (UNAB), semestre 2° 2026.

El paso a paso completo, la justificación técnica y las conclusiones están en [INFORME.md](INFORME.md).

## Arquitectura

```
                 ┌────────────── red monitoreo-net (172.21.0.0/24) ──────────────┐
 node-exporter ──┐
 router_sim ─SNMP─ snmp_exporter ──┼──> Prometheus ──┐
                                                     ├──> Grafana ──alerta──> webhook
 cloud-logs/*.json ──> Promtail ──> Loki ────────────┘
 HotROD ──OTLP/HTTP──> OTel Collector ──OTLP──> Jaeger
```

Todos los contenedores llevan el prefijo `obs_` y comparten la red `monitoreo-net`.

## Requisitos

- Docker Desktop encendido. `docker version` debe mostrar las secciones **Client** y **Server**; si solo aparece Client, el motor no está activo.
- Git y, para el generador de logs, una terminal con `bash` (por ejemplo Git Bash).
- Puertos libres: 161/udp, 3000, 3100, 4317, 4318, 8080, 8081, 9090, 9100, 9116 y 16686.
- La ruta del proyecto no debe contener caracteres especiales como `%` (Docker Compose no puede leer el proyecto).

## Inicio rápido

```bash
git clone https://github.com/sebastianihg05/observabilidad-stack-infra.git
cd observabilidad-stack-infra
git checkout develop
docker compose up -d --build
docker compose ps          # deben aparecer los 11 contenedores en estado Up
bash scripts/generar_logs.sh   # un evento cada 2 s (INFO/WARNING/ERROR); Ctrl+C para detener
```

La primera construcción tarda varios minutos porque el agente SNMP (net-snmp) se compila desde su código fuente.

Para apagar el stack:

```bash
docker compose down
```

El dashboard, las fuentes de datos y la alerta se cargan desde archivos de aprovisionamiento, así que `docker compose down` seguido de `docker compose up -d --build` reconstruye todo sin configuración manual.

## Accesos

| Servicio | URL / puerto |
|---|---|
| Grafana (usuario `admin`, contraseña `admin`) | http://localhost:3000 |
| Prometheus | http://localhost:9090 |
| Jaeger | http://localhost:16686 |
| HotROD (aplicación de prueba) | http://localhost:8080 |
| Receptor de webhook | http://localhost:8081 |
| Loki | http://localhost:3100 |
| Node Exporter | http://localhost:9100 |
| SNMP Exporter | http://localhost:9116 |
| Agente SNMP simulado | 161/udp |
| OpenTelemetry Collector (OTLP/HTTP) | 4318 |

## Levantar por etapas

Si prefieres levantar y validar cada pilar por separado:

| Etapa | Comando | Verificación |
|---|---|---|
| 1. Métricas | `docker compose up -d --build prometheus node-exporter snmp_exporter router_sim` | http://localhost:9090/targets muestra `prometheus`, `node-exporter` y `snmp_router` en UP |
| 2. Logs | `docker compose up -d loki promtail` y `bash scripts/generar_logs.sh` | En Grafana Explore (Loki): `{job="nube_simulada_seba", level="ERROR"}` |
| 3. Visualización y alertas | `docker compose up -d grafana webhook` | Grafana muestra las fuentes Prometheus y Loki y el *Dashboard Operativo* |
| 4. Trazas | `docker compose up -d jaeger otel-collector hotrod` | Hacer pedidos en HotROD y, en Jaeger, servicio `frontend` → *Find Traces* |

## Consultas principales

**Uso de CPU (%)** — PromQL:

```promql
100 - (avg(rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

**Ancho de banda de entrada de eth0 (Mbps)** — PromQL. Usa el contador de 64 bits `ifHCInOctets`; el aviso *Query notice* de Prometheus es solo informativo (el nombre no termina en `_total`):

```promql
rate(ifHCInOctets{instance="router_sim", ifDescr="eth0"}[1m]) * 8 / 1000000
```

**Uso de disco (%)** — PromQL. En Docker Desktop el punto de montaje `/` no existe dentro de Node Exporter; `/etc/hosts` pertenece al disco ext4 de la VM:

```promql
100 - (node_filesystem_avail_bytes{mountpoint="/etc/hosts"} / node_filesystem_size_bytes{mountpoint="/etc/hosts"} * 100)
```

**Logs de error de la nube simulada** — LogQL:

```logql
{job="nube_simulada_seba", level="ERROR"}
```

Promtail extrae `severity` como etiqueta `level` (únicos valores indexados: INFO, WARNING, ERROR) y deja `eventName` dentro del log para no aumentar la cardinalidad. Las etiquetas fijas son `job=nube_simulada_seba`, `env=desarrollo` y `host=servidor-seba`.

## Dashboard Operativo

Archivo: [grafana/dashboards/dashboard-operativo.json](grafana/dashboards/dashboard-operativo.json). Refresco de 5 s y rango de 15 min.

| Panel | Tipo | Consulta |
|---|---|---|
| Tráfico de red eth0 | Serie de tiempo | Ancho de banda de eth0 |
| Uso de disco | Medidor (umbrales 70 % y 90 %) | Uso de disco |
| Eventos de la nube | Logs en vivo | `{job="nube_simulada_seba"}` |

## Alerta de CPU

Definida en [grafana/provisioning/alerting/](grafana/provisioning/alerting/):

| Pieza | Archivo | Detalle |
|---|---|---|
| Regla `CPU sobre 75%` | `reglas.yml` | Carpeta `alertas-infra`, grupo `cpu-servidor`, evaluación cada 1 min, etiqueta `destino = webhook` |
| Contact point `webhook-seba` | `contact-points.yml` | Tipo Webhook, URL `http://webhook:8080` |
| Política de notificación | `politicas.yml` | Envía las alertas con `destino = webhook` a `webhook-seba` |

En Grafana 10.2 el enrutamiento es por etiquetas: la regla no elige el contact point, lo hace la política.

**Probar la alerta:** baja temporalmente el umbral de la regla (por ejemplo a `0.1`), espera a que pase a *Firing* y revisa el aviso recibido:

```bash
docker logs obs_webhook --tail 40
```

Después devuelve el umbral a 75.

## Trazas

HotROD envía trazas por OTLP/HTTP al OpenTelemetry Collector ([otel/otel-collector-config.yaml](otel/otel-collector-config.yaml)), que las reenvía a Jaeger. El Collector usa:

- `batch`: agrupa los datos antes de enviarlos.
- `attributes/entorno`: agrega `entorno = laboratorio-seba` a todas las trazas, útil para filtrarlas en Jaeger.

En Jaeger aparecen los servicios `frontend`, `customer`, `driver`, `route`, `mysql` y `redis-manual`. Los errores en `redis-manual` (GetDriver) son fallos simulados por HotROD, no un problema del stack.

## Estructura

| Carpeta o archivo | Contenido |
|---|---|
| `docker-compose.yml` | Definición de los 11 servicios y la red `monitoreo-net` |
| `prometheus/prometheus.yml` | Trabajos de scraping (incluye el reetiquetado de `snmp_router`) |
| `snmp/` | Dockerfile y `snmpd.conf` del agente SNMP simulado |
| `promtail/promtail-config.yml` | Pipeline JSON de Promtail |
| `cloud-logs/eventos-nube.json` | Logs JSON simulados de nube (un evento por línea) |
| `grafana/dashboards/` | Dashboard Operativo exportado |
| `grafana/provisioning/` | Datasources, proveedor de dashboards y alertas cargados al iniciar |
| `otel/otel-collector-config.yaml` | Configuración del OpenTelemetry Collector |
| `scripts/generar_logs.sh` | Generador de logs simulados |
| `INFORME.md` | Informe técnico |

## Solución de problemas

| Síntoma | Causa y solución |
|---|---|
| Los comandos de Docker fallan con error de conexión | El motor de Docker Desktop no está encendido. |
| Docker Compose no lee el proyecto | La ruta contiene `%` u otro carácter especial; renombra la carpeta. |
| Un target de Prometheus o el destino de Promtail falla | Los nombres de contenedor deben coincidir exactamente con los de `docker-compose.yml`. |
| El panel de disco no muestra datos | Usa el `mountpoint` que exista en tu entorno (en Docker Desktop, `/etc/hosts`). |
| Lo creado a mano en Grafana desaparece al recrear el contenedor | Grafana no tiene volumen; exporta los cambios a `grafana/provisioning/` o `grafana/dashboards/` y limpia valores como `[REDACTED]`. |
| Git usa otro repositorio | Ejecuta Git dentro de la carpeta del proyecto, no desde una carpeta superior. |

## Mejoras pendientes

- Volúmenes persistentes para Loki, Prometheus y Grafana.
- Fijar versiones de las imágenes que hoy usan `latest` (Jaeger, HotROD, OpenTelemetry, Prometheus, exporters y webhook).
- Alertas de red y disco, además de la de CPU.
- Reemplazar el receptor de webhook por un canal real (correo o chat).

## Autores

Sebastián Hidalgo — Universidad Andrés Bello.
