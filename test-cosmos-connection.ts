import { CosmosDbPartitionedStorage } from "botbuilder-azure";

async function testCosmosDbConnection() {
    console.log('Testing Cosmos DB connection...');
    
    // Check environment variables
    console.log('Environment variables:');
    console.log('COSMOS_DB_ENDPOINT:', process.env.COSMOS_DB_ENDPOINT ? 'Set' : 'Missing');
    console.log('COSMOS_DB_AUTH_KEY:', process.env.COSMOS_DB_AUTH_KEY ? 'Set' : 'Missing');
    console.log('COSMOS_DB_DATABASE_ID:', process.env.COSMOS_DB_DATABASE_ID || 'bot-storage');
    console.log('COSMOS_DB_CONTAINER_ID:', process.env.COSMOS_DB_CONTAINER_ID || 'bot-state');

    if (!process.env.COSMOS_DB_ENDPOINT || !process.env.COSMOS_DB_AUTH_KEY) {
        console.error('Missing required environment variables!');
        return;
    }

    try {
        const cosmosDbStorage = new CosmosDbPartitionedStorage({
            cosmosDbEndpoint: process.env.COSMOS_DB_ENDPOINT!,
            authKey: process.env.COSMOS_DB_AUTH_KEY!,
            databaseId: process.env.COSMOS_DB_DATABASE_ID || "bot-storage",
            containerId: process.env.COSMOS_DB_CONTAINER_ID || "bot-state",
            compatibilityMode: false
        });

        // Test writing data
        const testKey = 'test-connection-' + Date.now();
        const testData = {
            timestamp: new Date().toISOString(),
            message: 'Test connection to Cosmos DB',
            version: '1.0'
        };

        console.log('Writing test data...');
        await cosmosDbStorage.write({ [testKey]: testData });
        console.log('✅ Successfully wrote test data to Cosmos DB');

        // Test reading data
        console.log('Reading test data...');
        const readData = await cosmosDbStorage.read([testKey]);
        console.log('✅ Successfully read data from Cosmos DB:', readData);

        // Clean up test data
        console.log('Cleaning up test data...');
        await cosmosDbStorage.delete([testKey]);
        console.log('✅ Successfully deleted test data');

        console.log('🎉 Cosmos DB connection test completed successfully!');
    } catch (error) {
        console.error('❌ Cosmos DB connection test failed:', error);
        
        if (error.message.includes('401')) {
            console.error('Authentication failed. Check your COSMOS_DB_AUTH_KEY.');
        } else if (error.message.includes('404')) {
            console.error('Database or container not found. Make sure they exist.');
        } else if (error.message.includes('ENOTFOUND')) {
            console.error('Network error. Check your COSMOS_DB_ENDPOINT.');
        }
    }
}

// Run the test
testCosmosDbConnection().catch(console.error);
