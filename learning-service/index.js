const express = require('express');
const dotenv = require('dotenv');
dotenv.config();
const app = express();
app.use(express.json());
app.get('/', (req, res) => {
    res.send('learning-service is running on port 3002!');
});
const PORT = process.env.PORT || 3002;
app.listen(PORT, () => console.log('learning-service running on port ' + PORT));
