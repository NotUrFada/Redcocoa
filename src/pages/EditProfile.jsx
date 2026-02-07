import { useState, useRef, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useUserPreferences } from '../context/UserPreferencesContext';
import { useAuth } from '../context/AuthContext';
import { uploadProfilePhoto, setProfilePhotos, updatePreferences } from '../lib/api';
import { hasSupabase } from '../lib/supabase';
import { ALL_INTERESTS } from '../data/mockData';
import { ETHNICITY_OPTIONS, HAIR_COLOR_OPTIONS, GINGER_PROMPTS, BLACK_PROMPTS, GINGER_BADGES, BLACK_BADGES, HUMOR_FILTER_OPTIONS, TONE_FILTER_OPTIONS, VALUES_FILTER_OPTIONS } from '../data/profileOptions';
import Header from '../components/Header';
import '../styles/EditProfile.css';

export default function EditProfile() {
  const navigate = useNavigate();
  const fileInputRef = useRef(null);
  const filesToUploadRef = useRef([]);
  const { user, profile, updateProfile } = useAuth();
  const {
    photos,
    bio,
    interestedIn,
    ageMin,
    ageMax,
    maxDistance,
    interests,
    preferredEthnicities,
    preferredHairColors,
    filterEnjoysHumor,
    filterLikesBanter,
    filterCultureAware,
    filterTone,
    filterDatingIntentionally,
    filterEmotionallyAvailable,
    filterHereForReal,
    notificationsNewMatches,
    notificationsMessages,
    update,
    requestLocation,
  } = useUserPreferences();

  const [showFilterModal, setShowFilterModal] = useState(null);
  const [showCultureModal, setShowCultureModal] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState(false);
  const [saveToast, setSaveToast] = useState(false);
  const isProduction = hasSupabase && user?.id !== 'demo';
  const [localPhotos, setLocalPhotos] = useState(photos || profile?.photo_urls || []);
  const [localBio, setLocalBio] = useState(bio || profile?.bio || '');

  useEffect(() => {
    if (profile?.photo_urls?.length) setLocalPhotos(profile.photo_urls);
    if (profile?.bio) setLocalBio(profile.bio);
    if (profile?.interests?.length) setLocalInterests(profile.interests);
    if (profile?.ethnicity != null) setLocalEthnicity(profile.ethnicity);
    if (profile?.hair_color != null) setLocalHairColor(profile.hair_color);
    if (preferredEthnicities?.length) setLocalPreferredEthnicities(preferredEthnicities);
    if (preferredHairColors?.length) setLocalPreferredHairColors(preferredHairColors);
    if (profile?.prompt_responses) setLocalPromptResponses(profile.prompt_responses);
    if (profile?.badges?.length) setLocalBadges(profile.badges);
    if (profile?.debunked_lines?.length) setLocalDebunkedLines(profile.debunked_lines);
    if (profile?.not_here_for) setLocalNotHereFor({ ...{ explain: '', dont_message: '', red_flag: '' }, ...profile.not_here_for });
    if (filterEnjoysHumor != null) setLocalFilterEnjoysHumor(filterEnjoysHumor);
    if (filterLikesBanter != null) setLocalFilterLikesBanter(filterLikesBanter);
    if (filterCultureAware != null) setLocalFilterCultureAware(filterCultureAware);
    if (filterTone?.length) setLocalFilterTone(filterTone);
    if (filterDatingIntentionally != null) setLocalFilterDatingIntentionally(filterDatingIntentionally);
    if (filterEmotionallyAvailable != null) setLocalFilterEmotionallyAvailable(filterEmotionallyAvailable);
    if (filterHereForReal != null) setLocalFilterHereForReal(filterHereForReal);
  }, [profile?.photo_urls, profile?.bio, profile?.interests, profile?.ethnicity, profile?.hair_color, profile?.prompt_responses, profile?.badges, profile?.debunked_lines, profile?.not_here_for, preferredEthnicities, preferredHairColors, filterEnjoysHumor, filterLikesBanter, filterCultureAware, filterTone, filterDatingIntentionally, filterEmotionallyAvailable, filterHereForReal]);
  const [localInterestedIn, setLocalInterestedIn] = useState(interestedIn || 'Everyone');
  const [localAgeMin, setLocalAgeMin] = useState(ageMin ?? 22);
  const [localAgeMax, setLocalAgeMax] = useState(ageMax ?? 35);
  const [localMaxDistance, setLocalMaxDistance] = useState(maxDistance ?? 25);
  const [localInterests, setLocalInterests] = useState(interests || profile?.interests || []);
  const [localPreferredEthnicities, setLocalPreferredEthnicities] = useState(preferredEthnicities || []);
  const [localPreferredHairColors, setLocalPreferredHairColors] = useState(preferredHairColors || []);
  const [localEthnicity, setLocalEthnicity] = useState(profile?.ethnicity || '');
  const [localHairColor, setLocalHairColor] = useState(profile?.hair_color || '');
  const [localNotifMatches, setLocalNotifMatches] = useState(notificationsNewMatches ?? true);
  const [localNotifMessages, setLocalNotifMessages] = useState(notificationsMessages ?? true);
  const [localPromptResponses, setLocalPromptResponses] = useState(profile?.prompt_responses || {});
  const [localBadges, setLocalBadges] = useState(profile?.badges || []);
  const [localDebunkedLines, setLocalDebunkedLines] = useState(profile?.debunked_lines || []);
  const [localNotHereFor, setLocalNotHereFor] = useState(profile?.not_here_for || { explain: '', dont_message: '', red_flag: '' });
  const [localFilterEnjoysHumor, setLocalFilterEnjoysHumor] = useState(filterEnjoysHumor ?? false);
  const [localFilterLikesBanter, setLocalFilterLikesBanter] = useState(filterLikesBanter ?? false);
  const [localFilterCultureAware, setLocalFilterCultureAware] = useState(filterCultureAware ?? false);
  const [localFilterTone, setLocalFilterTone] = useState(filterTone || []);
  const [localFilterDatingIntentionally, setLocalFilterDatingIntentionally] = useState(filterDatingIntentionally ?? false);
  const [localFilterEmotionallyAvailable, setLocalFilterEmotionallyAvailable] = useState(filterEmotionallyAvailable ?? false);
  const [localFilterHereForReal, setLocalFilterHereForReal] = useState(filterHereForReal ?? false);

  const allBadges = [...GINGER_BADGES, ...BLACK_BADGES];
  const toggleBadge = (id) => {
    const has = localBadges.includes(id);
    if (has) setLocalBadges(localBadges.filter((b) => b !== id));
    else if (localBadges.length < 2) setLocalBadges([...localBadges, id]);
  };

  const toggleInterest = (interest) => {
    setLocalInterests((prev) =>
      prev.includes(interest) ? prev.filter((i) => i !== interest) : [...prev, interest]
    );
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
          setLocalPhotos((p) => [...p, ...toAdd].slice(0, 6));
        }
      };
      reader.readAsDataURL(file);
    });
  };

  const removePhoto = (index) => {
    filesToUploadRef.current = filesToUploadRef.current.filter((_, i) => i !== index);
    setLocalPhotos((p) => p.filter((_, i) => i !== index));
  };

  const saveAll = async () => {
    update({
      photos: localPhotos,
      bio: localBio,
      interestedIn: localInterestedIn,
      ageMin: localAgeMin,
      ageMax: localAgeMax,
      maxDistance: localMaxDistance,
      interests: localInterests,
      preferredEthnicities: localPreferredEthnicities,
      preferredHairColors: localPreferredHairColors,
      filterEnjoysHumor: localFilterEnjoysHumor,
      filterLikesBanter: localFilterLikesBanter,
      filterCultureAware: localFilterCultureAware,
      filterTone: localFilterTone,
      filterDatingIntentionally: localFilterDatingIntentionally,
      filterEmotionallyAvailable: localFilterEmotionallyAvailable,
      filterHereForReal: localFilterHereForReal,
      notificationsNewMatches: localNotifMatches,
      notificationsMessages: localNotifMessages,
    });

    if (isProduction) {
      let photoUrls = localPhotos.filter((p) => typeof p === 'string' && p.startsWith('http'));
      if (filesToUploadRef.current.length > 0) {
        const urls = [];
        for (const file of filesToUploadRef.current) {
          const url = await uploadProfilePhoto(user.id, file);
          if (url) urls.push(url);
        }
        photoUrls = [...photoUrls, ...urls].slice(0, 6);
      }
      if (photoUrls.length) {
        await setProfilePhotos(user.id, photoUrls);
        await updateProfile({ photo_urls: photoUrls });
      }
      await updateProfile({
        bio: localBio,
        interests: localInterests,
        ethnicity: localEthnicity || null,
        hair_color: localHairColor || null,
        prompt_responses: Object.keys(localPromptResponses).length ? localPromptResponses : null,
        badges: localBadges.length ? localBadges : null,
        debunked_lines: localDebunkedLines.filter(Boolean).length ? localDebunkedLines.filter(Boolean) : null,
        not_here_for: (localNotHereFor.explain || localNotHereFor.dont_message || localNotHereFor.red_flag)
          ? localNotHereFor : null,
      });
      await updatePreferences(user.id, {
        age_min: localAgeMin,
        age_max: localAgeMax,
        max_distance_miles: localMaxDistance,
        interested_in: [localInterestedIn],
        preferredEthnicities: localPreferredEthnicities,
        preferredHairColors: localPreferredHairColors,
        filterEnjoysHumor: localFilterEnjoysHumor,
        filterLikesBanter: localFilterLikesBanter,
        filterCultureAware: localFilterCultureAware,
        filterTone: localFilterTone,
        filterDatingIntentionally: localFilterDatingIntentionally,
        filterEmotionallyAvailable: localFilterEmotionallyAvailable,
        filterHereForReal: localFilterHereForReal,
      });
    }

    setShowFilterModal(null);
    setSaveToast(true);
    setTimeout(() => setSaveToast(false), 2000);
    if (isProduction) navigate(-1);
  };

  const displayPhotos = localPhotos.length ? localPhotos : [
    'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=300&h=400&fit=crop',
    'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=300&h=400&fit=crop',
  ];

  return (
    <div className="edit-profile-page">
      <header className="edit-header">
        <button className="icon-btn-text" onClick={() => navigate(-1)}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
            <path d="M19 12H5M12 19l-7-7 7-7" />
          </svg>
        </button>
        <div className="header-title">Edit Profile</div>
        <button className="icon-btn-text" onClick={saveAll}>
          Save
        </button>
      </header>

      <div className="content">
        <div className="section-header">
          <div className="section-title">Profile Photos</div>
          <span className="add-more" onClick={() => fileInputRef.current?.click()}>Add More</span>
        </div>

        <input
          ref={fileInputRef}
          type="file"
          accept="image/*"
          multiple
          style={{ display: 'none' }}
          onChange={handlePhotoSelect}
        />

        <div className="photo-grid">
          {[0, 1, 2].map((i) => (
            <div key={i} className={`photo-slot ${!displayPhotos[i] ? 'empty' : ''}`} onClick={() => !displayPhotos[i] && fileInputRef.current?.click()}>
              {displayPhotos[i] ? (
                <div className="photo-wrapper">
                  <img src={displayPhotos[i]} alt="" />
                  <button type="button" className="photo-remove-btn" onClick={(e) => { e.stopPropagation(); removePhoto(i); }}>×</button>
                </div>
              ) : (
                <>
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="#ccc" strokeWidth="2">
                    <rect x="3" y="3" width="18" height="18" rx="2" />
                    <circle cx="8.5" cy="8.5" r="1.5" />
                    <path d="M21 15l-5-5L5 21" />
                  </svg>
                  <div className="add-btn">+</div>
                </>
              )}
            </div>
          ))}
        </div>

        <div className="input-group">
          <label className="label">Ethnicity</label>
          <select
            className="select-input"
            value={localEthnicity}
            onChange={(e) => setLocalEthnicity(e.target.value)}
          >
            <option value="">Select...</option>
            {ETHNICITY_OPTIONS.map((opt) => (
              <option key={opt} value={opt}>{opt}</option>
            ))}
          </select>
        </div>
        <div className="input-group">
          <label className="label">Hair color</label>
          <select
            className="select-input"
            value={localHairColor}
            onChange={(e) => setLocalHairColor(e.target.value)}
          >
            <option value="">Select...</option>
            {HAIR_COLOR_OPTIONS.map((opt) => (
              <option key={opt} value={opt}>{opt}</option>
            ))}
          </select>
        </div>
        <div className="section-title" style={{ marginBottom: 'var(--spacing-md)' }}>Culture & Expression</div>
        <div className="settings-card">
          <div className="settings-row" onClick={() => setShowCultureModal(true)}>
            <div className="settings-info">
              <span className="settings-label">Prompts, badges, boundaries</span>
              <span className="settings-sub">
                {localBadges.length ? `${localBadges.length} badge(s)` : ''}
                {Object.keys(localPromptResponses).filter((k) => localPromptResponses[k]).length ? `${localBadges.length ? ', ' : ''}${Object.keys(localPromptResponses).filter((k) => localPromptResponses[k]).length} prompt(s)` : ''}
                {Object.keys(localPromptResponses).filter((k) => localPromptResponses[k]).length === 0 && !localBadges.length ? 'Edit' : ''}
              </span>
            </div>
            <svg className="chevron" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </div>
        </div>

        <div className="input-group">
          <label className="label">About Me</label>
          <textarea
            className="textarea-input"
            placeholder="Tell everyone a bit about yourself..."
            value={localBio}
            onChange={(e) => setLocalBio(e.target.value)}
            rows={5}
          />
        </div>

        <div className="section-title" style={{ marginBottom: 'var(--spacing-md)' }}>Discovery Filters</div>
        <div className="settings-card">
          <div className="settings-row" onClick={() => setShowFilterModal('showMe')}>
            <div className="settings-info">
              <span className="settings-label">Show me</span>
              <span className="settings-sub">
                {localPreferredEthnicities.length || localPreferredHairColors.length
                  ? [...localPreferredEthnicities, ...localPreferredHairColors].join(', ') || 'Everyone'
                  : 'Everyone'}
              </span>
            </div>
            <svg className="chevron" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </div>
          <div className="settings-row" onClick={() => setShowFilterModal('interestedIn')}>
            <div className="settings-info">
              <span className="settings-label">Interested in</span>
              <span className="settings-sub">{localInterestedIn}</span>
            </div>
            <svg className="chevron" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </div>
          <div className="settings-row" onClick={() => setShowFilterModal('age')}>
            <div className="settings-info">
              <span className="settings-label">Age Range</span>
              <span className="settings-sub">{localAgeMin} - {localAgeMax}</span>
            </div>
            <svg className="chevron" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </div>
          <div className="settings-row" onClick={() => setShowFilterModal('distance')}>
            <div className="settings-info">
              <span className="settings-label">Maximum Distance</span>
              <span className="settings-sub">{localMaxDistance} miles</span>
            </div>
            <svg className="chevron" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </div>
          <div className="settings-row" onClick={() => setShowFilterModal('interests')}>
            <div className="settings-info">
              <span className="settings-label">Interests</span>
              <span className="settings-sub">{localInterests.length ? localInterests.join(', ') : 'None'}</span>
            </div>
            <svg className="chevron" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </div>
          <div className="settings-row" onClick={() => setShowFilterModal('humorVibe')}>
            <div className="settings-info">
              <span className="settings-label">Humor & vibe</span>
              <span className="settings-sub">
                {[localFilterEnjoysHumor && 'Humor', localFilterLikesBanter && 'Banter', localFilterCultureAware && 'Culture-aware', ...localFilterTone].filter(Boolean).join(', ') || 'None'}
              </span>
            </div>
            <svg className="chevron" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </div>
          <div className="settings-row" onClick={() => setShowFilterModal('values')}>
            <div className="settings-info">
              <span className="settings-label">Values & intent</span>
              <span className="settings-sub">
                {[localFilterDatingIntentionally && 'Intentional', localFilterEmotionallyAvailable && 'Emotionally available', localFilterHereForReal && 'Here for real'].filter(Boolean).join(', ') || 'None'}
              </span>
            </div>
            <svg className="chevron" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <polyline points="9 18 15 12 9 6" />
            </svg>
          </div>
        </div>

        <div className="section-title" style={{ marginBottom: 'var(--spacing-md)' }}>Location</div>
        <div className="settings-card">
          <div className="settings-row">
            <div className="settings-info">
              <span className="settings-label">Use my location</span>
              <span className="settings-sub">Find matches near you</span>
            </div>
            <button className="btn-secondary-sm" onClick={async () => {
              const result = await requestLocation();
              if (isProduction && result?.granted && result.latitude != null && result.longitude != null) {
                await updateProfile({ latitude: result.latitude, longitude: result.longitude });
              }
            }}>Enable</button>
          </div>
        </div>

        <div className="section-title" style={{ marginBottom: 'var(--spacing-md)' }}>Notifications</div>
        <div className="settings-card">
          <div className="settings-row">
            <div className="settings-info">
              <span className="settings-label">New Matches</span>
            </div>
            <label className="toggle">
              <input
                type="checkbox"
                checked={localNotifMatches}
                onChange={(e) => setLocalNotifMatches(e.target.checked)}
              />
              <span className="slider" />
            </label>
          </div>
          <div className="settings-row">
            <div className="settings-info">
              <span className="settings-label">Messages</span>
            </div>
            <label className="toggle">
              <input
                type="checkbox"
                checked={localNotifMessages}
                onChange={(e) => setLocalNotifMessages(e.target.checked)}
              />
              <span className="slider" />
            </label>
          </div>
        </div>

        <div className="section-title" style={{ marginBottom: 'var(--spacing-md)' }}>Account Settings</div>
        <div className="settings-card">
          <div className="settings-row">
            <div className="settings-info">
              <span className="settings-label">Email</span>
              <span className="settings-sub">{user?.email || 'Not set'}</span>
            </div>
          </div>
          <div className="settings-row settings-row-clickable" onClick={() => setShowDeleteConfirm(true)}>
            <div className="settings-info">
              <span className="settings-label" style={{ color: '#E03131' }}>Delete Account</span>
            </div>
          </div>
        </div>
      </div>

      {showFilterModal && (
        <div className="modal-overlay" onClick={() => setShowFilterModal(null)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>
                {showFilterModal === 'showMe' && 'Show me people who are'}
                {showFilterModal === 'interestedIn' && 'Interested in'}
                {showFilterModal === 'age' && 'Age Range'}
                {showFilterModal === 'distance' && 'Maximum Distance'}
                {showFilterModal === 'interests' && 'Interests'}
                {showFilterModal === 'humorVibe' && 'Humor & vibe filters'}
                {showFilterModal === 'values' && 'Values & intent filters'}
              </h3>
              <button className="modal-close" onClick={() => setShowFilterModal(null)}>×</button>
            </div>
            <div className="modal-body">
              {showFilterModal === 'showMe' && (
                <div className="interests-grid-modal">
                  <p className="modal-hint">Select ethnicity and/or hair color. Leave empty to see everyone.</p>
                  {ETHNICITY_OPTIONS.filter((e) => e !== 'Prefer not to say').map((opt) => (
                    <button
                      key={opt}
                      type="button"
                      className={`interest-tag ${localPreferredEthnicities.includes(opt) ? 'selected' : ''}`}
                      onClick={() => {
                        const next = localPreferredEthnicities.includes(opt)
                          ? localPreferredEthnicities.filter((x) => x !== opt)
                          : [...localPreferredEthnicities, opt];
                        setLocalPreferredEthnicities(next);
                      }}
                    >
                      {opt}
                    </button>
                  ))}
                  {HAIR_COLOR_OPTIONS.filter((h) => h !== 'Prefer not to say').map((opt) => (
                    <button
                      key={opt}
                      type="button"
                      className={`interest-tag ${localPreferredHairColors.includes(opt) ? 'selected' : ''}`}
                      onClick={() => {
                        const next = localPreferredHairColors.includes(opt)
                          ? localPreferredHairColors.filter((x) => x !== opt)
                          : [...localPreferredHairColors, opt];
                        setLocalPreferredHairColors(next);
                      }}
                    >
                      {opt}
                    </button>
                  ))}
                </div>
              )}
              {showFilterModal === 'interestedIn' && (
                <select
                  value={localInterestedIn}
                  onChange={(e) => setLocalInterestedIn(e.target.value)}
                  className="modal-select"
                >
                  <option value="Everyone">Everyone</option>
                  <option value="Men">Men</option>
                  <option value="Women">Women</option>
                  <option value="Non-binary">Non-binary</option>
                </select>
              )}
              {showFilterModal === 'age' && (
                <div className="modal-range">
                  <div>
                    <label>Min: {localAgeMin}</label>
                    <input
                      type="range"
                      min="18"
                      max="50"
                      value={localAgeMin}
                      onChange={(e) => {
                        const v = parseInt(e.target.value);
                        setLocalAgeMin(v);
                        if (v > localAgeMax) setLocalAgeMax(v);
                      }}
                    />
                  </div>
                  <div>
                    <label>Max: {localAgeMax}</label>
                    <input
                      type="range"
                      min="18"
                      max="60"
                      value={localAgeMax}
                      onChange={(e) => {
                        const v = parseInt(e.target.value);
                        setLocalAgeMax(v);
                        if (v < localAgeMin) setLocalAgeMin(v);
                      }}
                    />
                  </div>
                </div>
              )}
              {showFilterModal === 'distance' && (
                <div className="modal-range">
                  <label>Max: {localMaxDistance} miles</label>
                  <input
                    type="range"
                    min="1"
                    max="100"
                    value={localMaxDistance}
                    onChange={(e) => setLocalMaxDistance(parseInt(e.target.value) || 25)}
                  />
                </div>
              )}
              {showFilterModal === 'humorVibe' && (
                <div className="filter-modal-body">
                  <p className="modal-hint">Filter by humor and communication style. Prevents vibe mismatch.</p>
                  {HUMOR_FILTER_OPTIONS.map((opt) => (
                    <label key={opt.id} className="filter-checkbox">
                      <input
                        type="checkbox"
                        checked={
                          (opt.id === 'enjoys_humor' && localFilterEnjoysHumor) ||
                          (opt.id === 'likes_banter' && localFilterLikesBanter) ||
                          (opt.id === 'culture_aware' && localFilterCultureAware)
                        }
                        onChange={(e) => {
                          if (opt.id === 'enjoys_humor') setLocalFilterEnjoysHumor(e.target.checked);
                          if (opt.id === 'likes_banter') setLocalFilterLikesBanter(e.target.checked);
                          if (opt.id === 'culture_aware') setLocalFilterCultureAware(e.target.checked);
                        }}
                      />
                      <span>{opt.label}</span>
                    </label>
                  ))}
                  <p className="modal-hint" style={{ marginTop: 16 }}>Tone</p>
                  <div className="filter-tone-tags">
                    {TONE_FILTER_OPTIONS.map((opt) => (
                      <button
                        key={opt.id}
                        type="button"
                        className={`interest-tag ${localFilterTone.includes(opt.id) ? 'selected' : ''}`}
                        onClick={() => {
                          const next = localFilterTone.includes(opt.id)
                            ? localFilterTone.filter((x) => x !== opt.id)
                            : [...localFilterTone, opt.id];
                          setLocalFilterTone(next);
                        }}
                      >
                        {opt.label}
                      </button>
                    ))}
                  </div>
                </div>
              )}
              {showFilterModal === 'values' && (
                <div className="filter-modal-body">
                  <p className="modal-hint">Filter by dating values. Quietly protects from time-wasters.</p>
                  {VALUES_FILTER_OPTIONS.map((opt) => (
                    <label key={opt.id} className="filter-checkbox">
                      <input
                        type="checkbox"
                        checked={
                          (opt.id === 'dating_intentionally' && localFilterDatingIntentionally) ||
                          (opt.id === 'emotionally_available' && localFilterEmotionallyAvailable) ||
                          (opt.id === 'culture_aware' && localFilterCultureAware) ||
                          (opt.id === 'here_for_real' && localFilterHereForReal)
                        }
                        onChange={(e) => {
                          if (opt.id === 'dating_intentionally') setLocalFilterDatingIntentionally(e.target.checked);
                          if (opt.id === 'emotionally_available') setLocalFilterEmotionallyAvailable(e.target.checked);
                          if (opt.id === 'culture_aware') setLocalFilterCultureAware(e.target.checked);
                          if (opt.id === 'here_for_real') setLocalFilterHereForReal(e.target.checked);
                        }}
                      />
                      <span>{opt.label}</span>
                    </label>
                  ))}
                </div>
              )}
              {showFilterModal === 'interests' && (
                <div className="interests-grid-modal">
                  {ALL_INTERESTS.map((interest) => (
                    <button
                      key={interest}
                      type="button"
                      className={`interest-tag ${localInterests.includes(interest) ? 'selected' : ''}`}
                      onClick={() => toggleInterest(interest)}
                    >
                      {interest}
                    </button>
                  ))}
                </div>
              )}
            </div>
            <div className="modal-footer">
              <button className="btn-primary full" onClick={saveAll}>Apply</button>
            </div>
          </div>
        </div>
      )}

      {showCultureModal && (
        <div className="modal-overlay" onClick={() => setShowCultureModal(false)}>
          <div className="modal-content modal-culture" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Culture & Expression</h3>
              <button className="modal-close" onClick={() => setShowCultureModal(false)}>×</button>
            </div>
            <div className="modal-body">
              <div className="culture-modal-section">
                <h4>🔥 Ginger Prompts</h4>
                {GINGER_PROMPTS.map((p) => (
                  <div key={p.id} className="input-group">
                    <label>{p.text}</label>
                    <input
                      type="text"
                      placeholder="Your answer..."
                      value={localPromptResponses[p.id] || ''}
                      onChange={(e) => setLocalPromptResponses({ ...localPromptResponses, [p.id]: e.target.value })}
                    />
                  </div>
                ))}
              </div>
              <div className="culture-modal-section">
                <h4>🤎 Black Prompts</h4>
                {BLACK_PROMPTS.map((p) => (
                  <div key={p.id} className="input-group">
                    <label>{p.text}</label>
                    <input
                      type="text"
                      placeholder="Your answer..."
                      value={localPromptResponses[p.id] || ''}
                      onChange={(e) => setLocalPromptResponses({ ...localPromptResponses, [p.id]: e.target.value })}
                    />
                  </div>
                ))}
              </div>
              <div className="culture-modal-section">
                <h4>Badges (1–2 max)</h4>
                <div className="badges-grid">
                  {allBadges.map((b) => (
                    <button
                      key={b.id}
                      type="button"
                      className={`badge-tag ${localBadges.includes(b.id) ? 'selected' : ''}`}
                      onClick={() => toggleBadge(b.id)}
                      disabled={!localBadges.includes(b.id) && localBadges.length >= 2}
                    >
                      {b.emoji} {b.label}
                    </button>
                  ))}
                </div>
              </div>
              <div className="culture-modal-section">
                <h4>Things People Get Wrong About Me</h4>
                {[0, 1, 2].map((i) => (
                  <div key={i} className="input-group">
                    <input
                      type="text"
                      placeholder={`Line ${i + 1}...`}
                      value={localDebunkedLines[i] || ''}
                      onChange={(e) => {
                        const arr = [...localDebunkedLines];
                        arr[i] = e.target.value;
                        setLocalDebunkedLines(arr.slice(0, 3));
                      }}
                    />
                  </div>
                ))}
              </div>
              <div className="culture-modal-section">
                <h4>Not Here For</h4>
                <div className="input-group">
                  <label>I&apos;m not here to explain ___</label>
                  <input
                    type="text"
                    placeholder="e.g. my hair, my culture..."
                    value={localNotHereFor.explain || ''}
                    onChange={(e) => setLocalNotHereFor({ ...localNotHereFor, explain: e.target.value })}
                  />
                </div>
                <div className="input-group">
                  <label>Please don&apos;t message me if ___</label>
                  <input
                    type="text"
                    placeholder="e.g. you're just curious..."
                    value={localNotHereFor.dont_message || ''}
                    onChange={(e) => setLocalNotHereFor({ ...localNotHereFor, dont_message: e.target.value })}
                  />
                </div>
                <div className="input-group">
                  <label>A red flag for me is ___</label>
                  <input
                    type="text"
                    placeholder="e.g. fetishizing, disrespect..."
                    value={localNotHereFor.red_flag || ''}
                    onChange={(e) => setLocalNotHereFor({ ...localNotHereFor, red_flag: e.target.value })}
                  />
                </div>
              </div>
            </div>
            <div className="modal-footer">
              <button className="btn-primary full" onClick={() => { saveAll(); setShowCultureModal(false); }}>Apply</button>
            </div>
          </div>
        </div>
      )}

      {showDeleteConfirm && (
        <div className="modal-overlay" onClick={() => setShowDeleteConfirm(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <div className="modal-header">
              <h3>Delete Account</h3>
              <button className="modal-close" onClick={() => setShowDeleteConfirm(false)}>×</button>
            </div>
            <div className="modal-body">
              <p>Are you sure? This will permanently delete your account and all data. This action cannot be undone.</p>
              <p>To delete your account, please email <strong>support@redcocoa.app</strong> from your registered email.</p>
            </div>
            <div className="modal-footer">
              <button className="btn-primary full" onClick={() => setShowDeleteConfirm(false)}>Close</button>
            </div>
          </div>
        </div>
      )}

      {saveToast && (
        <div className="save-toast">Saved!</div>
      )}
    </div>
  );
}
