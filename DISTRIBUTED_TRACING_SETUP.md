# Distributed Tracing Setup for FastAPI Container Apps

This guide shows how to connect your FastAPI Semantic Kernel service with the Teams Bot telemetry using OpenTelemetry distributed tracing.

## 🔗 What This Achieves

With distributed tracing, you'll see:
- ✅ **Complete request flow**: Bot → FastAPI → Semantic Kernel → AI Service
- ✅ **End-to-end timing**: Total request time across all services  
- ✅ **Error correlation**: Which service actually failed in a chain
- ✅ **Performance bottlenecks**: Where time is spent in the request pipeline

## 📦 Required Dependencies

Add these to your FastAPI service's `requirements.txt`:

```python
# OpenTelemetry core
opentelemetry-api
opentelemetry-sdk

# Auto-instrumentation for FastAPI and HTTP requests
opentelemetry-instrumentation-fastapi
opentelemetry-instrumentation-requests
opentelemetry-instrumentation-httpx

# Azure Monitor exporter
azure-monitor-opentelemetry-exporter

# Semantic Kernel instrumentation (if available)
opentelemetry-instrumentation-semantic-kernel  # May not exist yet
```

## 🚀 FastAPI Service Setup

### 1. Initialize OpenTelemetry (main.py)

```python
import os
from fastapi import FastAPI
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from azure.monitor.opentelemetry.exporter import AzureMonitorTraceExporter
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.instrumentation.httpx import HTTPXClientInstrumentor

# Initialize OpenTelemetry BEFORE creating FastAPI app
def setup_telemetry():
    # Set up the tracer provider
    trace.set_tracer_provider(TracerProvider())
    tracer_provider = trace.get_tracer_provider()
    
    # Configure Azure Monitor exporter
    connection_string = os.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING")
    if connection_string:
        azure_exporter = AzureMonitorTraceExporter(
            connection_string=connection_string
        )
        span_processor = BatchSpanProcessor(azure_exporter)
        tracer_provider.add_span_processor(span_processor)
        print(f"✅ OpenTelemetry configured for Azure Monitor")
    else:
        print("⚠️ No APPLICATIONINSIGHTS_CONNECTION_STRING found")

# Initialize telemetry FIRST
setup_telemetry()

# Create FastAPI app
app = FastAPI(title="Semantic Kernel Chat Agent")

# Auto-instrument FastAPI (AFTER creating the app)
FastAPIInstrumentor.instrument_app(app)

# Auto-instrument HTTP requests
RequestsInstrumentor().instrument()
HTTPXClientInstrumentor().instrument()

# Your existing chat endpoint
@app.post("/agent_chat")
async def agent_chat(request: ChatRequest):
    # OpenTelemetry will automatically create spans for:
    # - The incoming HTTP request
    # - Any outgoing HTTP requests (to AI services)
    # - Database calls (if instrumented)
    
    tracer = trace.get_tracer(__name__)
    
    # Add custom spans for your business logic
    with tracer.start_as_current_span("semantic_kernel_processing") as span:
        span.set_attribute("session_id", request.session_id)
        span.set_attribute("message_length", len(request.message))
        
        try:
            # Your existing Semantic Kernel logic here
            response = await process_with_semantic_kernel(request)
            
            span.set_attribute("response_length", len(response))
            span.set_status(trace.Status(trace.StatusCode.OK))
            
            return {"response": response}
            
        except Exception as e:
            span.record_exception(e)
            span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
            raise
```

### 2. Add Custom Instrumentation for Semantic Kernel

```python
from opentelemetry import trace
from semantic_kernel import Kernel

class InstrumentedSemanticKernel:
    def __init__(self, kernel: Kernel):
        self.kernel = kernel
        self.tracer = trace.get_tracer(__name__)
    
    async def invoke_function(self, function_name: str, **kwargs):
        with self.tracer.start_as_current_span(f"sk_function_{function_name}") as span:
            span.set_attribute("function.name", function_name)
            span.set_attribute("function.parameters", str(kwargs))
            
            try:
                result = await self.kernel.invoke_function(function_name, **kwargs)
                span.set_attribute("function.result_length", len(str(result)))
                return result
            except Exception as e:
                span.record_exception(e)
                span.set_status(trace.Status(trace.StatusCode.ERROR, str(e)))
                raise

# Use the instrumented kernel
instrumented_kernel = InstrumentedSemanticKernel(your_kernel)
```

### 3. Container Apps Environment Variables

In your Azure Container Apps environment, set:

```yaml
env:
  - name: APPLICATIONINSIGHTS_CONNECTION_STRING
    value: "InstrumentationKey=...;IngestionEndpoint=https://..."
  - name: OTEL_SERVICE_NAME
    value: "semantic-kernel-agent"
  - name: OTEL_SERVICE_VERSION
    value: "1.0.0"
```

## 🔍 What You'll See in Application Insights

After setup, your queries will show:

### 1. **Connected Traces**
```kql
// See complete request flows
dependencies
| where name contains "agent_chat"
| project timestamp, operation_Id, name, duration, data
| join (dependencies | where name == "External_AI_API") on operation_Id
| project timestamp, BotCall=name, FastAPICall=name1, TotalDuration=duration+duration1
```

### 2. **End-to-End Performance**
```kql
// See performance across services
dependencies
| where operation_Id in (
    dependencies 
    | where name == "External_AI_API" 
    | distinct operation_Id
)
| summarize 
    TotalDuration = max(duration),
    ServiceCount = dcount(name),
    Services = make_set(name)
by operation_Id
| render timechart
```

### 3. **Error Correlation**
```kql
// See which service actually failed
union dependencies, exceptions
| where operation_Id in (
    exceptions | distinct operation_Id
)
| project timestamp, operation_Id, itemType, name, success, outerMessage
| order by timestamp asc
```

## 🎯 Expected Results

Once both services are instrumented:

1. **Teams Bot** creates trace with `External_AI_API` span
2. **Bot** adds trace headers to HTTP request  
3. **FastAPI** receives request, extracts trace context
4. **FastAPI** continues the same trace with `agent_chat` span
5. **Semantic Kernel** operations appear as child spans
6. **AI service calls** appear as HTTP dependency spans

You'll see a **single connected trace** showing the complete request journey!

## 🔧 Testing Distributed Tracing

1. **Send message to bot**
2. **Check Application Insights** for traces with same `operation_Id`
3. **Verify timing correlation** between bot and FastAPI spans
4. **Confirm error propagation** works across services

## 📚 Additional Resources

- [OpenTelemetry Python Documentation](https://opentelemetry.io/docs/instrumentation/python/)
- [Azure Monitor OpenTelemetry Exporter](https://github.com/Azure/azure-sdk-for-python/tree/main/sdk/monitor/azure-monitor-opentelemetry-exporter)
- [FastAPI OpenTelemetry Integration](https://opentelemetry-python-contrib.readthedocs.io/en/latest/instrumentation/fastapi/fastapi.html)
