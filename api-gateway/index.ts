import express, { Request, Response } from "express";
import axios, { AxiosError } from "axios";

const app = express();
app.use(express.json());

const PORT = process.env.PORT || 8000;

// --- Auth Service ---
app.use("/auth", async (req: Request, res: Response) => {
  try {
    const response = await axios({
      method: req.method,
      url: `http://auth-service:8001${req.path}`,
      data: req.body,
      headers: req.headers,
    });
    res.status(response.status).send(response.data);
  } catch (error: unknown) {
    if (axios.isAxiosError(error)) {
      res.status(error.response?.status || 500).send(error.response?.data || error.message);
    } else {
      res.status(500).send({ message: "Internal server error" });
    }
  }
});

// --- Learning Service ---
app.use("/learning", async (req: Request, res: Response) => {
  try {
    const response = await axios({
      method: req.method,
      url: `http://learning-service:8002${req.path}`,
      data: req.body,
      headers: req.headers,
    });
    res.status(response.status).send(response.data);
  } catch (error: unknown) {
    if (axios.isAxiosError(error)) {
      res.status(error.response?.status || 500).send(error.response?.data || error.message);
    } else {
      res.status(500).send({ message: "Internal server error" });
    }
  }
});

// --- Payment Service ---
app.use("/payments", async (req: Request, res: Response) => {
  try {
    const response = await axios({
      method: req.method,
      url: `http://payment-service:8003${req.path}`,
      data: req.body,
      headers: req.headers,
    });
    res.status(response.status).send(response.data);
  } catch (error: unknown) {
    if (axios.isAxiosError(error)) {
      res.status(error.response?.status || 500).send(error.response?.data || error.message);
    } else {
      res.status(500).send({ message: "Internal server error" });
    }
  }
});
console.log("Starting API Gateway...");
app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
});

// --- Start Server ---
app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
});
