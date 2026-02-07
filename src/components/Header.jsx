import { useNavigate } from 'react-router-dom';
import './Header.css';

export default function Header({ title, subtitle, showBack = false, rightAction }) {
  const navigate = useNavigate();

  return (
    <header className="app-header">
      <div className="header-inner">
        {showBack ? (
          <button className="icon-btn" onClick={() => navigate(-1)}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <polyline points="15 18 9 12 15 6" />
            </svg>
          </button>
        ) : (
          <div style={{ width: 40 }} />
        )}
        {title && <div className="header-title">{title}</div>}
        {rightAction || <div style={{ width: 40 }} />}
      </div>
      {subtitle && <p className="header-subtitle">{subtitle}</p>}
    </header>
  );
}
