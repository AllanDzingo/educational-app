const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
dotenv.config();
const app = express();
app.use(express.json());
app.use(cors());

app.get('/', (req, res) => {
    res.send('payment-service is running on port 3003!');
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        service: 'payment-service',
        timestamp: new Date().toISOString(),
        environment: process.env.ENVIRONMENT || 'development'
    });
});

// Sample payment endpoint
app.post('/process', (req, res) => {
    const { amount, currency } = req.body;
    res.json({
        success: true,
        transactionId: 'txn_' + Date.now(),
        amount,
        currency: currency || 'USD'
    });
});
const PORT = process.env.PORT || 3003;
app.listen(PORT, () => console.log('payment-service running on port ' + PORT));
