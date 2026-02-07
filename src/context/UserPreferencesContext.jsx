import { createContext, useContext, useState, useEffect, useCallback } from 'react';
import { useAuth } from './AuthContext';
import { getPreferences } from '../lib/api';
import { hasSupabase } from '../lib/supabase';

const STORAGE_KEY = 'redcocoa_preferences';

const defaults = {
  // Discovery filters
  ageMin: 22,
  ageMax: 35,
  maxDistance: 25,
  interestedIn: 'Everyone',
  interests: [],
  preferredEthnicities: [],
  preferredHairColors: [],
  // Location
  location: null,
  latitude: null,
  longitude: null,
  locationEnabled: false,
  // Notifications
  notificationsNewMatches: true,
  notificationsMessages: true,
  notificationsAppActivity: false,
  notificationsEnabled: false,
  // Profile
  photos: [],
  bio: '',
  // Passed profile IDs (to filter them out)
  passedIds: [],
  // Humor & vibe filters
  filterEnjoysHumor: null,
  filterLikesBanter: null,
  filterCultureAware: null,
  filterTone: [],
  filterDatingIntentionally: null,
  filterEmotionallyAvailable: null,
  filterHereForReal: null,
};

function load() {
  try {
    const s = localStorage.getItem(STORAGE_KEY);
    return s ? { ...defaults, ...JSON.parse(s) } : { ...defaults };
  } catch {
    return { ...defaults };
  }
}

function save(data) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  } catch (e) {
    console.warn('Failed to save preferences', e);
  }
}

const UserPreferencesContext = createContext(null);

export function UserPreferencesProvider({ children }) {
  const { user } = useAuth();
  const [prefs, setPrefs] = useState(load);

  useEffect(() => {
    save(prefs);
  }, [prefs]);

  useEffect(() => {
    if (!hasSupabase || !user?.id || user.id === 'demo') return;
    getPreferences(user.id).then((data) => {
      if (!data) return;
      setPrefs((p) => ({
        ...p,
        ageMin: data.age_min ?? p.ageMin,
        ageMax: data.age_max ?? p.ageMax,
        maxDistance: data.max_distance_miles ?? p.maxDistance,
        interestedIn: data.interested_in?.[0] ?? p.interestedIn,
        preferredEthnicities: data.preferred_ethnicities || [],
        preferredHairColors: data.preferred_hair_colors || [],
        filterEnjoysHumor: data.filter_enjoys_humor,
        filterLikesBanter: data.filter_likes_banter,
        filterCultureAware: data.filter_culture_aware,
        filterTone: data.filter_tone || [],
        filterDatingIntentionally: data.filter_dating_intentionally,
        filterEmotionallyAvailable: data.filter_emotionally_available,
        filterHereForReal: data.filter_here_for_real,
      }));
    });
  }, [user?.id]);

  const update = useCallback((updates) => {
    setPrefs((p) => ({ ...p, ...updates }));
  }, []);

  const addPassedId = useCallback((id) => {
    setPrefs((p) => ({
      ...p,
      passedIds: [...(p.passedIds || []), id].slice(-100),
    }));
  }, []);

  const requestLocation = useCallback(() => {
    if (!navigator.geolocation) {
      update({ locationEnabled: true });
      return Promise.resolve({ granted: true });
    }
    return new Promise((resolve) => {
      navigator.geolocation.getCurrentPosition(
        (pos) => {
          const lat = pos.coords.latitude;
          const lon = pos.coords.longitude;
          update({ locationEnabled: true, latitude: lat, longitude: lon });
          resolve({ granted: true, latitude: lat, longitude: lon });
        },
        () => {
          update({ locationEnabled: false });
          resolve({ granted: false });
        }
      );
    });
  }, [update]);

  const requestNotifications = useCallback(() => {
    if (!('Notification' in window)) {
      update({ notificationsEnabled: true });
      return Promise.resolve(true);
    }
    if (Notification.permission === 'granted') {
      update({ notificationsEnabled: true });
      return Promise.resolve(true);
    }
    return Notification.requestPermission().then((p) => {
      const granted = p === 'granted';
      update({ notificationsEnabled: granted });
      return granted;
    });
  }, [update]);

  return (
    <UserPreferencesContext.Provider
      value={{
        ...prefs,
        update,
        addPassedId,
        requestLocation,
        requestNotifications,
      }}
    >
      {children}
    </UserPreferencesContext.Provider>
  );
}

export function useUserPreferences() {
  const ctx = useContext(UserPreferencesContext);
  return ctx || { ...defaults, update: () => {}, addPassedId: () => {}, requestLocation: () => Promise.resolve({ granted: false }), requestNotifications: () => Promise.resolve(false) };
}
