import axios from 'axios';

// Create axios instance with default config
const api = axios.create({
  baseURL: '/api', // Will be proxied through nginx to backend service
  timeout: 5000,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Add request interceptor for auth token
api.interceptors.request.use(
  config => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  error => Promise.reject(error)
);

// Add response interceptor for error handling
api.interceptors.response.use(
  response => response,
  error => {
    // Redirect to login if receiving 401 Unauthorized
    if (error.response && error.response.status === 401) {
      localStorage.removeItem('token');
      window.location.href = '/login';
    }
    return Promise.reject(error);
  }
);

// Auth API functions
export const login = async (username, password) => {
  try {
    const response = await api.post('/auth/login', { username, password });
    const { token, user } = response.data;
    
    // Store token in localStorage
    localStorage.setItem('token', token);
    
    return user;
  } catch (error) {
    console.error('Login error:', error);
    throw error;
  }
};

export const logout = async () => {
  try {
    await api.post('/auth/logout');
    localStorage.removeItem('token');
  } catch (error) {
    console.error('Logout error:', error);
    // Clear token even if API request fails
    localStorage.removeItem('token');
    throw error;
  }
};

export const getCurrentUser = async () => {
  try {
    const response = await api.get('/auth/me');
    return response.data;
  } catch (error) {
    console.error('Get current user error:', error);
    throw error;
  }
};

// User API functions
export const getUsers = async (page = 1, limit = 10) => {
  try {
    const response = await api.get('/v1/users', {
      params: { page, limit }
    });
    return response.data;
  } catch (error) {
    console.error('Get users error:', error);
    throw error;
  }
};

export const getUserById = async (id) => {
  try {
    const response = await api.get(`/v1/users/${id}`);
    return response.data;
  } catch (error) {
    console.error(`Get user ${id} error:`, error);
    throw error;
  }
};

export const createUser = async (userData) => {
  try {
    const response = await api.post('/v1/users', userData);
    return response.data;
  } catch (error) {
    console.error('Create user error:', error);
    throw error;
  }
};

export const updateUser = async (id, userData) => {
  try {
    const response = await api.put(`/v1/users/${id}`, userData);
    return response.data;
  } catch (error) {
    console.error(`Update user ${id} error:`, error);
    throw error;
  }
};

export const deleteUser = async (id) => {
  try {
    const response = await api.delete(`/v1/users/${id}`);
    return response.data;
  } catch (error) {
    console.error(`Delete user ${id} error:`, error);
    throw error;
  }
};

export default api;
