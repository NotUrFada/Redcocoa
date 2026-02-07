import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { getAuthErrorMessage } from '../lib/authErrors';
import { hasSupabase } from '../lib/supabase';
import '../styles/Auth.css';

export default function ResetPassword() {
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const { user, recoverySession, updatePassword, clearRecoverySession } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    if (!hasSupabase) return;
    const hash = window.location.hash;
    if (!hash && !recoverySession && !user) {
      clearRecoverySession();
    }
  }, [recoverySession, user, clearRecoverySession]);

  async function handleSubmit(e) {
    e.preventDefault();
    setError('');
    if (password !== confirmPassword) {
      setError('Passwords do not match');
      return;
    }
    if (password.length < 6) {
      setError('Password must be at least 6 characters');
      return;
    }
    setLoading(true);
    try {
      await updatePassword(password);
      setSuccess(true);
      setTimeout(() => navigate('/login', { replace: true }), 2000);
    } catch (err) {
      setError(getAuthErrorMessage(err));
    } finally {
      setLoading(false);
    }
  }

  const showForm = hasSupabase && recoverySession && user;

  if (!hasSupabase) {
    return (
      <div className="auth-page">
        <div className="auth-container">
          <div className="auth-brand">
            <div className="brand-icon" />
            <h1>Red Cocoa</h1>
            <p>Password reset is not available in demo mode.</p>
          </div>
          <p className="auth-switch">
            <button type="button" onClick={() => navigate('/login')}>
              Back to Sign In
            </button>
          </p>
        </div>
      </div>
    );
  }

  if (success) {
    return (
      <div className="auth-page">
        <div className="auth-container">
          <div className="auth-brand">
            <div className="brand-icon" />
            <h1>Password updated</h1>
            <p>Redirecting you to sign in...</p>
          </div>
        </div>
      </div>
    );
  }

  if (!showForm) {
    return (
      <div className="auth-page">
        <div className="auth-container">
          <div className="auth-brand">
            <div className="brand-icon" />
            <h1>Invalid or expired link</h1>
            <p>Request a new password reset link from the login page.</p>
          </div>
          <p className="auth-switch">
            <button type="button" onClick={() => navigate('/login')}>
              Back to Sign In
            </button>
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="auth-page">
      <div className="auth-container">
        <div className="auth-brand">
          <div className="brand-icon" />
          <h1>Set new password</h1>
          <p>Enter your new password below</p>
        </div>

        <form onSubmit={handleSubmit} className="auth-form">
          {error && <div className="auth-error">{error}</div>}
          <input
            type="password"
            placeholder="New password (min 6 characters)"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
            required
            minLength={6}
            autoComplete="new-password"
          />
          <input
            type="password"
            placeholder="Confirm new password"
            value={confirmPassword}
            onChange={(e) => setConfirmPassword(e.target.value)}
            required
            minLength={6}
            autoComplete="new-password"
          />
          <button type="submit" className="btn-primary" disabled={loading}>
            {loading ? 'Updating...' : 'Update password'}
          </button>
        </form>

        <p className="auth-switch">
          <button type="button" onClick={() => navigate('/login')}>
            Back to Sign In
          </button>
        </p>
      </div>
    </div>
  );
}
