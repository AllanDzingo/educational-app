const express = require("express");
const axios = require("axios");

const app = express();
app.use(express.json());

// ===== AUTH SERVICE (PORT 3001) =====
app.use("/auth", async (req, res) => {
    try {
        const response = await axios({
            method: req.method,
            url: "http://localhost:3001" + req.originalUrl.replace("/auth", ""),
            data: req.body
        });
        res.send(response.data);
    } catch (error) {
        res.status(error.response?.status || 500).send(error.response?.data || error.message);
    }
});

// ===== LEARNING SERVICE (PORT 3002) =====
app.use("/learning", async (req, res) => {
    try {
        const response = await axios({
            method: req.method,
            url: "http://localhost:3002" + req.originalUrl.replace("/learning", ""),
            data: req.body
        });
        res.send(response.data);
    } catch (error) {
        res.status(error.response?.status || 500).send(error.response?.data || error.message);
    }
});

// ===== PAYMENT SERVICE (PORT 3003) =====
app.use("/payments", async (req, res) => {
    try {
        const response = await axios({
            method: req.method,
            url: "http://localhost:3003" + req.originalUrl.replace("/payments", ""),
            data: req.body
        });
        res.send(response.data);
    } catch (error) {
        res.status(error.response?.status || 500).send(error.response?.data || error.message);
    }
});

// ===== HOME PAGE =====
app.get("/", (req, res) => {
    res.send("API Gateway is running");
});

// ===== START GATEWAY =====
app.listen(8000, () => {
    console.log("API Gateway running on http://localhost:8000");
});
