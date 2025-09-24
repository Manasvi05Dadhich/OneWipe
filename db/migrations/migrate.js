// Import the database connection from the parent 'db' directory
const db = require('../index');

// Define an async function to handle the database query
const createVerificationLogTable = async () => {
    // The SQL command to create our table.
    // "IF NOT EXISTS" prevents an error if we try to run the script multiple times.
    const queryText = `
        CREATE TABLE IF NOT EXISTS verification_logs (
            id SERIAL PRIMARY KEY,
            certificate_hash VARCHAR(255) NOT NULL,
            is_verified BOOLEAN NOT NULL,
            verified_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
        );
    `;

    try {
        // Execute the query using our database connection
        await db.query(queryText);
        console.log('✅ Table "verification_logs" created or already exists.');
    } catch (err) {
        console.error('❌ Error creating table:', err.stack);
    }
};

// Call the function to run the script
createVerificationLogTable();