import { useState, useMemo, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { profiles as mockProfiles } from '../data/mockData';
import { useAuth } from '../context/AuthContext';
import { useUserPreferences } from '../context/UserPreferencesContext';
import { getDiscoveryProfiles, passOnProfile, likeProfile } from '../lib/api';
import { hasSupabase } from '../lib/supabase';
import SwipeableCard from '../components/SwipeableCard';
import '../styles/Discover.css';

function normalizeInterest(s) {
  return (s || '').replace(/[\u{1F300}-\u{1F9FF}]/gu, '').replace(/[^\w\s]/g, '').trim();
}

function hasInterestOverlap(userInterests, profileInterests) {
  if (!userInterests?.length) return true;
  const userSet = new Set(userInterests.map(normalizeInterest).map((s) => s.toLowerCase()));
  return (profileInterests || []).some((pi) => {
    const n = normalizeInterest(pi).toLowerCase();
    return userSet.has(n) || [...userSet].some((u) => n.includes(u) || u.includes(n));
  });
}

export default function Discover() {
  const [currentIndex, setCurrentIndex] = useState(0);
  const [hasSeenAll, setHasSeenAll] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [apiProfiles, setApiProfiles] = useState(null);
  const [loading, setLoading] = useState(hasSupabase);
  const navigate = useNavigate();
  const { user } = useAuth();
  const {
    ageMin,
    ageMax,
    maxDistance,
    interests,
    preferredEthnicities,
    preferredHairColors,
    passedIds,
    addPassedId,
    filterEnjoysHumor,
    filterLikesBanter,
    filterCultureAware,
    filterTone,
    filterDatingIntentionally,
    filterEmotionallyAvailable,
    filterHereForReal,
  } = useUserPreferences();

  const isProduction = hasSupabase && user?.id !== 'demo';

  useEffect(() => {
    if (!isProduction) {
      setLoading(false);
      return;
    }
    setLoading(true);
    getDiscoveryProfiles(user.id, {
      ageMin, ageMax, maxDistance, interests, preferredEthnicities, preferredHairColors,
      filterEnjoysHumor, filterLikesBanter, filterCultureAware, filterTone,
      filterDatingIntentionally, filterEmotionallyAvailable, filterHereForReal,
    }).then((list) => {
      setApiProfiles(list);
      setLoading(false);
    });
  }, [isProduction, user?.id, ageMin, ageMax, maxDistance, interests, preferredEthnicities, preferredHairColors, filterEnjoysHumor, filterLikesBanter, filterCultureAware, filterTone, filterDatingIntentionally, filterEmotionallyAvailable, filterHereForReal]);

  const baseProfiles = isProduction ? (apiProfiles ?? []) : mockProfiles;

  const filteredProfiles = useMemo(() => {
    let list = baseProfiles.filter((p) => {
      if (!isProduction && passedIds?.includes(p.id)) return false;
      if (p.age < (ageMin ?? 18) || p.age > (ageMax ?? 60)) return false;
      if ((p.distanceMiles ?? 999) > (maxDistance ?? 100)) return false;
      if (!hasInterestOverlap(interests, p.interests)) return false;
      if (preferredEthnicities?.length || preferredHairColors?.length) {
        const matchEthnicity = !preferredEthnicities?.length || (p.ethnicity && preferredEthnicities.includes(p.ethnicity));
        const matchHair = !preferredHairColors?.length || (p.hair_color && preferredHairColors.includes(p.hair_color));
        if (!matchEthnicity && !matchHair) return false;
      }
      if (filterEnjoysHumor && p.humor_preference === 'not_for_me') return false;
      if (filterLikesBanter && p.humor_preference === 'not_for_me') return false;
      if (filterCultureAware && !(p.prompt_responses && Object.keys(p.prompt_responses).length) && !(p.badges && p.badges.length)) return false;
      if (filterTone?.length && (!p.tone_vibe || !filterTone.includes(p.tone_vibe))) return false;
      return true;
    });
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      list = list.filter(
        (p) =>
          (p.name || '').toLowerCase().includes(q) ||
          (p.location || '').toLowerCase().includes(q) ||
          (p.bio || '').toLowerCase().includes(q) ||
          (p.interests || []).some((i) => String(i).toLowerCase().includes(q))
      );
    }
    return list;
  }, [baseProfiles, isProduction, ageMin, ageMax, maxDistance, interests, preferredEthnicities, preferredHairColors, passedIds, searchQuery]);

  const visibleProfiles = filteredProfiles.slice(currentIndex, currentIndex + 3);
  const currentProfile = filteredProfiles[currentIndex];

  const advanceCard = () => {
    if (currentIndex >= filteredProfiles.length - 1) {
      setHasSeenAll(true);
    } else {
      setCurrentIndex((i) => i + 1);
    }
  };

  const handlePass = async () => {
    if (!currentProfile) return;
    try {
      if (isProduction) await passOnProfile(user.id, currentProfile.id);
      else addPassedId(currentProfile.id);
    } catch (e) {
      console.warn('Pass failed:', e);
    }
    advanceCard();
  };

  const handleSwipeLeft = async () => {
    if (!currentProfile) return;
    try {
      if (isProduction) await passOnProfile(user.id, currentProfile.id);
      else addPassedId(currentProfile.id);
    } catch (e) {
      console.warn('Pass failed:', e);
    }
    advanceCard();
  };

  const handleSwipeRight = () => {
    if (currentProfile) navigate(`/profile/${currentProfile.id}`);
  };

  const handleLike = async () => {
    if (!currentProfile) return;
    try {
      if (isProduction) {
        const result = await likeProfile(user.id, currentProfile.id);
        const isMatch = result?.isMatch ?? false;
        if (isMatch) navigate(`/chat/${currentProfile.id}`);
        else navigate(`/profile/${currentProfile.id}`);
      } else {
        navigate(`/profile/${currentProfile.id}`);
      }
    } catch (e) {
      console.warn('Like failed:', e);
      navigate(`/profile/${currentProfile.id}`);
    }
  };

  const handleAdjustFilters = () => {
    navigate('/profile/edit');
  };

  const renderEmpty = (title, desc) => (
    <div className="discover-page discover-empty">
      <div className="discover-header">
        <div className="brand">
          <div className="brand-icon" />
          Red Cocoa
        </div>
        <div className="header-actions">
          <button className="icon-btn" onClick={() => navigate('/chats')}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
              <path d="M13.73 21a2 2 0 0 1-3.46 0" />
            </svg>
          </button>
          <button className="icon-btn icon-btn-accent" onClick={handleAdjustFilters}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <line x1="4" y1="21" x2="4" y2="14" />
              <line x1="4" y1="10" x2="4" y2="3" />
              <line x1="12" y1="21" x2="12" y2="12" />
              <line x1="12" y1="8" x2="12" y2="3" />
              <line x1="20" y1="21" x2="20" y2="16" />
              <line x1="20" y1="12" x2="20" y2="3" />
              <line x1="1" y1="14" x2="7" y2="14" />
              <line x1="9" y1="8" x2="15" y2="8" />
              <line x1="17" y1="16" x2="23" y2="16" />
            </svg>
          </button>
        </div>
      </div>
      <div className="empty-state">
        {hasSeenAll && (
          <div className="empty-illustration">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
              <circle cx="12" cy="12" r="10" />
              <path d="M8 14s1.5 2 4 2 4-2 4-2" />
              <line x1="9" y1="9" x2="9.01" y2="9" />
              <line x1="15" y1="9" x2="15.01" y2="9" />
            </svg>
            <div className="sparkle" style={{ top: '20%', right: '20%' }} />
            <div className="sparkle" style={{ bottom: '15%', left: '25%', width: 6, height: 6, opacity: 0.6 }} />
          </div>
        )}
        <h2 className="empty-title">{title}</h2>
        <p className="empty-desc">{desc}</p>
        <div className="empty-actions">
          <button className="btn btn-primary" onClick={handleAdjustFilters}>
            <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
              <path d="M22 3H2l8 9.46V19l4 2v-8.54L22 3z" />
            </svg>
            Adjust Filters
          </button>
        </div>
      </div>
    </div>
  );

  if (loading) {
    return (
      <div className="discover-page discover-empty">
        <div className="empty-state">
          <p className="empty-desc">Loading profiles...</p>
        </div>
      </div>
    );
  }

  if (filteredProfiles.length === 0 && !hasSeenAll) {
    return renderEmpty('No matches yet', 'Try adjusting your filters to see more people.');
  }

  if (hasSeenAll) {
    return renderEmpty(
      "You've seen them all!",
      "Your perfect match is out there. Try adjusting your filters to see more people."
    );
  }

  if (!currentProfile) return null;

  return (
    <div className="discover-page">
      {!isProduction && (
        <div className="demo-mode-banner">
          Demo mode — add <code>VITE_SUPABASE_URL</code> and <code>VITE_SUPABASE_ANON_KEY</code> to .env to see real profiles
        </div>
      )}
      <div className="discover-header">
        <div className="brand">
          <div className="brand-icon" />
          Red Cocoa
        </div>
        <div className="header-actions">
          <button className="icon-btn" onClick={() => navigate('/chats')}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
              <path d="M13.73 21a2 2 0 0 1-3.46 0" />
            </svg>
          </button>
          <button className="icon-btn icon-btn-accent" onClick={handleAdjustFilters}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <line x1="4" y1="21" x2="4" y2="14" />
              <line x1="4" y1="10" x2="4" y2="3" />
              <line x1="12" y1="21" x2="12" y2="12" />
              <line x1="12" y1="8" x2="12" y2="3" />
              <line x1="20" y1="21" x2="20" y2="16" />
              <line x1="20" y1="12" x2="20" y2="3" />
              <line x1="1" y1="14" x2="7" y2="14" />
              <line x1="9" y1="8" x2="15" y2="8" />
              <line x1="17" y1="16" x2="23" y2="16" />
            </svg>
          </button>
        </div>
      </div>
      <input
        type="text"
        className="search-input"
        placeholder="Search by location or interest..."
        value={searchQuery}
        onChange={(e) => { setSearchQuery(e.target.value); setCurrentIndex(0); }}
      />

      <div className="card-stack">
        {visibleProfiles.map((profile, i) => (
          <SwipeableCard
            key={profile.id + i}
            profile={profile}
            isTop={i === 0}
            onSwipeLeft={handleSwipeLeft}
            onSwipeRight={handleSwipeRight}
            onClick={() => navigate(`/profile/${profile.id}`)}
          />
        ))}
      </div>

      <div className="discover-actions">
        <button className="btn btn-round btn-pass" onClick={handlePass}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
            <line x1="18" y1="6" x2="6" y2="18" />
            <line x1="6" y1="6" x2="18" y2="18" />
          </svg>
        </button>
        <button className="btn btn-primary btn-message" onClick={() => navigate(`/chat/${currentProfile.id}`)}>
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" className="btn-icon">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
          </svg>
          <span className="btn-text">Send message</span>
        </button>
        <button className="btn btn-round btn-like" onClick={handleLike}>
          <svg width="24" height="24" viewBox="0 0 24 24" fill="currentColor">
            <path d="M20.84 4.61a5.5 5.5 0 0 0-7.78 0L12 5.67l-1.06-1.06a5.5 5.5 0 0 0-7.78 7.78l1.06 1.06L12 21.23l7.78-7.78 1.06-1.06a5.5 5.5 0 0 0 0-7.78z" />
          </svg>
        </button>
      </div>
    </div>
  );
}
