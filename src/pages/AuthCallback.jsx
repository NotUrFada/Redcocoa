import { useEffect, useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { supabase, hasSupabase } from '../lib/supabase';
import '../styles/Auth.css';

export default function AuthCallback() {
  const navigate = useNavigate();
  const location = useLocation();
  const [message, setMessage] = useState('Confirming...');

  useEffect(() => {
    if (!hasSupabase) {
      navigate('/login', { replace: true });
      return;
    }

    const hash = location.hash?.slice(1) || '';
    const params = Object.fromEntries(new URLSearchParams(hash));

    if (params.error) {
      if (params.error_code === 'otp_expired' || params.error_description?.includes('expired')) {
        setMessage('This link has expired. Please sign in and we can send you a new confirmation email.');
      } else {
        setMessage(params.error_description?.replace(/\+/g, ' ') || 'Something went wrong. Please try again.');
      }
      return;
    }

    if (params.access_token) {
      supabase.auth.setSession({
        access_token: params.access_token,
        refresh_token: params.refresh_token || '',
      }).then(() => {
        setMessage('Email confirmed! Redirecting...');
        setTimeout(() => navigate('/', { replace: true }), 1000);
      }).catch(() => {
        setMessage('Could not complete sign-in. Please try logging in.');
      });
      return;
    }

    setMessage('No confirmation data found. Try logging in.');
  }, [location.hash, navigate]);

  const isError = message !== 'Confirming...' && message !== 'Email confirmed! Redirecting...';

  return (
    <div className="auth-page auth-callback">
      <div className="auth-container">
        <h1 className="auth-callback-title">{isError ? 'Link expired or invalid' : message.includes('Redirecting') ? 'Success' : 'Confirming email'}</h1>
        <p className="auth-callback-message">{message}</p>
        {(isError || message === 'No confirmation data found. Try logging in.') && (
          <div className="auth-callback-actions">
            <button type="button" className="auth-callback-btn primary" onClick={() => navigate('/login', { replace: true })}>
              Go to Log in
            </button>
            <button type="button" className="auth-callback-btn secondary" onClick={() => navigate('/signup', { replace: true })}>
              Sign up again
            </button>
          </div>
        )}
      </div>
    </div>
  );
}
