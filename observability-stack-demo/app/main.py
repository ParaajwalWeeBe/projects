import os
import random
import time
import logging
from fastapi import FastAPI, Request, HTTPException
from prometheus_client import Counter, Histogram, CollectorRegistry, CONTENT_TYPE_LATEST
from prometheus_client import generate_latest
from opentelemetry import trace
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.logging import LoggingInstrumentor
from pythonjsonlogger import jsonlogger
from starlette.responses import Response

SERVICE_NAME = os.getenv("OTEL_SERVICE_NAME", "sample-app")

# ----- Logging (JSON with trace correlation) -----
logger = logging.getLogger(SERVICE_NAME)
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
fmt = jsonlogger.JsonFormatter(
    "%(asctime)s %(levelname)s %(name)s %(message)s %(otelTraceID)s %(otelSpanID)s"
)
handler.setFormatter(fmt)
logger.addHandler(handler)

# Inject otelTraceID and otelSpanID into logs
LoggingInstrumentor().instrument(
    set_logging_format=False, log_level=logging.INFO
)

# ----- Tracing -----
resource = Resource.create({"service.name": SERVICE_NAME, "deployment.environment": "dev"})
provider = TracerProvider(resource=resource)
exporter = OTLPSpanExporter(endpoint=os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "http://jaeger:4317"), insecure=True)
processor = BatchSpanProcessor(exporter)
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)
tracer = trace.get_tracer(__name__)

# ----- Metrics -----
registry = CollectorRegistry()
REQ_COUNTER = Counter(
    "app_requests_total",
    "Total HTTP requests",
    ["method", "endpoint", "status"],
    registry=registry,
)
LAT_HIST = Histogram(
    "app_request_latency_seconds",
    "Request latency in seconds",
    ["endpoint"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2, 5),
    registry=registry,
)

app = FastAPI()

# Auto-instrument FastAPI routes (creates spans per request)
FastAPIInstrumentor.instrument_app(app, tracer_provider=provider)

@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start = time.perf_counter()
    endpoint = request.url.path
    method = request.method
    try:
        resp = await call_next(request)
        status = resp.status_code
        return resp
    except Exception:
        status = 500
        raise
    finally:
        dur = time.perf_counter() - start
        LAT_HIST.labels(endpoint=endpoint).observe(dur)
        REQ_COUNTER.labels(method=method, endpoint=endpoint, status=str(status)).inc()

@app.get("/api/hello")
async def hello(name: str = "world"):
    # Demonstrate nested spans and occasional errors
    with tracer.start_as_current_span("hello_handler"):
        logger.info("Handling request", extra={})
        await simulated_work()
        if random.random() < 0.1:
            logger.error("Simulated failure", extra={})
            raise HTTPException(status_code=500, detail="Random failure")
        msg = f"Hello, {name}!"
        logger.info("Success response", extra={"response": msg})
        return {"message": msg}

@app.get("/metrics")
def metrics():
    return Response(generate_latest(registry), media_type=CONTENT_TYPE_LATEST)

async def simulated_work():
    with tracer.start_as_current_span("simulated_work"):
        # variable latency
        delay = random.uniform(0.01, 0.3)
        time.sleep(delay)
        logger.info("Did some work", extra={"delay": delay})

