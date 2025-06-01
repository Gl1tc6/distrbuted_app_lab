import React, { useState, useEffect } from 'react';
import axios from 'axios';

function App() {
  const [users, setUsers] = useState([]);
  const [token, setToken] = useState(localStorage.getItem('token'));

  const fetchUsers = async () => {
    if (!token) return;
    try {
      const response = await axios.get('/api/v1/users', {
        headers: { Authorization: `Bearer ${token}` }
      });
      setUsers(response.data);
    } catch (error) {
      console.error('Error fetching users:', error);
    }
  };

  const login = async () => {
    try {
      const response = await axios.post('/api/auth/login', {
        username: 'admin',
        password: 'admin123'
      });
      setToken(response.data.token);
      localStorage.setItem('token', response.data.token);
    } catch (error) {
      console.error('Login failed:', error);
    }
  };

  useEffect(() => {
    if (token) fetchUsers();
  }, [token]);

  return (
    <div style={{ padding: '20px', fontFamily: 'Arial' }}>
      <h1>DynamicSoft - Upravljanje korisnicima</h1>
      {!token ? (
        <button onClick={login}>Prijaviť se</button>
      ) : (
        <div>
          <h2>Korisnici:</h2>
          <button onClick={fetchUsers}>Osvježi</button>
          <ul>
            {users.map(user => (
              <li key={user.id}>{user.username} - {user.email}</li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}

export default App;