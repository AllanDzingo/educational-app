import express, { Request, Response } from "express";
import axios, { AxiosError } from "axios";
import cors from "cors";

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 8000;

// Service URLs (support both Docker Compose and Cloud Run)
const AUTH_SERVICE_URL = process.env.AUTH_SERVICE_URL || 'http://auth-service:3001';
const LEARNING_SERVICE_URL = process.env.LEARNING_SERVICE_URL || 'http://learning-service:3002';
const PAYMENT_SERVICE_URL = process.env.PAYMENT_SERVICE_URL || 'http://payment-service:3003';

// Health check endpoint
app.get('/health', async (req: Request, res: Response) => {
  const healthStatus: any = {
    status: 'healthy',
    service: 'api-gateway',
    timestamp: new Date().toISOString(),
    environment: process.env.ENVIRONMENT || 'development',
    services: {
      auth: 'unknown',
      learning: 'unknown',
      payment: 'unknown'
    }
  };

  // Check auth service
  try {
    await axios.get(`${AUTH_SERVICE_URL}/health`, { timeout: 2000 });
    healthStatus.services.auth = 'healthy';
  } catch (error) {
    healthStatus.services.auth = 'unhealthy';
    healthStatus.status = 'degraded';
  }

  // Check learning service
  try {
    await axios.get(`${LEARNING_SERVICE_URL}/health`, { timeout: 2000 });
    healthStatus.services.learning = 'healthy';
  } catch (error) {
    healthStatus.services.learning = 'unhealthy';
    healthStatus.status = 'degraded';
  }

  // Check payment service
  try {
    await axios.get(`${PAYMENT_SERVICE_URL}/health`, { timeout: 2000 });
    healthStatus.services.payment = 'healthy';
  } catch (error) {
    healthStatus.services.payment = 'unhealthy';
    healthStatus.status = 'degraded';
  }

  const statusCode = healthStatus.status === 'healthy' ? 200 : 503;
  res.status(statusCode).json(healthStatus);
});

// --- Auth Service ---
app.use("/auth", async (req: Request, res: Response) => {
  try {
    const response = await axios({
      method: req.method,
      url: `${AUTH_SERVICE_URL}${req.path}`,
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
      url: `${LEARNING_SERVICE_URL}${req.path}`,
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
      url: `${PAYMENT_SERVICE_URL}${req.path}`,
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


// --- Start Server ---
app.listen(PORT, () => {
  console.log(`API Gateway running on port ${PORT}`);
});
