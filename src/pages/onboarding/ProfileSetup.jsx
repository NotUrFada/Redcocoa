import { useState, useRef } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import { useUserPreferences } from '../../context/UserPreferencesContext';
import { uploadProfilePhoto, setProfilePhotos, updatePreferences } from '../../lib/api';
import { hasSupabase } from '../../lib/supabase';
import { ALL_INTERESTS } from '../../data/mockData';
import { ETHNICITY_OPTIONS, HAIR_COLOR_OPTIONS, GINGER_PROMPTS, BLACK_PROMPTS, GINGER_BADGES, BLACK_BADGES } from '../../data/profileOptions';
import '../../styles/Onboarding.css';

const STEPS = ['basics', 'photos', 'interests', 'bio', 'culture', 'preferences'];

function parseBirthDateToISO(str) {
  if (!str || typeof str !== 'string') return null;
  const s = str.trim();
  if (!s) return null;
  const match = s.match(/^(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})$/);
  if (match) {
    const [, a, b, year] = match;
    const month = a.length === 1 ? `0${a}` : a;
    const day = b.length === 1 ? `0${b}` : b;
    return `${year}-${month}-${day}`;
  }
  if (/^\d{4}-\d{2}-\d{2}$/.test(s)) return s;
  return null;
}

export default function ProfileSetup() {
  const [step, setStep] = useState(0);
  const [saving, setSaving] = useState(false);
  const fileInputRef = useRef(null);
  const filesToUploadRef = useRef([]);
  const { user, updateProfile, profile } = useAuth();
  const { update: updatePrefs, requestLocation, latitude, longitude } = useUserPreferences();
  const navigate = useNavigate();

  const [formData, setFormData] = useState({
    name: profile?.name || '',
    birthDate: '',
    location: '',
    bio: '',
    interestedIn: 'Everyone',
    ageMin: 22,
    ageMax: 35,
    maxDistance: 25,
    interests: [],
    photos: [],
    ethnicity: profile?.ethnicity || '',
    hairColor: profile?.hair_color || '',
    preferredEthnicities: [],
    preferredHairColors: [],
    promptResponses: {},
    badges: [],
    debunkedLines: [],
    notHereFor: { explain: '', dontMessage: '', redFlag: '' },
  });

  const currentStep = STEPS[step];
  const isLast = step === STEPS.length - 1;

  const update = (key, value) => setFormData((f) => ({ ...f, [key]: value }));

  const toggleInterest = (interest) => {
    setFormData((f) => ({
      ...f,
      interests: f.interests.includes(interest)
        ? f.interests.filter((i) => i !== interest)
        : [...f.interests, interest],
    }));
  };

  const handlePhotoSelect = (e) => {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;
    filesToUploadRef.current = [...filesToUploadRef.current, ...files].slice(0, 6);
    const toAdd = [];
    let remaining = files.length;
    files.forEach((file) => {
      const reader = new FileReader();
      reader.onload = (ev) => {
        toAdd.push(ev.target.result);
        remaining--;
        if (remaining === 0) {
          setFormData((f) => ({
            ...f,
            photos: [...f.photos, ...toAdd].slice(0, 6),
          }));
        }
      };
      reader.readAsDataURL(file);
    });
  };

  const removePhoto = (index) => {
    filesToUploadRef.current = filesToUploadRef.current.filter((_, i) => i !== index);
    setFormData((f) => ({
      ...f,
      photos: f.photos.filter((_, i) => i !== index),
    }));
  };

  const handleNext = async () => {
    if (isLast) {
      updatePrefs({
        ageMin: formData.ageMin,
        ageMax: formData.ageMax,
        maxDistance: formData.maxDistance,
        interestedIn: formData.interestedIn,
        interests: formData.interests,
        photos: formData.photos,
        bio: formData.bio,
        preferredEthnicities: formData.preferredEthnicities,
        preferredHairColors: formData.preferredHairColors,
      });
      navigate('/onboarding/permissions', { replace: true });

      (async () => {
        try {
          let photoUrls = [];
          if (hasSupabase && user?.id !== 'demo' && filesToUploadRef.current.length > 0) {
            for (const file of filesToUploadRef.current) {
              const url = await uploadProfilePhoto(user.id, file);
              if (url) photoUrls.push(url);
            }
            if (photoUrls.length) await setProfilePhotos(user.id, photoUrls);
          }

          const profileUpdates = {
            name: formData.name,
            birth_date: parseBirthDateToISO(formData.birthDate) || null,
            bio: formData.bio,
            interests: formData.interests,
            location: formData.location || null,
            latitude: latitude || null,
            longitude: longitude || null,
            ethnicity: formData.ethnicity || null,
            hair_color: formData.hairColor || null,
            prompt_responses: Object.keys(formData.promptResponses).length ? formData.promptResponses : null,
            badges: formData.badges.length ? formData.badges : null,
            debunked_lines: (formData.debunkedLines || []).filter(Boolean).length ? (formData.debunkedLines || []).filter(Boolean) : null,
            not_here_for: (formData.notHereFor.explain || formData.notHereFor.dontMessage || formData.notHereFor.redFlag)
              ? { explain: formData.notHereFor.explain, dont_message: formData.notHereFor.dontMessage, red_flag: formData.notHereFor.redFlag } : null,
          };
          if (photoUrls.length) profileUpdates.photo_urls = photoUrls;
          await updateProfile(profileUpdates);

          if (hasSupabase && user?.id !== 'demo') {
            await updatePreferences(user.id, {
              age_min: formData.ageMin,
              age_max: formData.ageMax,
              max_distance_miles: formData.maxDistance,
              interested_in: [formData.interestedIn],
              preferredEthnicities: formData.preferredEthnicities,
              preferredHairColors: formData.preferredHairColors,
            });
          }
        } catch (err) {
          console.warn('Profile setup save error:', err);
        }
      })();
    } else {
      try {
        if (currentStep === 'basics' && formData.location) {
          updatePrefs({ location: formData.location });
        }
      } catch (e) {
        console.warn('Prefs update:', e);
      }
      setStep((s) => Math.min(s + 1, STEPS.length - 1));
    }
  };

  const handleBack = () => {
    if (step > 0) setStep((s) => s - 1);
    else navigate('/onboarding');
  };

  const canProceed = () => {
    if (currentStep === 'basics') return (formData.name || '').trim().length > 0;
    if (currentStep === 'interests') return formData.interests.length >= 3;
    if (currentStep === 'bio') return formData.bio.length >= 20;
    if (currentStep === 'culture') return true;
    return true;
  };

  const allBadges = [...GINGER_BADGES, ...BLACK_BADGES];
  const toggleBadge = (id) => {
    const has = formData.badges.includes(id);
    if (has) {
      update('badges', formData.badges.filter((b) => b !== id));
    } else if (formData.badges.length < 2) {
      update('badges', [...formData.badges, id]);
    }
  };

  return (
    <div className="onboarding-page profile-setup">
      <div className="onboarding-header">
        <button className="back-btn" onClick={handleBack}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
            <polyline points="15 18 9 12 15 6" />
          </svg>
        </button>
        <div className="progress-bar">
          <div className="progress-fill" style={{ width: `${((step + 1) / STEPS.length) * 100}%` }} />
        </div>
        <span className="step-count">{step + 1} of {STEPS.length}</span>
      </div>

      <div className="setup-content">
        {currentStep === 'basics' && (
          <>
            <h1>Let's get to know you</h1>
            <p className="step-desc">Add your basic info so we can find your best matches.</p>
            <div className="form-group">
              <label>First name</label>
              <input
                type="text"
                placeholder="Your name"
                value={formData.name}
                onChange={(e) => update('name', e.target.value)}
                autoFocus
              />
            </div>
            <div className="form-group">
              <label>Birthday</label>
              <input
                type="text"
                placeholder="MM/DD/YYYY"
                value={formData.birthDate}
                onChange={(e) => update('birthDate', e.target.value)}
                inputMode="numeric"
              />
            </div>
            <div className="form-group">
              <label>Ethnicity</label>
              <select
                value={formData.ethnicity}
                onChange={(e) => update('ethnicity', e.target.value)}
              >
                <option value="">Select...</option>
                {ETHNICITY_OPTIONS.map((opt) => (
                  <option key={opt} value={opt}>{opt}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label>Hair color</label>
              <select
                value={formData.hairColor}
                onChange={(e) => update('hairColor', e.target.value)}
              >
                <option value="">Select...</option>
                {HAIR_COLOR_OPTIONS.map((opt) => (
                  <option key={opt} value={opt}>{opt}</option>
                ))}
              </select>
            </div>
            <div className="form-group">
              <label>Location</label>
              <input
                type="text"
                placeholder="City, State"
                value={formData.location}
                onChange={(e) => update('location', e.target.value)}
              />
            </div>
            <button
              type="button"
              className="btn-location-detect"
              onClick={() => {
                requestLocation().then((ok) => {
                  if (ok) update('location', 'Current location');
                });
              }}
            >
              📍 Use my current location
            </button>
          </>
        )}

        {currentStep === 'photos' && (
          <>
            <h1>Add your photos</h1>
            <p className="step-desc">Profiles with photos get 10x more matches. Add at least 1.</p>
            <input
              ref={fileInputRef}
              type="file"
              accept="image/*"
              multiple
              style={{ display: 'none' }}
              onChange={handlePhotoSelect}
            />
            <div className="photo-upload-grid">
              {[0, 1, 2].map((i) => (
                <div
                  key={i}
                  className={`photo-slot ${i === 0 ? 'primary' : ''}`}
                  onClick={() => fileInputRef.current?.click()}
                >
                  {formData.photos[i] ? (
                    <div className="photo-preview">
                      <img src={formData.photos[i]} alt="" />
                      <button
                        type="button"
                        className="photo-remove"
                        onClick={(e) => { e.stopPropagation(); removePhoto(i); }}
                      >
                        ×
                      </button>
                    </div>
                  ) : (
                    <div className="photo-placeholder">
                      <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <rect x="3" y="3" width="18" height="18" rx="2" />
                        <circle cx="8.5" cy="8.5" r="1.5" />
                        <path d="M21 15l-5-5L5 21" />
                      </svg>
                      <span>{i === 0 ? 'Add photo' : '+'}</span>
                    </div>
                  )}
                </div>
              ))}
            </div>
          </>
        )}

        {currentStep === 'interests' && (
          <>
            <h1>What are you into?</h1>
            <p className="step-desc">Select at least 3 interests. This helps us find better matches.</p>
            <div className="interests-grid">
              {ALL_INTERESTS.map((interest) => (
                <button
                  key={interest}
                  type="button"
                  className={`interest-tag ${formData.interests.includes(interest) ? 'selected' : ''}`}
                  onClick={() => toggleInterest(interest)}
                >
                  {interest}
                </button>
              ))}
            </div>
            <p className="interests-count">{formData.interests.length} selected</p>
          </>
        )}

        {currentStep === 'bio' && (
          <>
            <h1>Write a short bio</h1>
            <p className="step-desc">Tell others what makes you unique. At least 20 characters.</p>
            <div className="form-group">
              <textarea
                placeholder="I love exploring new coffee shops, hiking on weekends, and..."
                value={formData.bio}
                onChange={(e) => update('bio', e.target.value)}
                rows={5}
              />
              <span className="char-count">{formData.bio.length}/500</span>
            </div>
          </>
        )}

        {currentStep === 'culture' && (
          <>
            <h1>Culture & expression</h1>
            <p className="step-desc">Optional. Add prompts, badges, and boundaries. Skip if you prefer.</p>

            <div className="culture-section">
              <h3 className="culture-section-title">🔥 Ginger Prompt Pack</h3>
              <p className="form-hint">Fill in any you like. Leave blank to skip.</p>
              {GINGER_PROMPTS.map((p) => (
                <div key={p.id} className="form-group">
                  <label>{p.text}</label>
                  <input
                    type="text"
                    placeholder="Your answer..."
                    value={formData.promptResponses[p.id] || ''}
                    onChange={(e) => update('promptResponses', { ...formData.promptResponses, [p.id]: e.target.value })}
                  />
                </div>
              ))}
            </div>

            <div className="culture-section">
              <h3 className="culture-section-title">🤎 Black Prompt Pack</h3>
              <p className="form-hint">Fill in any you like. Leave blank to skip.</p>
              {BLACK_PROMPTS.map((p) => (
                <div key={p.id} className="form-group">
                  <label>{p.text}</label>
                  <input
                    type="text"
                    placeholder="Your answer..."
                    value={formData.promptResponses[p.id] || ''}
                    onChange={(e) => update('promptResponses', { ...formData.promptResponses, [p.id]: e.target.value })}
                  />
                </div>
              ))}
            </div>

            <div className="culture-section">
              <h3 className="culture-section-title">Badges</h3>
              <p className="form-hint">Select 1–2 max. Never auto-assigned.</p>
              <div className="badges-grid">
                {allBadges.map((b) => (
                  <button
                    key={b.id}
                    type="button"
                    className={`badge-tag ${formData.badges.includes(b.id) ? 'selected' : ''}`}
                    onClick={() => toggleBadge(b.id)}
                    disabled={!formData.badges.includes(b.id) && formData.badges.length >= 2}
                  >
                    <span>{b.emoji}</span> {b.label}
                  </button>
                ))}
              </div>
            </div>

            <div className="culture-section">
              <h3 className="culture-section-title">Things People Get Wrong About Me</h3>
              <p className="form-hint">1–3 short lines. Optional.</p>
              {[0, 1, 2].map((i) => (
                <div key={i} className="form-group">
                  <input
                    type="text"
                    placeholder={`Line ${i + 1}...`}
                    value={formData.debunkedLines[i] || ''}
                    onChange={(e) => {
                      const arr = [...(formData.debunkedLines || [])];
                      arr[i] = e.target.value;
                      update('debunkedLines', arr.slice(0, 3));
                    }}
                  />
                </div>
              ))}
            </div>

            <div className="culture-section">
              <h3 className="culture-section-title">Not Here For</h3>
              <p className="form-hint">Optional. Sets expectations and protects your boundaries.</p>
              <div className="form-group">
                <label>I'm not here to explain ___</label>
                <input
                  type="text"
                  placeholder="e.g. my hair, my culture..."
                  value={formData.notHereFor.explain}
                  onChange={(e) => update('notHereFor', { ...formData.notHereFor, explain: e.target.value })}
                />
              </div>
              <div className="form-group">
                <label>Please don't message me if ___</label>
                <input
                  type="text"
                  placeholder="e.g. you're just curious..."
                  value={formData.notHereFor.dontMessage}
                  onChange={(e) => update('notHereFor', { ...formData.notHereFor, dontMessage: e.target.value })}
                />
              </div>
              <div className="form-group">
                <label>A red flag for me is ___</label>
                <input
                  type="text"
                  placeholder="e.g. fetishizing, disrespect..."
                  value={formData.notHereFor.redFlag}
                  onChange={(e) => update('notHereFor', { ...formData.notHereFor, redFlag: e.target.value })}
                />
              </div>
            </div>
          </>
        )}

        {currentStep === 'preferences' && (
          <>
            <h1>Who are you looking for?</h1>
            <p className="step-desc">We'll use this to show you better matches.</p>
            <div className="form-group">
              <label>Show me people who are</label>
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  checked={formData.preferredEthnicities.includes('Black')}
                  onChange={(e) => update('preferredEthnicities', e.target.checked ? ['Black'] : [])}
                />
                <span>Black</span>
              </label>
              <label className="checkbox-label">
                <input
                  type="checkbox"
                  checked={formData.preferredHairColors.includes('Red/Ginger')}
                  onChange={(e) => update('preferredHairColors', e.target.checked ? ['Red/Ginger'] : [])}
                />
                <span>Ginger / Red hair</span>
              </label>
              <p className="form-hint">Select one or both. Leave empty to see everyone.</p>
            </div>
            <div className="form-group">
              <label>Or choose more options</label>
              <div className="preference-tags">
                {ETHNICITY_OPTIONS.filter((e) => e !== 'Prefer not to say').map((opt) => (
                  <button
                    key={opt}
                    type="button"
                    className={`interest-tag small ${formData.preferredEthnicities.includes(opt) ? 'selected' : ''}`}
                    onClick={() => {
                      const next = formData.preferredEthnicities.includes(opt)
                        ? formData.preferredEthnicities.filter((x) => x !== opt)
                        : [...formData.preferredEthnicities, opt];
                      update('preferredEthnicities', next);
                    }}
                  >
                    {opt}
                  </button>
                ))}
                {HAIR_COLOR_OPTIONS.filter((h) => !['Prefer not to say', 'Black'].includes(h)).map((opt) => (
                  <button
                    key={opt}
                    type="button"
                    className={`interest-tag small ${formData.preferredHairColors.includes(opt) ? 'selected' : ''}`}
                    onClick={() => {
                      const next = formData.preferredHairColors.includes(opt)
                        ? formData.preferredHairColors.filter((x) => x !== opt)
                        : [...formData.preferredHairColors, opt];
                      update('preferredHairColors', next);
                    }}
                  >
                    {opt}
                  </button>
                ))}
              </div>
            </div>
            <div className="form-group">
              <label>Interested in</label>
              <select
                value={formData.interestedIn}
                onChange={(e) => update('interestedIn', e.target.value)}
              >
                <option value="Everyone">Everyone</option>
                <option value="Men">Men</option>
                <option value="Women">Women</option>
                <option value="Non-binary">Non-binary</option>
              </select>
            </div>
            <div className="form-group">
              <label>Age range: {formData.ageMin} - {formData.ageMax}</label>
              <div className="range-inputs">
                <div>
                  <span className="range-label">Min: {formData.ageMin}</span>
                  <input
                    type="range"
                    min="18"
                    max="50"
                    value={formData.ageMin}
                    onChange={(e) => {
                      const v = parseInt(e.target.value);
                      update('ageMin', v);
                      if (v > formData.ageMax) update('ageMax', v);
                    }}
                  />
                </div>
                <div>
                  <span className="range-label">Max: {formData.ageMax}</span>
                  <input
                    type="range"
                    min="18"
                    max="60"
                    value={formData.ageMax}
                    onChange={(e) => {
                      const v = parseInt(e.target.value);
                      update('ageMax', v);
                      if (v < formData.ageMin) update('ageMin', v);
                    }}
                  />
                </div>
              </div>
            </div>
            <div className="form-group">
              <label>Maximum distance: {formData.maxDistance} miles</label>
              <input
                type="range"
                min="1"
                max="100"
                value={formData.maxDistance}
                onChange={(e) => update('maxDistance', parseInt(e.target.value))}
              />
            </div>
          </>
        )}
      </div>

      <div className="onboarding-actions single">
        <button
          type="button"
          className="btn-primary full"
          onClick={(e) => { e.preventDefault(); handleNext(); }}
          disabled={!canProceed() || saving}
        >
          {saving ? 'Saving...' : isLast ? 'Continue' : 'Next'}
        </button>
      </div>
    </div>
  );
}
