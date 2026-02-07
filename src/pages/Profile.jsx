import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { profiles as mockProfiles } from '../data/mockData';
import { useAuth } from '../context/AuthContext';
import { GINGER_PROMPTS, BLACK_PROMPTS, GINGER_BADGES, BLACK_BADGES } from '../data/profileOptions';
import { getProfileById, blockUser, reportUser, likeProfile, passOnProfile } from '../lib/api';
import { hasSupabase } from '../lib/supabase';
import FullScreenLayout from '../components/FullScreenLayout';
import '../styles/Profile.css';

export default function Profile() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [showReportMenu, setShowReportMenu] = useState(false);
  const [reportSent, setReportSent] = useState(false);

  const isProduction = hasSupabase && user?.id !== 'demo';

  useEffect(() => {
    if (!id) return;
    if (isProduction) {
      getProfileById(id, user?.id).then((p) => {
        setProfile(p);
        setLoading(false);
      });
    } else {
      const mock = mockProfiles.find((p) => p.id === id) || mockProfiles[0];
      setProfile(mock);
      setLoading(false);
    }
  }, [id, isProduction, user?.id]);

  const handleReport = async (reason) => {
    if (isProduction && user?.id && profile?.id) {
      await reportUser(user.id, profile.id, reason);
    }
    setReportSent(true);
    setShowReportMenu(false);
  };

  const handleBlock = async () => {
    if (isProduction && user?.id && profile?.id) {
      await blockUser(user.id, profile.id);
    }
    setShowReportMenu(false);
    navigate(-1);
  };

  const handlePass = async () => {
    try {
      if (isProduction && user?.id) await passOnProfile(user.id, profile.id);
    } catch (e) {
      console.warn('Pass failed:', e);
    }
    navigate(-1);
  };

  const handleLike = async () => {
    try {
      if (isProduction && user?.id) {
        const result = await likeProfile(user.id, profile.id);
        if (result?.isMatch) navigate(`/chat/${profile.id}`);
        else navigate(-1);
      } else {
        navigate(-1);
      }
    } catch (e) {
      console.warn('Like failed:', e);
      navigate(-1);
    }
  };

  if (loading || !profile) {
    return (
      <FullScreenLayout>
        <div className="profile-page">
          <div className="profile-content profile-loading">
            <p>Loading...</p>
          </div>
        </div>
      </FullScreenLayout>
    );
  }

  return (
    <FullScreenLayout>
    <div className="profile-page">
      <div className="gallery-container">
        <div className="gallery-indicators">
          <div className="indicator active" />
          <div className="indicator" />
          <div className="indicator" />
        </div>
        <div className="profile-top-actions">
          <button className="back-btn" onClick={() => navigate(-1)} aria-label="Back">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
              <path d="M15 18l-6-6 6-6" />
            </svg>
          </button>
          <button className="menu-btn" onClick={() => setShowReportMenu(!showReportMenu)}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="12" cy="12" r="1" />
              <circle cx="12" cy="5" r="1" />
              <circle cx="12" cy="19" r="1" />
            </svg>
          </button>
        </div>
        {showReportMenu && (
          <div className="report-menu">
            <button onClick={() => handleReport('spam')}>Report spam</button>
            <button onClick={() => handleReport('inappropriate')}>Report inappropriate</button>
            <button onClick={() => handleReport('other')}>Report other</button>
            <button className="report-block" onClick={handleBlock}>Block {profile.name}</button>
          </div>
        )}
        {reportSent && <div className="report-toast">Report submitted. Thank you.</div>}
        <img
          src={profile.image}
          className="gallery-image"
          alt={profile.name}
          onError={(e) => {
            e.target.onerror = null;
            e.target.src = 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600&h=800&fit=crop';
          }}
        />
      </div>

      <div className="profile-content">
        <div className="profile-header">
          <h1 className="name-age">{profile.name}, {profile.age}</h1>
          <div className="location">
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
              <circle cx="12" cy="10" r="3" />
            </svg>
            <span className="location-text">{profile.location} • {profile.distance}</span>
          </div>
        </div>

        <div className="section">
          <h2 className="section-label">About Me</h2>
          <p className="bio-text">{profile.bio}</p>
        </div>

        {(profile.height || profile.ethnicity || profile.hair_color) && (
          <div className="section">
            <h2 className="section-label">Essentials</h2>
            <div className="stats-grid">
              {profile.ethnicity && (
                <div className="stat-item">
                  <div className="stat-info"><span>Ethnicity</span><strong>{profile.ethnicity}</strong></div>
                </div>
              )}
              {profile.hair_color && (
                <div className="stat-item">
                  <div className="stat-info"><span>Hair</span><strong>{profile.hair_color}</strong></div>
                </div>
              )}
              {profile.height && (
                <div className="stat-item">
                  <div className="stat-icon">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" />
                      <circle cx="12" cy="7" r="4" />
                    </svg>
                  </div>
                  <div className="stat-info"><span>Height</span><strong>{profile.height}</strong></div>
                </div>
              )}
              {profile.sign && (
                <div className="stat-item">
                  <div className="stat-icon">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <circle cx="12" cy="12" r="10" />
                      <polyline points="12 6 12 12 16 14" />
                    </svg>
                  </div>
                  <div className="stat-info"><span>Sign</span><strong>{profile.sign}</strong></div>
                </div>
              )}
              {profile.intent && (
                <div className="stat-item">
                  <div className="stat-icon">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M12 2l3.09 6.26L22 9.27l-5 4.87 1.18 6.88L12 17.77l-6.18 3.25L7 14.14 2 9.27l6.91-1.01L12 2z" />
                    </svg>
                  </div>
                  <div className="stat-info"><span>Intent</span><strong>{profile.intent}</strong></div>
                </div>
              )}
              {profile.education && (
                <div className="stat-item">
                  <div className="stat-icon">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" />
                      <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" />
                    </svg>
                  </div>
                  <div className="stat-info"><span>Education</span><strong>{profile.education}</strong></div>
                </div>
              )}
            </div>
          </div>
        )}

        {(profile.prompt_responses && Object.keys(profile.prompt_responses).length > 0) && (
          <div className="section">
            <h2 className="section-label">Prompts</h2>
            <div className="prompt-responses">
              {[...GINGER_PROMPTS, ...BLACK_PROMPTS].map((p) =>
                profile.prompt_responses[p.id] ? (
                  <div key={p.id} className="prompt-item">
                    <p className="prompt-text">{p.text.replace('___', profile.prompt_responses[p.id])}</p>
                  </div>
                ) : null
              )}
            </div>
          </div>
        )}

        {(profile.badges?.length > 0) && (
          <div className="section">
            <h2 className="section-label">Badges</h2>
            <div className="badges-display">
              {profile.badges.map((id) => {
                const b = [...GINGER_BADGES, ...BLACK_BADGES].find((x) => x.id === id);
                return b ? <span key={id} className="badge-pill">{b.emoji} {b.label}</span> : null;
              })}
            </div>
          </div>
        )}

        {(profile.debunked_lines?.length > 0) && (
          <div className="section">
            <h2 className="section-label">Things People Get Wrong About Me</h2>
            <ul className="debunked-list">
              {profile.debunked_lines.map((line, i) => (
                <li key={i}>{line}</li>
              ))}
            </ul>
          </div>
        )}

        {(profile.not_here_for && (profile.not_here_for.explain || profile.not_here_for.dont_message || profile.not_here_for.red_flag)) && (
          <div className="section">
            <h2 className="section-label">Not Here For</h2>
            <div className="not-here-for">
              {profile.not_here_for.explain && <p><strong>I&apos;m not here to explain</strong> {profile.not_here_for.explain}</p>}
              {profile.not_here_for.dont_message && <p><strong>Please don&apos;t message me if</strong> {profile.not_here_for.dont_message}</p>}
              {profile.not_here_for.red_flag && <p><strong>A red flag for me is</strong> {profile.not_here_for.red_flag}</p>}
            </div>
          </div>
        )}

        <div className="section">
          <h2 className="section-label">Interests</h2>
          <div className="tags-container">
            {(profile.interests || []).map((tag, i) => (
              <span key={i} className="tag">{tag}</span>
            ))}
          </div>
        </div>
      </div>

      <div className="profile-actions">
        <button className="btn btn-round" onClick={handlePass} aria-label="Pass">✕</button>
        <button className="btn btn-primary" onClick={() => navigate(`/chat/${profile.id}`)}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
          </svg>
          Send message
        </button>
        <button className="btn btn-round btn-like" onClick={handleLike} aria-label="Like">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="currentColor">
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
          </svg>
        </button>
      </div>
    </div>
    </FullScreenLayout>
  );
}
