import { useNavigate } from 'react-router-dom';
import FullScreenLayout from '../components/FullScreenLayout';
import '../styles/Legal.css';

export default function TermsOfService() {
  const navigate = useNavigate();

  return (
    <FullScreenLayout>
      <div className="legal-page">
        <header className="legal-header">
          <button className="back-btn" onClick={() => navigate(-1)}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <polyline points="15 18 9 12 15 6" />
            </svg>
          </button>
          <h1>Terms of Service</h1>
        </header>
        <div className="legal-content">
          <p><strong>Last updated:</strong> January 2025</p>

          <h2>1. Acceptance</h2>
          <p>By using Red Cocoa, you agree to these terms. You must be 18+ to use this service.</p>

          <h2>2. Account</h2>
          <p>You are responsible for your account and must provide accurate information. You must not impersonate others or create fake profiles.</p>

          <h2>3. Conduct</h2>
          <p>You agree not to harass, abuse, or harm other users. Prohibited content includes illegal material, spam, and explicit content without consent. We reserve the right to remove content and suspend accounts.</p>

          <h2>4. Safety</h2>
          <p>Use caution when meeting in person. We do not conduct background checks. Report suspicious or harmful behavior through the app.</p>

          <h2>5. Intellectual Property</h2>
          <p>Red Cocoa and its content are owned by us. You retain rights to your profile content and grant us a license to display it.</p>

          <h2>6. Termination</h2>
          <p>We may terminate your access for violations. You may delete your account at any time.</p>

          <h2>7. Contact</h2>
          <p>For support: support@redcocoa.app</p>
        </div>
      </div>
    </FullScreenLayout>
  );
}
