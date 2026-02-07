import { useNavigate } from 'react-router-dom';
import FullScreenLayout from '../components/FullScreenLayout';
import '../styles/Legal.css';

export default function PrivacyPolicy() {
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
          <h1>Privacy Policy</h1>
        </header>
        <div className="legal-content">
          <p><strong>Last updated:</strong> January 2025</p>

          <h2>1. Information We Collect</h2>
          <p>We collect information you provide directly: profile details (name, photos, bio, preferences), messages, and usage data. We use device information for app functionality.</p>

          <h2>2. How We Use Your Information</h2>
          <p>We use your information to provide matching, messaging, and personalized features. We may use aggregated data to improve our services.</p>

          <h2>3. Sharing Your Information</h2>
          <p>Your profile is visible to other users based on your preferences. We do not sell your personal information. We may share data with service providers who assist our operations.</p>

          <h2>4. Data Security</h2>
          <p>We implement industry-standard security measures to protect your data. Messages are encrypted in transit.</p>

          <h2>5. Your Rights</h2>
          <p>You may access, correct, or delete your data through the app settings. You may request a copy of your data or withdraw consent at any time.</p>

          <h2>6. Contact</h2>
          <p>For privacy inquiries: privacy@redcocoa.app</p>
        </div>
      </div>
    </FullScreenLayout>
  );
}
