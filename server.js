// 1. Imports
const express = require('express');

// 2. Initialize App
const app = express();
const port = 3000;

// 3. Middleware
app.use(express.json());

// 4. Import Your Route Files
const wipeRoutes = require('./routes/wipe');
const certRoutes = require('./routes/cert');
const deviceRoutes = require('./routes/device');

// 5. Use the Routes
app.use('/api/wipe', wipeRoutes);
app.use('/api/certificate', certRoutes);
app.use('/api/device', deviceRoutes);

// A simple status check endpoint
app.get('/api/status', (req, res) => {
    res.json({ status: 'Backend server is up and running!' });
});

// 6. Start Server
app.listen(port, () => {
    console.log(`✅ Backend server is running and listening at http://localhost:${port}`);
});