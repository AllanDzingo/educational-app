const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');
dotenv.config();
const app = express();
app.use(express.json());
app.use(cors());

app.get('/', (req, res) => {
    res.send('learning-service is running on port 3002!');
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({
        status: 'healthy',
        service: 'learning-service',
        timestamp: new Date().toISOString(),
        environment: process.env.ENVIRONMENT || 'development'
    });
});

// Sample courses endpoint
app.get('/courses', (req, res) => {
    res.json([
        { id: 1, title: 'Introduction to Programming', description: 'Learn the basics' },
        { id: 2, title: 'Advanced JavaScript', description: 'Master JS concepts' },
        { id: 3, title: 'DevOps Fundamentals', description: 'CI/CD and more' }
    ]);
});
const PORT = process.env.PORT || 3002;
app.listen(PORT, () => console.log('learning-service running on port ' + PORT));
