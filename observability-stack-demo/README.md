# 🔭 Full Observability Stack: FastAPI + Prometheus + Loki + Jaeger + Grafana

## 1) Overview

This project is my end-to-end observability setup for a containerized FastAPI service. I instrumented the app for metrics, logs, and traces, then wired everything into Grafana so I can monitor traffic, latency, errors, and hop across signals during incidents like an SRE. It’s designed to be clear, reproducible, and interview-ready.

- **What’s inside:** Metrics (Prometheus), Logs (Loki via Promtail), Traces (Jaeger), Visualization and correlation (Grafana).
- **Why it matters:** Unified observability shortens MTTR, supports proactive performance tuning, and demonstrates systems thinking in interviews.

---

## 2) Architecture and Tools

### 2.1 Architecture
Grafana connects to Prometheus, Loki, and Jaeger for a single-pane view.

FastAPI (metrics/logs/traces) 
├── Metrics → Prometheus → Grafana (Panels, Alerts) 
├── Logs → Promtail → Loki → Grafana (LogQL, Filters) 
└── Traces → OpenTelemetry → Jaeger → Grafana (Trace UI)


### 2.2 Tools Used

| Component    | Role                                       | Why I Chose It                          |
|--------------|--------------------------------------------|-----------------------------------------|
| FastAPI      | Sample service to generate telemetry        | Simple, fast, Pythonic                  |
| Prometheus   | Metrics storage and query engine            | Best-in-class pull-based metrics        |
| Loki         | Log database optimized for labels           | Scalable, cost-effective logs           |
| Promtail     | Log shipper with Docker discovery           | Label-aware, easy Docker integration    |
| Jaeger       | Distributed tracing backend                 | Clear trace timelines + error analysis  |
| Grafana      | Unified visualization and correlation       | One place for metrics, logs, and traces |

---

## 3) Setup and Run

### 3.1 Prerequisites

1. **Docker & Compose:** Install Docker and Docker Compose (latest versions).
2. **Ports:** Ensure these ports are free: 8000 (app), 9090 (Prometheus), 3100 (Loki), 16686 (Jaeger UI), 3000 (Grafana).
3. **Repo Structure:** I keep configs modular and self-explanatory.

### 3.2 Launch the Stack

1. **Start services**
   - Run:
     ```bash
     docker-compose up -d --build
     ```

2. **Open UIs**
   - Grafana: http://localhost:3000 (default user/pass: admin/admin)
   - Jaeger: http://localhost:16686
   - FastAPI: http://localhost:8000 (metrics at /metrics)
   - Prometheus: http://localhost:9090
   - Loki readiness: http://localhost:3100/ready (may briefly say “Ingester not ready: waiting for 15s” during warm-up)

3. **Generate traffic**
   - Use:
     ```bash
     for i in {1..100}; do curl -s http://localhost:8000/hello > /dev/null; done
     ```

---

## 4) Using Grafana and Jaeger

### 4.1 Add Data Sources in Grafana (once)

1. **Prometheus**
   - URL: http://prometheus:9090

2. **Loki**
   - URL: http://loki:3100

3. **Jaeger**
   - URL: http://jaeger:16686

> Tip: In Docker, Grafana reaches other services by their Compose service name (prometheus, loki, jaeger).

### 4.2 Metrics in Grafana (Prometheus)

1. **Open Explore**
   - Choose data source: Prometheus.

2. **Request rate by status**
   - Query:
     ```promql
     sum(rate(app_requests_total[1m])) by (status)
     ```

3. **p95 latency**
   - Query:
     ```promql
     histogram_quantile(0.95, sum(rate(app_request_latency_seconds_bucket[5m])) by (le))
     ```

4. **Panelize**
   - Add these queries as panels on a dashboard (e.g., “Traffic” and “Latency p95”).

### 4.3 Logs in Grafana (Loki)

1. **Open Explore**
   - Choose data source: Loki.

2. **Filter app logs**
   - Query:
     ```logql
     {container="app"} |~ "INFO|ERROR"
     ```

3. **Inspect fields**
   - Expand a log line; you’ll see parsed fields like `traceid` and `spanid` for correlation.

### 4.4 Traces in Jaeger

1. **Find traces**
   - Jaeger UI → Service: sample-app → Find Traces.

2. **Read the timeline**
   - You’ll see spans like `hello_handler → simulated_work`.
   - Look for error tags or long spans to debug issues.

### 4.5 Hop Across Signals (Interview-Worthy)

1. **Trace → Logs**
   - Copy a `traceid` from Jaeger.
   - In Grafana (Loki):
     ```logql
     {container="app"} |= "traceid=<PASTE_ID>"
     ```

2. **Logs → Trace**
   - Copy `traceid` from a log line.
   - Paste into Jaeger search → Find Traces.

> This is the core SRE workflow I use to move from symptom to root cause fast.

