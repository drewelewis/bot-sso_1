import {
  TeamsActivityHandler,
  TurnContext,
  SigninStateVerificationQuery,
  MemoryStorage,
  ConversationState,
  UserState,
  StatePropertyAccessor,
  Activity,
  ConversationReference,
} from "botbuilder";
import { SSODialog } from "./ssoDialog";
import { SSOCommandMap } from "./commands/SSOCommandMap";
import e from "express";

interface MessageHistoryItem {
  role: 'user' | 'assistant' | 'system' | 'tool';
  content: string;
}

export class TeamsBot extends TeamsActivityHandler {
  conversationState: ConversationState;
  userState: UserState;
  dialog: SSODialog;
  dialogState: StatePropertyAccessor;
  messageHistoryAccessor: StatePropertyAccessor<MessageHistoryItem[]>;
  private conversationReferences: { [key: string]: Partial<ConversationReference> } = {};

  constructor() {
    super();

    // Define the state store for your bot.
    // See https://aka.ms/about-bot-state to learn more about using MemoryStorage.
    // A bot requires a state storage system to persist the dialog and user state between messages.
    const memoryStorage = new MemoryStorage();



    // Create conversation and user state with in-memory storage provider.
    this.conversationState = new ConversationState(memoryStorage);
    this.userState = new UserState(memoryStorage);
    this.dialog = new SSODialog(new MemoryStorage());
    this.dialogState = this.conversationState.createProperty("DialogState");
    //this.messageHistoryAccessor = this.conversationState.createProperty("MessageHistory");
    // get the conversation id and user id from the context

    this.onMessage(async (context, next) => {
      console.log("Running with Message Activity.");

      // Store conversation reference for proactive messaging
      this.addConversationReference(context.activity);

      let txt = context.activity.text;
      // remove the mention of this bot
      const removedMentionText = TurnContext.removeRecipientMention(
        context.activity
      );
      if (removedMentionText) {
        // Remove the line break
        txt = removedMentionText.toLowerCase().replace(/\n|\r/g, "").trim();
      }
      
      // Trigger command by IM text
      if (SSOCommandMap.get(txt)) {
        await this.dialog.run(context, this.dialogState);
      }
      else
      {
        await context.sendActivity({type: "typing"});
        
        // Get the user's Entra ID from the context and use it as the session id
        // This is used to identify the user in the AI response
        // Note: context.activity.from.id is the Teams user ID, not the Entra ID
        // For Entra ID, we need to get it from the user's AAD object ID
        const userId = context.activity.from.aadObjectId || context.activity.from.id;
        const aiResponse = await this.getAIResponse(userId,txt);
        
        await context.sendActivity(aiResponse);
       }
       
    });

    // this.onMembersAdded(async (context, next) => {
    //   const membersAdded = context.activity.membersAdded;
    //   for (let cnt = 0; cnt < membersAdded.length; cnt++) {
    //     if (membersAdded[cnt].id) {
    //       await context.sendActivity("🎉 Welcome to the SSO Bot scheduling assistant!\n\n" +
    //         "💬 I'll keep track of our conversation history. You can:\n" +
    //         "• Chat normally and I'll remember our messages\n" +
    //         "• Type **'history'** to see our conversation summary\n" +
    //         "• Type **'clear history'** to start fresh\n" +
    //         "• Use SSO commands for authentication features\n\n" +
    //         "Let's start chatting!");
    //       break;
    //     }
    //   }
    //   await next();
    // });
  }

  private addConversationReference(activity: Activity): void {
    const conversationReference = TurnContext.getConversationReference(activity);
    this.conversationReferences[
      conversationReference.user.id
    ] = conversationReference;
  }

  public getConversationReferences(): { [key: string]: Partial<ConversationReference> } {
    return this.conversationReferences;
  }

  async run(context: TurnContext) {
    await super.run(context);

    // Save any state changes. The load happened during the execution of the Dialog.
    await this.conversationState.saveChanges(context, false);
    await this.userState.saveChanges(context, false);
  }

  async handleTeamsSigninVerifyState(
    context: TurnContext,
    query: SigninStateVerificationQuery
  ) {
    console.log(
      "Running dialog with signin/verifystate from an Invoke Activity."
    );
    await this.dialog.run(context, this.dialogState);
  }

  async handleTeamsSigninTokenExchange(
    context: TurnContext,
    query: SigninStateVerificationQuery
  ) {
    await this.dialog.run(context, this.dialogState);
  }

  async onSignInInvoke(context: TurnContext) {
    await this.dialog.run(context, this.dialogState);
  }

  // outputs the AI response in the following format:
  async getAIResponse(session_id: string, message: string): Promise<string> {
    // Get agent url from environment variable
    const url = process.env.AGENT_URL || "http://localhost:8989/agent_chat";

    // We can use the `Headers` constructor to create headers
    // and assign it as the type of the `headers` variable
    const headers: Headers = new Headers();
    // Add a few headers
    headers.set('Content-Type', 'application/json');
    headers.set('Accept', 'application/json');

    // Create the request object, which will be a RequestInfo type. 
    // Here, we will pass in the URL as well as the options object as parameters.
    const request: Request = new Request(url, {
      method: 'POST',
      headers: headers,
      body: JSON.stringify({ session_id: session_id, message: message })
    });

    try {
      // Pass in the request object to the `fetch` API
      const response = await fetch(request);
      
      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status} calling URL: ${url}`);
      }
      
      const data = await response.json();
      
      // Extract the response text from the API response
      // This depends on your API's response format
      if (data && data.response) {
        return data.response;
      } else if (data && data.message) {
        return data.message;
      } else if (typeof data === 'string') {
        return data;
      } else {
        return JSON.stringify(data);
      }
    } catch (error) {
      console.error('Fetch error:', error);
      // Return a fallback message instead of the error object
      return `Sorry, I encountered an error while processing your request: ${error.message}`;
    }
  }

  

  // Process AI response, handling both JSON and plain text responses
  processAIResponse(response: string): string {
    try {
      // Try to parse as JSON first
      const jsonResponse = JSON.parse(response);
      
      // Check if it's an array of conversation messages
      if (Array.isArray(jsonResponse)) {
        return this.processConversationArray(jsonResponse);
      }
      
      // Check if it's a single message object
      if (jsonResponse.role && jsonResponse.content) {
        return jsonResponse.content;
      }
      
      // Check if it has a specific response field
      if (jsonResponse.response) {
        return jsonResponse.response;
      }
      
      // Check if it has a message field
      if (jsonResponse.message) {
        return jsonResponse.message;
      }
      
      // If it's a tool call response, extract relevant information
      if (jsonResponse.tool_calls || jsonResponse.function_call) {
        return this.processToolCallResponse(jsonResponse);
      }
      
      // For other JSON objects, try to extract meaningful content
      return this.extractMeaningfulContent(jsonResponse);
      
    } catch (error) {
      // If parsing fails, treat as plain text
      console.log('Response is not JSON, treating as plain text');
      return response;
    }
  }

  // Process an array of conversation messages
  private processConversationArray(messages: any[]): string {
    const lastMessage = messages[messages.length - 1];
    
    // If the last message is from assistant, return its content
    if (lastMessage && lastMessage.role === 'assistant') {
      return lastMessage.content || 'No content in assistant response';
    }
    
    // Look for tool results or function calls
    const toolResults = messages.filter(msg => msg.role === 'tool');
    if (toolResults.length > 0) {
      return this.processToolResults(toolResults);
    }
    
    // Fallback: return a summary of the conversation
    return `Received ${messages.length} messages. Last message: ${lastMessage?.content || 'No content'}`;
  }

  // Process tool call responses
  private processToolCallResponse(response: any): string {
    if (response.tool_calls) {
      const toolCall = response.tool_calls[0];
      return `Executed tool: ${toolCall.function?.name || 'Unknown'} with result: ${JSON.stringify(toolCall.function?.arguments || {})}`;
    }
    
    if (response.function_call) {
      return `Function call: ${response.function_call.name} with arguments: ${response.function_call.arguments}`;
    }
    
    return 'Tool call response received';
  }

  // Process tool results
  private processToolResults(toolResults: any[]): string {
    if (toolResults.length === 1) {
      const result = toolResults[0];
      try {
        // Try to parse the tool result content
        const parsedContent = JSON.parse(result.content);
        
        // If it's user data from Microsoft Graph API
        if (Array.isArray(parsedContent) && parsedContent[0]?.display_name) {
          return this.formatUserList(parsedContent);
        }
        
        return `Tool result: ${result.content}`;
      } catch {
        return `Tool result: ${result.content}`;
      }
    }
    
    return `Received ${toolResults.length} tool results`;
  }

  // Format user list from Microsoft Graph API
  private formatUserList(users: any[]): string {
    if (users.length === 0) {
      return 'No users found.';
    }
    
    let formatted = `Found ${users.length} user(s):\n\n`;
    
    users.forEach((user, index) => {
      formatted += `${index + 1}. **${user.display_name || 'No name'}**\n`;
      if (user.job_title) formatted += `   • Job Title: ${user.job_title}\n`;
      if (user.department) formatted += `   • Department: ${user.department}\n`;
      if (user.mail) formatted += `   • Email: ${user.mail}\n`;
      formatted += '\n';
    });
    
    return formatted;
  }

  // Extract meaningful content from generic JSON objects
  private extractMeaningfulContent(obj: any): string {
    // Common fields that might contain meaningful content
    const contentFields = ['content', 'text', 'message', 'response', 'result', 'data'];
    
    for (const field of contentFields) {
      if (obj[field] && typeof obj[field] === 'string') {
        return obj[field];
      }
    }
    
    // If no meaningful field found, stringify the object
    return JSON.stringify(obj, null, 2);
  }

  // Parse conversation response and extract items for history
  parseConversationResponse(response: string): { displayMessage: string, conversationItems: MessageHistoryItem[] } {
    try {
      const parsedResponse = JSON.parse(response);
      const conversationItems: MessageHistoryItem[] = [];
      let displayMessage = '';

      // Check if it's an array of conversation messages (like your sample)
      if (Array.isArray(parsedResponse)) {
        // Filter out system messages and process the conversation
        const relevantMessages = parsedResponse.filter(msg => 
          msg.role && ['user', 'assistant', 'tool'].includes(msg.role)
        );

        // Add all relevant messages to conversation items
        relevantMessages.forEach(msg => {
          if (msg.role === 'user' || msg.role === 'assistant') {
            conversationItems.push({
              role: msg.role,
              content: msg.content || ''
            });
          } else if (msg.role === 'tool') {
            // Tool messages are added to history as-is, without processing for display
            conversationItems.push({
              role: 'tool',
              content: msg.content || ''
            });
          }
        });

        // Get the last assistant message for display
        const lastAssistantMessage = relevantMessages
          .filter(msg => msg.role === 'assistant')
          .pop();

        if (lastAssistantMessage) {
          displayMessage = lastAssistantMessage.content || 'Response received';
        } else {
          // If no assistant message, show a generic message
          displayMessage = 'Conversation processed successfully';
        }
      } else {
        // Handle single message objects
        conversationItems.push({
          role: 'assistant',
          content: response
        });
        displayMessage = response;
      }

      return { displayMessage, conversationItems };
    } catch (error) {
      console.log('Failed to parse as conversation JSON, treating as simple text');
      return {
        displayMessage: response,
        conversationItems: [{ role: 'assistant', content: response }]
      };
    }
  }

  // Process tool content to extract meaningful information
  private processToolContent(toolContent: string): string {
    try {
      // Check if tool content contains user data (Python objects)
      if (toolContent.includes('User(') && toolContent.includes('display_name=')) {
        return this.extractUserDataFromToolContent(toolContent);
      }
      
      // Try to parse as JSON
      const parsed = JSON.parse(toolContent);
      if (Array.isArray(parsed) && parsed[0]?.display_name) {
        return this.formatUserList(parsed);
      }
      
      return toolContent;
    } catch {
      return toolContent;
    }
  }

  // Extract user data from Python object string representation
  private extractUserDataFromToolContent(content: string): string {
    const userMatches = content.match(/User\([^)]+display_name='([^']+)'[^)]+job_title='([^']*)'[^)]+department='([^']*)'[^)]+mail='([^']*)'/g);
    
    if (userMatches && userMatches.length > 0) {
      let formatted = `Found ${userMatches.length} user(s):\n\n`;
      
      userMatches.forEach((match, index) => {
        const nameMatch = match.match(/display_name='([^']+)'/);
        const jobMatch = match.match(/job_title='([^']*)'/);
        const deptMatch = match.match(/department='([^']*)'/);
        const emailMatch = match.match(/mail='([^']*)'/);
        
        const name = nameMatch ? nameMatch[1] : 'Unknown';
        const job = jobMatch ? jobMatch[1] : '';
        const dept = deptMatch ? deptMatch[1] : '';
        const email = emailMatch ? emailMatch[1] : '';
        
        formatted += `${index + 1}. **${name}**\n`;
        if (job) formatted += `   • Job Title: ${job}\n`;
        if (dept) formatted += `   • Department: ${dept}\n`;
        if (email) formatted += `   • Email: ${email}\n`;
        formatted += '\n';
      });
      
      return formatted;
    }
    
    return content;
  }
 }
