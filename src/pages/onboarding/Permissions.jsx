import { useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useOnboarding } from '../../context/OnboardingContext';
import { useUserPreferences } from '../../context/UserPreferencesContext';
import { useAuth } from '../../context/AuthContext';
import { hasSupabase } from '../../lib/supabase';
import '../../styles/Onboarding.css';

export default function Permissions() {
  const { completeOnboarding } = useOnboarding();
  const { user, updateProfile } = useAuth();
  const { locationEnabled, notificationsEnabled, requestLocation, requestNotifications, update } = useUserPreferences();
  const navigate = useNavigate();

  useEffect(() => {
    if ('Notification' in window && Notification.permission === 'granted') {
      update({ notificationsEnabled: true });
    }
  }, [update]);

  useEffect(() => {
    completeOnboarding();
  }, [completeOnboarding]);

  const handleFinish = () => {
    navigate('/', { replace: true });
  };

  const handleRequestLocation = async () => {
    const result = await requestLocation();
    if (hasSupabase && user?.id !== 'demo' && result?.granted && result.latitude != null && result.longitude != null) {
      await updateProfile({ latitude: result.latitude, longitude: result.longitude });
    }
  };
  const handleRequestNotifications = () => requestNotifications();

  return (
    <div className="onboarding-page permissions">
      <div className="permissions-content">
        <h1>Almost there!</h1>
        <p className="step-desc">Enable these to get the best experience.</p>

        <div className="permission-card">
          <div className="permission-icon">📍</div>
          <div className="permission-text">
            <h3>Location</h3>
            <p>Find matches near you.</p>
          </div>
          <button
            className={`permission-btn ${locationEnabled ? 'enabled' : ''}`}
            onClick={handleRequestLocation}
          >
            {locationEnabled ? 'Enabled' : 'Enable'}
          </button>
        </div>

        <div className="permission-card">
          <div className="permission-icon">🔔</div>
          <div className="permission-text">
            <h3>Notifications</h3>
            <p>Never miss a match or message.</p>
          </div>
          <button
            className={`permission-btn ${notificationsEnabled ? 'enabled' : ''}`}
            onClick={handleRequestNotifications}
          >
            {notificationsEnabled ? 'Enabled' : 'Enable'}
          </button>
        </div>

        <p className="permissions-note">You can change these anytime in Settings.</p>
      </div>

      <div className="onboarding-actions single">
        <button className="btn-primary full" onClick={handleFinish}>
          Start matching
        </button>
      </div>
    </div>
  );
}
