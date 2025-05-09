import React, { useState, useEffect } from 'react';
import { getUsers } from '../services/api';
import sanitizeHtml from 'sanitize-html';

function UserList() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(1);
  const [limit, setLimit] = useState(10);
  
  useEffect(() => {
    const fetchUsers = async () => {
      try {
        setLoading(true);
        const data = await getUsers(page, limit);
        // Sanitize data for XSS protection
        const sanitizedUsers = data.map(user => ({
          ...user,
          username: sanitizeHtml(user.username),
          email: sanitizeHtml(user.email)
        }));
        setUsers(sanitizedUsers);
        setError(null);
      } catch (err) {
        setError('Failed to fetch users. Please try again later.');
        console.error('Error fetching users:', err);
      } finally {
        setLoading(false);
      }
    };
    
    fetchUsers();
  }, [page, limit]);
  
  const handlePageChange = (newPage) => {
    if (newPage > 0) {
      setPage(newPage);
    }
  };
  
  const handleLimitChange = (e) => {
    setLimit(Number(e.target.value));
    setPage(1); // Reset to first page when changing items per page
  };
  
  if (loading) {
    return <div className="loading">Loading users...</div>;
  }
  
  if (error) {
    return <div className="error-message">{error}</div>;
  }
  
  return (
    <div className="user-list">
      <h2>User List</h2>
      
      <div className="list-controls">
        <div className="items-per-page">
          <label htmlFor="limit">Items per page:</label>
          <select id="limit" value={limit} onChange={handleLimitChange}>
            <option value="5">5</option>
            <option value="10">10</option>
            <option value="20">20</option>
            <option value="50">50</option>
          </select>
        </div>
      </div>
      
      {users.length === 0 ? (
        <p>No users found.</p>
      ) : (
        <>
          <table className="users-table">
            <thead>
              <tr>
                <th>ID</th>
                <th>Username</th>
                <th>Email</th>
                <th>Created At</th>
              </tr>
            </thead>
            <tbody>
              {users.map(user => (
                <tr key={user.id}>
                  <td>{user.id}</td>
                  <td>{user.username}</td>
                  <td>{user.email}</td>
                  <td>{new Date(user.created_at).toLocaleString()}</td>
                </tr>
              ))}
            </tbody>
          </table>
          
          <div className="pagination">
            <button 
              onClick={() => handlePageChange(page - 1)}
              disabled={page === 1}
            >
              Previous
            </button>
            <span>Page {page}</span>
            <button 
              onClick={() => handlePageChange(page + 1)}
              disabled={users.length < limit}
            >
              Next
            </button>
          </div>
        </>
      )}
      
      <style jsx>{`
        .user-list {
          background-color: white;
          border-radius: 8px;
          box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
          padding: 1.5rem;
        }
        
        .users-table {
          width: 100%;
          border-collapse: collapse;
          margin: 1rem 0;
        }
        
        .users-table th, .users-table td {
          border: 1px solid #ddd;
          padding: 0.75rem;
          text-align: left;
        }
        
        .users-table th {
          background-color: #f2f2f2;
          font-weight: 600;
        }
        
        .users-table tr:nth-child(even) {
          background-color: #f9f9f9;
        }
        
        .users-table tr:hover {
          background-color: #f1f8ff;
        }
        
        .list-controls {
          display: flex;
          justify-content: space-between;
          margin-bottom: 1rem;
        }
        
        .pagination {
          display: flex;
          justify-content: center;
          align-items: center;
          margin-top: 1rem;
        }
        
        .pagination button {
          background-color: #3498db;
          color: white;
          border: none;
          padding: 0.5rem 1rem;
          margin: 0 0.5rem;
          border-radius: 4px;
          cursor: pointer;
        }
        
        .pagination button:disabled {
          background-color: #ccc;
          cursor: not-allowed;
        }
        
        .pagination span {
          margin: 0 1rem;
        }
        
        .items-per-page {
          display: flex;
          align-items: center;
        }
        
        .items-per-page label {
          margin-right: 0.5rem;
        }
        
        .loading, .error-message {
          padding: 2rem;
          text-align: center;
          background-color: white;
          border-radius: 8px;
          box-shadow: 0 2px 10px rgba(0, 0, 0, 0.1);
        }
        
        .error-message {
          color: #e74c3c;
        }
      `}</style>
    </div>
  );
}

export default UserList;
