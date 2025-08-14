// Import required packages
import express from "express";
import path from "path";
import send from "send";

// Initialize OpenTelemetry FIRST - must be before any other imports
import "./telemetry/otel-init";

// Import required bot services.
// See https://aka.ms/bot-services to learn more about the different parts of a bot.
import {
  CloudAdapter,
  ConfigurationServiceClientCredentialFactory,
  ConfigurationBotFrameworkAuthentication,
  TurnContext,
} from "botbuilder";

// This bot's main dialog.
import { TeamsBot } from "./teamsBot";
import config from "./config";
import { telemetryService } from "./telemetry";

// Initialize telemetry as early as possible
// OpenTelemetry is now initialized in otel-init.ts
telemetryService.initialize();

// Create adapter.
// See https://aka.ms/about-bot-adapter to learn more about adapters.
const credentialsFactory = new ConfigurationServiceClientCredentialFactory(
  config
);

const botFrameworkAuthentication = new ConfigurationBotFrameworkAuthentication(
  {},
  credentialsFactory
);

const adapter = new CloudAdapter(botFrameworkAuthentication);

// Catch-all for errors.
const onTurnErrorHandler = async (context: TurnContext, error: Error) => {
  // This check writes out errors to console log .vs. Azure Monitor.
  // NOTE: In production environment, you should consider logging this to Azure
  //       Monitor via OpenTelemetry.
  console.error(`\n [onTurnError] unhandled error: ${error}`);

  // Track error in Azure Monitor via OpenTelemetry
  const { userId, conversationId } = telemetryService.extractTelemetryFromContext(context);
  telemetryService.trackException(error, {
    userId,
    conversationId,
    errorType: 'TurnError',
    activity: context.activity.type
  });

  // Send a trace activity, which will be displayed in Bot Framework Emulator
  await context.sendTraceActivity(
    "OnTurnError Trace",
    `${error}`,
    "https://www.botframework.com/schemas/error",
    "TurnError"
  );

  // Send a message to the user
  await context.sendActivity(
    `The bot encountered unhandled error:\n ${error.message}`
  );
  await context.sendActivity(
    "To continue to run this bot, please fix the bot source code."
  );
};

// Set the onTurnError for the singleton CloudAdapter
adapter.onTurnError = onTurnErrorHandler;

// Create the bot that will handle incoming messages.
const bot = new TeamsBot();

// Store conversation references for proactive messaging
// const conversationReferences: { [key: string]: any } = {};

// Create HTTP server.
const expressApp = express();
expressApp.use(express.json());

const server = expressApp.listen(
  process.env.port || process.env.PORT || 3978,
  () => {
    console.log(
      `\nBot Started, ${expressApp.name} listening to`,
      server.address()
    );
    
    // Track application startup
    telemetryService.trackCustomEvent('Application_Started', {
      port: (process.env.port || process.env.PORT || 3978).toString(),
      environment: process.env.ENVIRONMENT || 'development',
      nodeVersion: process.version
    });
  }
);

// Graceful shutdown handling to ensure telemetry is flushed
const gracefulShutdown = async (signal: string) => {
  console.log(`\nReceived ${signal}. Graceful shutdown starting...`);
  
  // Track application shutdown
  telemetryService.trackCustomEvent('Application_Shutdown', {
    signal,
    uptime: process.uptime().toString()
  });
  
  // Flush telemetry
  await telemetryService.flush();
  
  // Close server
  server.close(() => {
    console.log('HTTP server closed.');
    process.exit(0);
  });
  
  // Force exit after 10 seconds
  setTimeout(() => {
    console.log('Forcing exit...');
    process.exit(1);
  }, 10000);
};

// Handle different shutdown signals
process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
process.on('SIGUSR2', () => gracefulShutdown('SIGUSR2')); // Nodemon restart

// Listen for incoming requests.
expressApp.post("/api/messages", async (req, res) => {
  const operationTimer = telemetryService.startOperation('ProcessMessage');
  
  try {
    await adapter
      .process(req, res, async (context) => {
        const { userId, conversationId, messageType } = telemetryService.extractTelemetryFromContext(context);
        operationTimer.setContext(userId, conversationId);
        
        const messageStartTime = Date.now();
        
        try {
          await bot.run(context);
          
          // Track successful message processing
          const responseTime = Date.now() - messageStartTime;
          telemetryService.trackMessage({
            userId,
            conversationId,
            messageType,
            messageText: context.activity.text?.substring(0, 100), // First 100 chars for privacy
            responseTime,
            success: true
          });
          
          operationTimer.stop(true);
        } catch (error) {
          const responseTime = Date.now() - messageStartTime;
          telemetryService.trackMessage({
            userId,
            conversationId,
            messageType,
            messageText: context.activity.text?.substring(0, 100),
            responseTime,
            success: false,
            error: error instanceof Error ? error.message : String(error)
          });
          
          operationTimer.stop(false, error instanceof Error ? error.message : String(error));
          throw error;
        }
      })
      .catch((err) => {
        // Error message including "412" means it is waiting for user's consent, which is a normal process of SSO, shouldn't throw this error.
        if (!err.message.includes("412")) {
          operationTimer.stop(false, err.message);
          throw err;
        } else {
          // Track SSO consent as normal flow
          telemetryService.trackCustomEvent('SSO_ConsentRequired', {
            message: 'SSO consent flow initiated'
          });
          operationTimer.stop(true);
        }
      });
  } catch (error) {
    operationTimer.stop(false, error instanceof Error ? error.message : String(error));
    throw error;
  }
});

expressApp.post('/api/notify', async (req, res) => {
  const operationTimer = telemetryService.startOperation('ProactiveMessage');
  
  try {
    const userId = req.body.user_id;
    const message = req.body.message || 'This is a proactive message!';
    
    operationTimer.setContext(userId, 'proactive');
    
    const conversationReferences = bot.getConversationReferences();
    
    // Debug: Log the available user IDs and the requested user ID
    console.log('Requested user ID:', userId);
    console.log('Available conversation references:', Object.keys(conversationReferences));
    
    telemetryService.trackCustomEvent('ProactiveMessage_Requested', {
      userId,
      availableUsers: Object.keys(conversationReferences).length.toString(),
      messageLength: message.length.toString()
    });
    
    const reference = conversationReferences[userId];

    if (reference) {
      try {
        // Get the bot's app ID from config, use empty string for local testing
        const appId = config.MicrosoftAppId || "";
        
        // Use the correct method signature for continueConversationAsync
        await (adapter as any).continueConversationAsync(appId, reference, async (context) => {
          // var message=JSON.stringify(req.body)
          await context.sendActivity(message);
        });
        
        telemetryService.trackCustomEvent('ProactiveMessage_Sent', {
          userId,
          success: 'true',
          messageLength: message.length.toString()
        });
        
        operationTimer.stop(true);
        res.status(200).send('Message sent');
      } catch (error) {
        console.error('Error sending proactive message:', error);
        
        telemetryService.trackException(error instanceof Error ? error : new Error(String(error)), {
          userId,
          operation: 'ProactiveMessage_Send'
        });
        
        operationTimer.stop(false, error instanceof Error ? error.message : String(error));
        res.status(500).send('Error sending message');
      }
    } else {
      telemetryService.trackCustomEvent('ProactiveMessage_UserNotFound', {
        userId,
        availableUsers: Object.keys(conversationReferences).join(',')
      });
      
      operationTimer.stop(false, 'User not found');
      res.status(404).send(`User not found. Available users: ${Object.keys(conversationReferences).join(', ')}`);
    }
  } catch (error) {
    operationTimer.stop(false, error instanceof Error ? error.message : String(error));
    throw error;
  }
});

expressApp.get(["/auth-start.html", "/auth-end.html"], async (req, res) => {
  send(
    req,
    path.join(
      __dirname,
      "../public",
      req.url.includes("auth-start.html") ? "auth-start.html" : "auth-end.html"
    )
  ).pipe(res);
});
