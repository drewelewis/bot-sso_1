import { trace, metrics, context, SpanStatusCode, SpanKind } from '@opentelemetry/api';
import { TurnContext } from 'botbuilder';

export interface TelemetryEvent {
  name: string;
  properties?: Record<string, any>;
  measurements?: Record<string, number>;
}

export interface OperationTelemetry {
  operationName: string;
  properties?: Record<string, any>;
  measurements?: Record<string, number>;
}

export interface OperationTimer {
  setContext(userId: string, conversationId: string): OperationTimer;
  stop(success: boolean, errorMessage?: string): void;
  end(): void;
}

export class TelemetryService {
  private isInitialized = false;
  private tracer = trace.getTracer('teams-bot');

  initialize(): void {
    if (this.isInitialized) {
      return;
    }
    
    console.log('🔍 TelemetryService initialized');
    this.isInitialized = true;
  }

  extractTelemetryFromContext(context: TurnContext): { userId: string; conversationId: string; messageType?: string } {
    const userId = context.activity?.from?.id || 'unknown';
    const conversationId = context.activity?.conversation?.id || 'unknown';
    const messageType = context.activity?.type || 'unknown';
    
    return { userId, conversationId, messageType };
  }

  trackMessage(message: string | Record<string, any>, properties?: Record<string, any>): void {
    if (!this.isInitialized) {
      return;
    }
    
    if (typeof message === 'string') {
      // OpenTelemetry approach: Use console.log for traces
      console.log('📨 Bot Message:', message, properties || {});
    } else {
      // Handle object-style message tracking
      console.log('📨 Bot Message:', message);
    }
  }

  trackCustomEvent(eventName: string, properties?: Record<string, any>): void {
    if (!this.isInitialized) {
      return;
    }
    
    // OpenTelemetry approach: Use console.log for custom events
    console.log('🎯 Custom Event:', eventName, properties || {});
  }

  trackException(error: Error, properties?: Record<string, any>): void {
    if (!this.isInitialized) {
      return;
    }
    
    // OpenTelemetry approach: Use console.error for exceptions
    console.error('❌ Exception:', error.message, {
      stack: error.stack,
      properties: properties || {}
    });
  }

  startOperation(operationName: string | OperationTelemetry): OperationTimer {
    if (!this.isInitialized) {
      const dummyTimer: OperationTimer = { 
        setContext: () => dummyTimer,
        stop: () => {},
        end: () => {} 
      };
      return dummyTimer;
    }

    const opName = typeof operationName === 'string' ? operationName : operationName.operationName;
    const opProperties = typeof operationName === 'string' ? {} : (operationName.properties || {});

    // OpenTelemetry approach: Create spans for operations
    const span = this.tracer.startSpan(opName, {
      kind: SpanKind.INTERNAL,
      attributes: {
        ...opProperties,
        operation_type: 'bot_operation'
      }
    });

    console.log('🚀 Operation Started:', opName, opProperties);

    let operationContext = {
      userId: 'unknown',
      conversationId: 'unknown'
    };

    const timer: OperationTimer = {
      setContext: (userId: string, conversationId: string) => {
        operationContext.userId = userId;
        operationContext.conversationId = conversationId;
        span.setAttributes({
          'user_id': userId,
          'conversation_id': conversationId
        });
        return timer;
      },
      
      stop: (success: boolean, errorMessage?: string) => {
        if (success) {
          span.setStatus({ code: SpanStatusCode.OK });
          console.log('✅ Operation Completed:', opName, operationContext);
        } else {
          span.setStatus({ 
            code: SpanStatusCode.ERROR, 
            message: errorMessage || 'Operation failed' 
          });
          console.log('❌ Operation Failed:', opName, { 
            ...operationContext, 
            error: errorMessage 
          });
        }
        span.end();
      },

      end: () => {
        span.setStatus({ code: SpanStatusCode.OK });
        span.end();
        console.log('✅ Operation Ended:', opName);
      }
    };

    return timer;
  }

  flush(): Promise<void> {
    // OpenTelemetry handles flushing automatically
    return Promise.resolve();
  }
}

export const telemetryService = new TelemetryService();
