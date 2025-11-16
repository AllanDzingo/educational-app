const express = require('express');
const dotenv = require('dotenv');
dotenv.config();
const app = express();
app.use(express.json());
app.get('/', (req, res) => {
    res.send('auth-service is running on port 3001!');
});
const PORT = process.env.PORT || 3001;
app.listen(PORT, () => console.log('auth-service running on port ' + PORT));
