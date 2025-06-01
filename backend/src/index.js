const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { Pool } = require('pg');

const app = express();
const port = process.env.PORT || 3000;

// Sigurnosni middleware
app.use(helmet());
app.use(cors());
app.use(express.json({ limit: '10mb' }));

const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: 'Too many requests' }
});
app.use(limiter);

// Database connection
const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://user:password@database:5432/dynamicsoft'
});

// JWT middleware
const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];
  
  if (!token) return res.sendStatus(401);
  
  jwt.verify(token, process.env.JWT_SECRET || 'secret', (err, user) => {
    if (err) return res.sendStatus(403);
    req.user = user;
    next();
  });
};

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', version: '1.0.0', timestamp: new Date() });
});

// Auth endpoints
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    
    if (username === 'admin' && password === 'admin123') {
      const token = jwt.sign(
        { username: 'admin', role: 'admin' },
        process.env.JWT_SECRET || 'secret',
        { expiresIn: '1h' }
      );
      res.json({ token });
    } else {
      res.status(401).json({ error: 'Invalid credentials' });
    }
  } catch (error) {
    res.status(500).json({ error: 'Server error' });
  }
});

// Users endpoints
app.get('/api/v1/users', authenticateToken, async (req, res) => {
  try {
    const result = await pool.query('SELECT id, username, email, created_at FROM users LIMIT 10');
    res.json(result.rows);
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Database error' });
  }
});

// V2 endpoint with enhanced security
app.get('/api/v2/users', authenticateToken, async (req, res) => {
  try {
    if (req.user.role !== 'admin') {
      return res.status(403).json({ error: 'Insufficient privileges' });
    }
    
    const limit = Math.min(parseInt(req.query.limit) || 10, 100);
    const offset = parseInt(req.query.offset) || 0;
    
    const result = await pool.query(
      'SELECT id, username, email, created_at FROM users LIMIT $1 OFFSET $2',
      [limit, offset]
    );
    
    res.set({
      'Content-Security-Policy': "default-src 'self'",
      'Strict-Transport-Security': 'max-age=31536000',
      'X-Content-Type-Options': 'nosniff'
    });
    
    res.json({
      version: 'v2',
      data: result.rows,
      metadata: { count: result.rows.length, timestamp: new Date() }
    });
  } catch (error) {
    console.error(error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

app.listen(port, () => {
  console.log(`Backend server running on port ${port}`);
});