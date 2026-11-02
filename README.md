# observabilidad-stack-infra

Práctica Final Integradora: stack de observabilidad completo con Docker Compose
(Prometheus, Node Exporter, SNMP Exporter, Loki, Promtail, Grafana, OpenTelemetry Collector y Jaeger).

Curso: Taller Observabilidad Infraestructura con Stack Open Source (UNAB).

## Estructura

| Carpeta | Contenido |
|---|---|
| `prometheus/` | Configuración y reglas de Prometheus |
| `snmp/` | Dockerfile y `snmpd.conf` del agente SNMP simulado |
| `promtail/` | Pipeline JSON de Promtail |
| `cloud-logs/` | Logs JSON simulados de nube |
| `grafana/provisioning/` | Datasources, dashboards y alertas |
| `otel/` | Configuración del OpenTelemetry Collector |
| `scripts/` | Generadores de logs y tráfico |
| `evidencias/` | Capturas de Grafana y Jaeger |

## Uso

```bash
docker compose up -d
```

(En construcción: ver `INFORME.md`.)
