import { useAzureMonitor } from '@azure/monitor-opentelemetry';
import { trace, metrics, context, SpanStatusCode } from '@opentelemetry/api';
import { TurnContext } from 'botbuilder';
import config from './config';

export interface MessageTelemetry {
  userId: string;
  conversationId: string;
  messageType: string;
  messageText?: string;
  responseTime?: number;
  success: boolean;
  error?: string;
  additionalProperties?: { [key: string]: any };
}

export interface PerformanceTelemetry {
  operationName: string;
  duration: number;
  success: boolean;
  userId?: string;
  conversationId?: string;
  error?: string;
  additionalProperties?: { [key: string]: any };
}

export class TelemetryService {
  private static instance: TelemetryService;
  private tracer: any;
  private meter: any;
  private isInitialized: boolean = false;
  private messageCounter: any;
  private responseTimeHistogram: any;
  private errorCounter: any;

  private constructor() {}

  public static getInstance(): TelemetryService {
    if (!TelemetryService.instance) {
      TelemetryService.instance = new TelemetryService();
    }
    return TelemetryService.instance;
  }

  public initialize(): void {
    if (this.isInitialized || !config.applicationInsightsConnectionString) {
      return;
    }

    try {
      // Configure Azure Monitor with OpenTelemetry - simplified configuration
      useAzureMonitor({
        azureMonitorExporterOptions: {
          connectionString: config.applicationInsightsConnectionString,
        }
      });

      // Get tracer and meter
      this.tracer = trace.getTracer(config.telemetryServiceName, config.telemetryServiceVersion);
      this.meter = metrics.getMeter(config.telemetryServiceName, config.telemetryServiceVersion);

      // Create custom metrics
      this.messageCounter = this.meter.createCounter('bot_messages_total', {
        description: 'Total number of bot messages processed'
      });

      this.responseTimeHistogram = this.meter.createHistogram('bot_response_time_ms', {
        description: 'Bot response time in milliseconds'
      });

      this.errorCounter = this.meter.createCounter('bot_errors_total', {
        description: 'Total number of bot errors'
      });

      this.isInitialized = true;
      console.log('OpenTelemetry Azure Monitor telemetry initialized successfully');
    } catch (error) {
      console.error('Failed to initialize OpenTelemetry Azure Monitor:', error);
    }
  }

  public trackMessage(telemetry: MessageTelemetry): void {
    if (!this.isInitialized) return;

    const span = this.tracer.startSpan('bot_message_processing', {
      attributes: {
        'bot.user_id': telemetry.userId,
        'bot.conversation_id': telemetry.conversationId,
        'bot.message_type': telemetry.messageType,
        'bot.success': telemetry.success,
        'service.name': config.telemetryServiceName,
        'service.version': config.telemetryServiceVersion,
        'deployment.environment': config.environment,
        ...(telemetry.additionalProperties || {})
      }
    });

    // Add message text if provided (truncated for privacy)
    if (telemetry.messageText) {
      span.setAttributes({
        'bot.message_text': telemetry.messageText.substring(0, 100),
        'bot.message_length': telemetry.messageText.length
      });
    }

    // Track metrics
    this.messageCounter.add(1, {
      success: telemetry.success.toString(),
      message_type: telemetry.messageType,
      user_id: telemetry.userId
    });

    if (telemetry.responseTime !== undefined) {
      this.responseTimeHistogram.record(telemetry.responseTime, {
        success: telemetry.success.toString(),
        message_type: telemetry.messageType
      });
      
      span.setAttributes({
        'bot.response_time_ms': telemetry.responseTime
      });
    }

    // Handle errors
    if (!telemetry.success) {
      span.setStatus({ code: SpanStatusCode.ERROR, message: telemetry.error || 'Unknown error' });
      this.errorCounter.add(1, {
        error_type: 'message_processing',
        user_id: telemetry.userId
      });
      
      if (telemetry.error) {
        span.recordException(new Error(telemetry.error));
      }
    } else {
      span.setStatus({ code: SpanStatusCode.OK });
    }

    span.end();
  }

  public trackPerformance(telemetry: PerformanceTelemetry): void {
    if (!this.isInitialized) return;

    const span = this.tracer.startSpan(telemetry.operationName, {
      attributes: {
        'operation.name': telemetry.operationName,
        'operation.duration_ms': telemetry.duration,
        'operation.success': telemetry.success,
        'bot.user_id': telemetry.userId || 'unknown',
        'bot.conversation_id': telemetry.conversationId || 'unknown',
        'service.name': config.telemetryServiceName,
        'service.version': config.telemetryServiceVersion,
        'deployment.environment': config.environment,
        ...(telemetry.additionalProperties || {})
      }
    });

    // Record performance metric
    const performanceHistogram = this.meter.createHistogram(`${telemetry.operationName.toLowerCase()}_duration_ms`, {
      description: `Duration of ${telemetry.operationName} operations in milliseconds`
    });
    
    performanceHistogram.record(telemetry.duration, {
      success: telemetry.success.toString(),
      operation: telemetry.operationName
    });

    if (!telemetry.success) {
      span.setStatus({ code: SpanStatusCode.ERROR, message: telemetry.error || 'Operation failed' });
      this.errorCounter.add(1, {
        error_type: telemetry.operationName,
        user_id: telemetry.userId || 'unknown'
      });
      
      if (telemetry.error) {
        span.recordException(new Error(telemetry.error));
      }
    } else {
      span.setStatus({ code: SpanStatusCode.OK });
    }

    span.end();
  }

  public trackCustomEvent(eventName: string, properties?: { [key: string]: string }, measurements?: { [key: string]: number }): void {
    if (!this.isInitialized) return;

    const span = this.tracer.startSpan(eventName, {
      attributes: {
        'event.name': eventName,
        'service.name': config.telemetryServiceName,
        'service.version': config.telemetryServiceVersion,
        'deployment.environment': config.environment,
        ...(properties || {})
      }
    });

    // Add measurements as attributes
    if (measurements) {
      Object.entries(measurements).forEach(([key, value]) => {
        span.setAttributes({ [`measurement.${key}`]: value });
      });
    }

    // Create a custom counter for this event
    const eventCounter = this.meter.createCounter(`bot_${eventName.toLowerCase()}_total`, {
      description: `Total count of ${eventName} events`
    });
    
    eventCounter.add(1, properties || {});

    span.setStatus({ code: SpanStatusCode.OK });
    span.end();
  }

  public trackException(error: Error, properties?: { [key: string]: string }): void {
    if (!this.isInitialized) return;

    const span = this.tracer.startSpan('bot_exception', {
      attributes: {
        'exception.type': error.constructor.name,
        'exception.message': error.message,
        'service.name': config.telemetryServiceName,
        'service.version': config.telemetryServiceVersion,
        'deployment.environment': config.environment,
        ...(properties || {})
      }
    });

    span.recordException(error);
    span.setStatus({ code: SpanStatusCode.ERROR, message: error.message });

    this.errorCounter.add(1, {
      error_type: 'exception',
      exception_type: error.constructor.name,
      ...(properties || {})
    });

    span.end();
  }

  public trackTrace(message: string, severity: 'info' | 'warn' | 'error' = 'info', properties?: { [key: string]: string }): void {
    if (!this.isInitialized) return;

    const span = this.tracer.startSpan('bot_trace', {
      attributes: {
        'trace.message': message,
        'trace.severity': severity,
        'service.name': config.telemetryServiceName,
        'service.version': config.telemetryServiceVersion,
        'deployment.environment': config.environment,
        ...(properties || {})
      }
    });

    const statusCode = severity === 'error' ? SpanStatusCode.ERROR : SpanStatusCode.OK;
    span.setStatus({ code: statusCode, message });
    span.end();
  }

  public startOperation(operationName: string): OperationTimer {
    return new OperationTimer(operationName, this);
  }

  public flush(): Promise<void> {
    // OpenTelemetry handles flushing automatically, but we can force it
    return Promise.resolve();
  }

  public extractTelemetryFromContext(context: TurnContext): { userId: string; conversationId: string; messageType: string } {
    const activity = context.activity;
    return {
      userId: activity.from?.id || 'unknown',
      conversationId: activity.conversation?.id || 'unknown',
      messageType: activity.type || 'unknown'
    };
  }

  public createSpan(operationName: string, attributes?: { [key: string]: any }) {
    if (!this.isInitialized) return null;
    
    return this.tracer.startSpan(operationName, {
      attributes: {
        'service.name': config.telemetryServiceName,
        'service.version': config.telemetryServiceVersion,
        'deployment.environment': config.environment,
        ...(attributes || {})
      }
    });
  }
}

export class OperationTimer {
  private startTime: number;
  private operationName: string;
  private telemetryService: TelemetryService;
  private userId?: string;
  private conversationId?: string;
  private span: any;

  constructor(operationName: string, telemetryService: TelemetryService) {
    this.operationName = operationName;
    this.telemetryService = telemetryService;
    this.startTime = Date.now();
    
    // Create a span for this operation
    this.span = telemetryService.createSpan(operationName, {
      'operation.start_time': this.startTime
    });
  }

  public setContext(userId: string, conversationId: string): OperationTimer {
    this.userId = userId;
    this.conversationId = conversationId;
    
    if (this.span) {
      this.span.setAttributes({
        'bot.user_id': userId,
        'bot.conversation_id': conversationId
      });
    }
    
    return this;
  }

  public stop(success: boolean = true, error?: string, additionalProperties?: { [key: string]: any }): void {
    const duration = Date.now() - this.startTime;
    
    if (this.span) {
      this.span.setAttributes({
        'operation.duration_ms': duration,
        'operation.success': success,
        ...(additionalProperties || {})
      });
      
      if (!success) {
        this.span.setStatus({ code: SpanStatusCode.ERROR, message: error || 'Operation failed' });
        if (error) {
          this.span.recordException(new Error(error));
        }
      } else {
        this.span.setStatus({ code: SpanStatusCode.OK });
      }
      
      this.span.end();
    }
    
    this.telemetryService.trackPerformance({
      operationName: this.operationName,
      duration,
      success,
      userId: this.userId,
      conversationId: this.conversationId,
      error,
      additionalProperties
    });
  }
}

// Export singleton instance
export const telemetryService = TelemetryService.getInstance();
