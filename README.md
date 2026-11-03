# observabilidad-stack-infra

Práctica Final Integradora: stack de observabilidad completo con Docker Compose
(Prometheus, Node Exporter, SNMP Exporter, Loki, Promtail, Grafana, OpenTelemetry Collector y Jaeger).

Curso: Taller Observabilidad Infraestructura con Stack Open Source (UNAB).

El detalle técnico, la justificación y las conclusiones están en [INFORME.md](INFORME.md).

## Requisitos

- Docker Desktop encendido (el motor debe estar en "Engine running").
- Git y, para el generador de logs, una terminal con `bash` (por ejemplo Git Bash).
- Puertos libres: 161/udp, 3000, 3100, 4317, 4318, 8080, 8081, 9090, 9100, 9116 y 16686.
- La carpeta del proyecto no debe tener el símbolo `%` en su ruta.

## Uso

Levantar todo el stack (la primera vez tarda varios minutos porque compila el agente SNMP):

```bash
docker compose up -d --build
```

Ver el estado de los contenedores:

```bash
docker compose ps
```

Generar logs de nube simulados (un evento cada 2 segundos, se detiene con Ctrl+C):

```bash
bash scripts/generar_logs.sh
```

Apagar el stack:

```bash
docker compose down
```

## Accesos

| Servicio | URL |
|---|---|
| Grafana (usuario `admin`, contraseña `admin`) | http://localhost:3000 |
| Prometheus | http://localhost:9090 |
| Jaeger | http://localhost:16686 |
| HotROD (aplicación de prueba) | http://localhost:8080 |
| Receptor de webhook | http://localhost:8081 |

Para ver los avisos de la alerta:

```bash
docker logs obs_webhook --tail 40
```

## Estructura

| Carpeta o archivo | Contenido |
|---|---|
| `docker-compose.yml` | Definición de todos los servicios |
| `prometheus/` | Configuración de Prometheus |
| `snmp/` | Dockerfile y `snmpd.conf` del agente SNMP simulado |
| `promtail/` | Pipeline JSON de Promtail |
| `cloud-logs/` | Logs JSON simulados de nube |
| `grafana/dashboards/` | Dashboard Operativo exportado |
| `grafana/provisioning/` | Datasources, dashboards y alertas cargados al iniciar |
| `otel/` | Configuración del OpenTelemetry Collector |
| `scripts/` | Generador de logs simulados |
| `INFORME.md` | Informe técnico |
