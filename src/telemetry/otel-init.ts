// OpenTelemetry must be initialized BEFORE any other imports
import { useAzureMonitor } from '@azure/monitor-opentelemetry';
import config from '../config';

// Initialize OpenTelemetry immediately
if (config.applicationInsightsConnectionString) {
  useAzureMonitor({
    azureMonitorExporterOptions: {
      connectionString: config.applicationInsightsConnectionString,
    }
  });
  console.log('OpenTelemetry Azure Monitor initialized');
}

// Export the telemetry service after initialization
export * from './telemetryService';
export { telemetryService } from './telemetryService';
