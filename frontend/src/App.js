import React, { useState, useEffect } from 'react';
import { BrowserRouter as Router, Routes, Route, Link } from 'react-router-dom';
import UserList from './components/UserList';
import { getCurrentUser, logout } from './services/api';
import './App.css';

function App() {
  const [user, setUser] = useState(null);
  const [loading, setLoading] = useState(true);
  
  useEffect(() => {
    // Check if user is logged in on load
    const checkAuth = async () => {
      try {
        const userData = await getCurrentUser();
        setUser(userData);
      } catch (error) {
        console.error('Authentication check failed:', error);
      } finally {
        setLoading(false);
      }
    };
    
    checkAuth();
  }, []);
  
  const handleLogout = async () => {
    try {
      await logout();
      setUser(null);
    } catch (error) {
      console.error('Logout failed:', error);
    }
  };
  
  if (loading) {
    return <div className="app-loading">Loading...</div>;
  }
  
  return (
    <Router>
      <div className="app">
        <header className="app-header">
          <h1>User Management System</h1>
          <nav>
            <ul>
              <li><Link to="/">Home</Link></li>
              {user ? (
                <>
                  <li><Link to="/users">Users</Link></li>
                  <li><button onClick={handleLogout}>Logout</button></li>
                  <li className="user-info">Logged in as: {user.username}</li>
                </>
              ) : (
                <li><Link to="/login">Login</Link></li>
              )}
            </ul>
          </nav>
        </header>
        
        <main className="app-content">
          <Routes>
            <Route path="/" element={<Home />} />
            <Route path="/users" element={user ? <UserList /> : <Login setUser={setUser} />} />
            <Route path="/login" element={<Login setUser={setUser} />} />
          </Routes>
        </main>
        
        <footer className="app-footer">
          <p>User Management System v1.0 - © 2025 DynamicSoft</p>
          <p>Secure Distributed Application</p>
        </footer>
      </div>
    </Router>
  );
}

function Home() {
  return (
    <div className="home">
      <h2>Welcome to User Management System</h2>
      <p>A secure distributed application for managing user data.</p>
    </div>
  );
}

function Login({ setUser }) {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    try {
      // In a real app, this would call the API service login method
      const userData = { username, role: username === 'admin' ? 'admin' : 'user' };
      setUser(userData);
    } catch (error) {
      setError('Login failed. Please check your credentials.');
    }
  };
  
  return (
    <div className="login-form">
      <h2>Login</h2>
      {error && <p className="error">{error}</p>}
      <form onSubmit={handleSubmit}>
        <div>
          <label htmlFor="username">Username:</label>
          <input
            type="text"
            id="username"
            value={username}
            onChange={(e) => setUsername(e.target.value)}
            required
          />
        </div>
        <div>
          <label htmlFor="password">Password:</label>
          <input
            type="password"
            id="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
          />
        </div>
        <button type="submit">Login</button>
      </form>
    </div>
  );
}

export default App;
