import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { hasSupabase } from '../../lib/supabase';
import { HUMOR_PREFERENCE_OPTIONS, TONE_OPTIONS } from '../../data/profileOptions';
import '../../styles/Onboarding.css';

export default function Consent() {
  const [step, setStep] = useState(0);
  const [humorPreference, setHumorPreference] = useState('');
  const [toneVibe, setToneVibe] = useState('');
  const [respectAcknowledged, setRespectAcknowledged] = useState(false);
  const { user, updateProfile: updateAuthProfile } = useAuth();
  const navigate = useNavigate();

  const handleNext = async () => {
    if (step === 0) {
      if (!humorPreference) return;
      setStep(1);
    } else if (step === 1) {
      if (!toneVibe) return;
      setStep(2);
    } else if (step === 2) {
      if (!respectAcknowledged) return;
      try {
        await updateAuthProfile({ humor_preference: humorPreference, tone_vibe: toneVibe });
      } catch {
        // Don't block onboarding if profile update fails (e.g. migration not run)
      }
      navigate('/onboarding/profile');
    }
  };

  const canProceed = () => {
    if (step === 0) return !!humorPreference;
    if (step === 1) return !!toneVibe;
    if (step === 2) return respectAcknowledged;
    return false;
  };

  return (
    <div className="onboarding-page consent-page">
      <div className="onboarding-header">
        <button className="back-btn" onClick={() => (step > 0 ? setStep(step - 1) : navigate('/onboarding'))}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
            <polyline points="15 18 9 12 15 6" />
          </svg>
        </button>
        <div className="progress-bar">
          <div className="progress-fill" style={{ width: `${((step + 1) / 3) * 100}%` }} />
        </div>
        <span className="step-count">{step + 1} of 3</span>
      </div>

      <div className="setup-content">
        {step === 0 && (
          <>
            <h1>Humor & vibe</h1>
            <p className="step-desc">Do you enjoy playful, ironic humor about internet myths & stereotypes?</p>
            <p className="form-hint">This controls prompt visibility, icebreakers, badges, and stickers.</p>
            <div className="consent-options">
              {HUMOR_PREFERENCE_OPTIONS.map((opt) => (
                <button
                  key={opt.value}
                  type="button"
                  className={`consent-option ${humorPreference === opt.value ? 'selected' : ''}`}
                  onClick={() => setHumorPreference(opt.value)}
                >
                  <span className="consent-emoji">{opt.emoji}</span>
                  <span className="consent-label">{opt.label}</span>
                </button>
              ))}
            </div>
          </>
        )}

        {step === 1 && (
          <>
            <h1>Your tone</h1>
            <p className="step-desc">How do you like to communicate?</p>
            <p className="form-hint">We'll match you with humor-compatible users and avoid vibe mismatch in chat.</p>
            <div className="consent-options tone-options">
              {TONE_OPTIONS.map((opt) => (
                <button
                  key={opt.value}
                  type="button"
                  className={`consent-option ${toneVibe === opt.value ? 'selected' : ''}`}
                  onClick={() => setToneVibe(opt.value)}
                >
                  <span className="consent-label">{opt.label}</span>
                </button>
              ))}
            </div>
          </>
        )}

        {step === 2 && (
          <>
            <h1>The respect rule</h1>
            <p className="step-desc">One thing we ask everyone to agree to:</p>
            <div className="respect-rule-box">
              <p><strong>We joke with people, not about them.</strong></p>
              <p>No fetishizing. No dehumanizing. No &quot;just joking&quot; excuses.</p>
            </div>
            <label className="checkbox-label respect-checkbox">
              <input
                type="checkbox"
                checked={respectAcknowledged}
                onChange={(e) => setRespectAcknowledged(e.target.checked)}
              />
              <span>I agree to the respect rule</span>
            </label>
          </>
        )}
      </div>

      <div className="onboarding-actions single">
        <button className="btn-primary full" onClick={handleNext} disabled={!canProceed()}>
          {step === 2 ? 'Continue' : 'Next'}
        </button>
      </div>
    </div>
  );
}
