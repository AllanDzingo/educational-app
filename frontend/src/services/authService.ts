import axios from "axios";

const API_URL = "http://localhost:8000/auth";

export const signup = async (data: { username: string; password: string }) => {
  const response = await axios.post(`${API_URL}/signup`, data);
  return response.data;
};

export const login = async (data: { username: string; password: string }) => {
  const response = await axios.post(`${API_URL}/login`, data);
  return response.data;
};
