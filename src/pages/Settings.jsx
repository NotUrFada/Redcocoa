import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useUserPreferences } from '../context/UserPreferencesContext';
import { HUMOR_PREFERENCE_OPTIONS, TONE_OPTIONS } from '../data/profileOptions';
import { getAuthErrorMessage } from '../lib/authErrors';
import Header from '../components/Header';
import '../styles/Settings.css';

export default function Settings() {
  const navigate = useNavigate();
  const { user, profile, signOut, updateProfile, updateEmail } = useAuth();
  const [showPhoneModal, setShowPhoneModal] = useState(false);
  const [phoneInput, setPhoneInput] = useState('');
  const [phoneSaving, setPhoneSaving] = useState(false);
  const [showEmailModal, setShowEmailModal] = useState(false);
  const [emailInput, setEmailInput] = useState('');
  const [emailSaving, setEmailSaving] = useState(false);
  const [emailError, setEmailError] = useState('');
  const [phoneError, setPhoneError] = useState('');
  const {
    ageMin,
    ageMax,
    maxDistance,
    interests,
    notificationsNewMatches,
    notificationsMessages,
    notificationsAppActivity,
    update,
  } = useUserPreferences();

  const handleLogout = async () => {
    await signOut();
    navigate('/login');
  };

  const openPhoneModal = () => {
    setPhoneInput(profile?.phone || user?.user_metadata?.phone || '');
    setPhoneError('');
    setShowPhoneModal(true);
  };

  const savePhone = async () => {
    const phone = phoneInput.trim() || null;
    setPhoneSaving(true);
    setPhoneError('');
    try {
      const timeout = new Promise((_, reject) =>
        setTimeout(() => reject(new Error('Request timed out. Please check your connection and try again.')), 10000)
      );
      await Promise.race([updateProfile({ phone }), timeout]);
      setShowPhoneModal(false);
    } catch (err) {
      setPhoneError(getAuthErrorMessage(err) || 'Failed to save phone number. Please try again.');
    } finally {
      setPhoneSaving(false);
    }
  };

  const openEmailModal = () => {
    setEmailInput(user?.email || '');
    setEmailError('');
    setShowEmailModal(true);
  };

  const saveEmail = async () => {
    const trimmed = emailInput.trim();
    if (!trimmed) return;
    setEmailSaving(true);
    setEmailError('');
    try {
      await updateEmail(trimmed);
      setShowEmailModal(false);
    } catch (err) {
      setEmailError(getAuthErrorMessage(err));
    } finally {
      setEmailSaving(false);
    }
  };

  return (
    <div className="settings-page">
      <Header title="Settings" showBack />

      <div className="content">
        <div className="section-label">Humor & Vibe</div>
        <div className="settings-group">
          <div className="settings-item">
            <div className="settings-info" style={{ width: '100%' }}>
              <span className="settings-title">Playful humor about myths & stereotypes</span>
              <div className="humor-options">
                {HUMOR_PREFERENCE_OPTIONS.map((opt) => (
                  <button
                    key={opt.value}
                    type="button"
                    className={`humor-opt ${profile?.humor_preference === opt.value ? 'selected' : ''}`}
                    onClick={() => updateProfile({ humor_preference: opt.value })}
                  >
                    {opt.emoji} {opt.label}
                  </button>
                ))}
              </div>
            </div>
          </div>
          <div className="settings-item">
            <div className="settings-info" style={{ width: '100%' }}>
              <span className="settings-title">Your tone</span>
              <div className="humor-options tone-options">
                {TONE_OPTIONS.map((opt) => (
                  <button
                    key={opt.value}
                    type="button"
                    className={`humor-opt ${profile?.tone_vibe === opt.value ? 'selected' : ''}`}
                    onClick={() => updateProfile({ tone_vibe: opt.value })}
                  >
                    {opt.label}
                  </button>
                ))}
              </div>
            </div>
          </div>
        </div>

        <div className="section-label">Account Management</div>
        <div className="settings-group">
          <button className="settings-item" onClick={() => navigate('/profile/edit')}>
            <div className="settings-info">
              <span className="settings-title">Edit Profile</span>
              <span className="settings-value">Photos, bio, preferences</span>
            </div>
            <svg className="settings-chevron" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </button>
          <button className="settings-item" onClick={openPhoneModal}>
            <div className="settings-info">
              <span className="settings-title">Phone Number</span>
              <span className="settings-value">{profile?.phone || user?.user_metadata?.phone || 'Not set'}</span>
            </div>
            <svg className="settings-chevron" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </button>
          <button className="settings-item" onClick={openEmailModal}>
            <div className="settings-info">
              <span className="settings-title">Email Address</span>
              <span className="settings-value">{user?.email || 'Not set'}</span>
            </div>
            <svg className="settings-chevron" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </button>
        </div>

        <div className="section-label">Dating Preferences</div>
        <div className="settings-group">
          <div className="settings-item">
            <div className="settings-info" style={{ width: '100%' }}>
              <div className="settings-row-inner">
                <span className="settings-title">Age Range</span>
                <span className="settings-value">{ageMin} - {ageMax}</span>
              </div>
              <div className="range-row">
                <span className="range-label">Min: {ageMin}</span>
                <input
                  type="range"
                  min="18"
                  max="50"
                  value={ageMin}
                  onChange={(e) => {
                    const v = parseInt(e.target.value);
                    update({ ageMin: v });
                    if (v > ageMax) update({ ageMax: v });
                  }}
                />
              </div>
              <div className="range-row">
                <span className="range-label">Max: {ageMax}</span>
                <input
                  type="range"
                  min="18"
                  max="60"
                  value={ageMax}
                  onChange={(e) => {
                    const v = parseInt(e.target.value);
                    update({ ageMax: v });
                    if (v < ageMin) update({ ageMin: v });
                  }}
                />
              </div>
            </div>
          </div>
          <div className="settings-item">
            <div className="settings-info" style={{ width: '100%' }}>
              <div className="settings-row-inner">
                <span className="settings-title">Maximum Distance</span>
                <span className="settings-value">{maxDistance} miles</span>
              </div>
              <input
                type="range"
                min="1"
                max="100"
                value={maxDistance}
                onChange={(e) => update({ maxDistance: parseInt(e.target.value) })}
              />
              <div className="range-labels">
                <span>1 mi</span>
                <span>100 mi</span>
              </div>
            </div>
          </div>
          <button className="settings-item" onClick={() => navigate('/profile/edit')}>
            <div className="settings-info">
              <span className="settings-title">Interests & Hobbies</span>
              <span className="settings-value">{interests?.length ? interests.join(', ') : 'None selected'}</span>
            </div>
            <svg className="settings-chevron" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </button>
        </div>

        <div className="section-label">Notifications</div>
        <div className="settings-group">
          <div className="settings-item">
            <span className="settings-title">New Matches</span>
            <label className="switch">
              <input
                type="checkbox"
                checked={notificationsNewMatches}
                onChange={(e) => update({ notificationsNewMatches: e.target.checked })}
              />
              <span className="slider" />
            </label>
          </div>
          <div className="settings-item">
            <span className="settings-title">Messages</span>
            <label className="switch">
              <input
                type="checkbox"
                checked={notificationsMessages}
                onChange={(e) => update({ notificationsMessages: e.target.checked })}
              />
              <span className="slider" />
            </label>
          </div>
          <div className="settings-item">
            <span className="settings-title">App Activity</span>
            <label className="switch">
              <input
                type="checkbox"
                checked={notificationsAppActivity}
                onChange={(e) => update({ notificationsAppActivity: e.target.checked })}
              />
              <span className="slider" />
            </label>
          </div>
        </div>

        <div className="section-label">Privacy & Safety</div>
        <div className="settings-group">
          <div className="settings-item">
            <span className="settings-title">Show me on Red Cocoa</span>
            <label className="switch">
              <input type="checkbox" defaultChecked />
              <span className="slider" />
            </label>
          </div>
          <button className="settings-item" onClick={() => navigate('/blocked')}>
            <span className="settings-title">Blocked Contacts</span>
            <svg className="settings-chevron" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </button>
        </div>

        <div className="section-label">Legal</div>
        <div className="settings-group">
          <button className="settings-item" onClick={() => navigate('/privacy')}>
            <span className="settings-title">Privacy Policy</span>
            <svg className="settings-chevron" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </button>
          <button className="settings-item" onClick={() => navigate('/terms')}>
            <span className="settings-title">Terms of Service</span>
            <svg className="settings-chevron" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </button>
        </div>

        <button className="logout-btn" onClick={handleLogout}>Log Out</button>
        <p className="version-text">Version 2.4.1 (Build 1082)</p>
      </div>

      {showPhoneModal && (
        <div className="modal-overlay" onClick={() => setShowPhoneModal(false)}>
          <div className="modal-content settings-modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Phone Number</h3>
              <button className="modal-close" onClick={() => setShowPhoneModal(false)} aria-label="Close">×</button>
            </div>
            <div className="modal-body">
              {phoneError && <div className="settings-modal-error">{phoneError}</div>}
              <input
                type="tel"
                inputMode="tel"
                autoComplete="tel"
                className="settings-modal-input"
                placeholder="e.g. +1 555 123 4567"
                value={phoneInput}
                onChange={(e) => setPhoneInput(e.target.value)}
                autoFocus
              />
            </div>
            <div className="modal-footer">
              <button className="btn-secondary-sm" onClick={() => setShowPhoneModal(false)}>Cancel</button>
              <button className="btn-primary-sm" onClick={savePhone} disabled={phoneSaving}>
                {phoneSaving ? 'Saving...' : 'Save'}
              </button>
            </div>
          </div>
        </div>
      )}

      {showEmailModal && (
        <div className="modal-overlay" onClick={() => !emailSaving && setShowEmailModal(false)}>
          <div className="modal-content settings-modal" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Email Address</h3>
              <button className="modal-close" onClick={() => !emailSaving && setShowEmailModal(false)} aria-label="Close">×</button>
            </div>
            <div className="modal-body">
              {emailError && <div className="settings-modal-error">{emailError}</div>}
              <input
                type="email"
                className="settings-modal-input"
                placeholder="Enter email address"
                value={emailInput}
                onChange={(e) => setEmailInput(e.target.value)}
                autoFocus
              />
            </div>
            <div className="modal-footer">
              <button className="btn-secondary-sm" onClick={() => !emailSaving && setShowEmailModal(false)}>Cancel</button>
              <button className="btn-primary-sm" onClick={saveEmail} disabled={emailSaving || !emailInput.trim()}>
                {emailSaving ? 'Saving...' : 'Save'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
