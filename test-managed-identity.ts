import { DefaultAzureCredential } from "@azure/identity";
import { CosmosDbPartitionedStorage } from "botbuilder-azure";

async function testManagedIdentityConnection() {
    console.log('🔍 Testing Managed Identity connection to Cosmos DB...\n');
    
    // Check environment variables
    console.log('📋 Environment Configuration:');
    console.log('   COSMOS_DB_ENDPOINT:', process.env.COSMOS_DB_ENDPOINT ? '✅ Set' : '❌ Missing');
    console.log('   COSMOS_DB_USE_AAD:', process.env.COSMOS_DB_USE_AAD || 'Not set (will auto-detect)');
    console.log('   COSMOS_DB_DATABASE_ID:', process.env.COSMOS_DB_DATABASE_ID || 'bot-storage (default)');
    console.log('   COSMOS_DB_CONTAINER_ID:', process.env.COSMOS_DB_CONTAINER_ID || 'bot-state (default)');
    console.log('   COSMOS_DB_AUTH_KEY:', process.env.COSMOS_DB_AUTH_KEY ? '⚠️  Set (will be ignored when using AAD)' : '✅ Not set (good for AAD)');
    
    if (!process.env.COSMOS_DB_ENDPOINT) {
        console.error('\n❌ COSMOS_DB_ENDPOINT is required!');
        return;
    }

    try {
        console.log('\n🔐 Creating Azure credential...');
        const credential = new DefaultAzureCredential({
            loggingOptions: {
                allowLoggingAccountIdentifiers: true
            }
        });

        console.log('🗄️  Initializing Cosmos DB storage...');
        const cosmosDbStorage = new CosmosDbPartitionedStorage({
            cosmosDbEndpoint: process.env.COSMOS_DB_ENDPOINT!,
            cosmosClientOptions: {
                aadCredentials: credential
            },
            databaseId: process.env.COSMOS_DB_DATABASE_ID || "bot-storage",
            containerId: process.env.COSMOS_DB_CONTAINER_ID || "bot-state",
            compatibilityMode: false
        });

        // Test writing data
        const testKey = 'managed-identity-test-' + Date.now();
        const testData = {
            timestamp: new Date().toISOString(),
            message: 'Test managed identity connection to Cosmos DB',
            environment: process.env.NODE_ENV || 'development',
            source: 'managed-identity-test'
        };

        console.log('✍️  Writing test data with managed identity...');
        await cosmosDbStorage.write({ [testKey]: testData });
        console.log('✅ Successfully wrote test data to Cosmos DB using managed identity!');

        // Test reading data
        console.log('📖 Reading test data...');
        const readData = await cosmosDbStorage.read([testKey]);
        console.log('✅ Successfully read data:', JSON.stringify(readData[testKey], null, 2));

        // Clean up test data
        console.log('🧹 Cleaning up test data...');
        await cosmosDbStorage.delete([testKey]);
        console.log('✅ Successfully deleted test data');

        console.log('\n🎉 Managed Identity connection test completed successfully!');
        console.log('\n📝 Your bot should now work with managed identity in App Service.');
        console.log('   Make sure to set COSMOS_DB_USE_AAD=true in your App Service configuration.');
        
    } catch (error: any) {
        console.error('\n❌ Managed Identity connection test failed:', error.message);
        
        // Provide specific troubleshooting guidance
        if (error.message.includes('ManagedIdentityCredential authentication unavailable')) {
            console.error('\n🔧 Troubleshooting:');
            console.error('   1. If running locally: Run "az login" to authenticate');
            console.error('   2. If in App Service: Enable system-assigned managed identity');
            console.error('   3. Ensure the managed identity has "Cosmos DB Built-in Data Contributor" role');
        } else if (error.message.includes('403') || error.message.includes('Forbidden')) {
            console.error('\n🔧 Troubleshooting:');
            console.error('   1. Check role assignments for your managed identity');
            console.error('   2. Ensure "Cosmos DB Built-in Data Contributor" role is assigned');
            console.error('   3. Role assignment may take a few minutes to propagate');
        } else if (error.message.includes('404')) {
            console.error('\n🔧 Troubleshooting:');
            console.error('   1. Check if database and container exist');
            console.error('   2. Verify COSMOS_DB_DATABASE_ID and COSMOS_DB_CONTAINER_ID values');
        } else {
            console.error('\n🔧 General troubleshooting steps:');
            console.error('   1. Check environment variables are set correctly');
            console.error('   2. Verify managed identity is enabled');
            console.error('   3. Check role assignments');
            console.error('   4. Review the full error details above');
        }
        
        console.error('\n📚 For detailed setup instructions, see:');
        console.error('   - MANAGED_IDENTITY_SETUP.md');
        console.error('   - AAD_COSMOS_SETUP.md');
    }
}

// Run the test
testManagedIdentityConnection().catch(console.error);
