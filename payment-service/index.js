const express = require('express');
const dotenv = require('dotenv');
dotenv.config();
const app = express();
app.use(express.json());
app.get('/', (req, res) => {
    res.send('payment-service is running on port 3003!');
});
const PORT = process.env.PORT || 3003;
app.listen(PORT, () => console.log('payment-service running on port ' + PORT));
