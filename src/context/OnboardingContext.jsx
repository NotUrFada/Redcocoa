import { createContext, useContext, useState, useCallback, useEffect } from 'react';
import { useAuth } from './AuthContext';

const KEY_PREFIX = 'redcocoa_onboarding_';
const LEGACY_KEY = 'redcocoa_onboarding_complete';

function getStorageKey(userId) {
  return userId ? `${KEY_PREFIX}${userId}` : `${KEY_PREFIX}anon`;
}

const OnboardingContext = createContext(null);

export function OnboardingProvider({ children }) {
  const { user } = useAuth();
  const userId = user?.id;
  const storageKey = getStorageKey(userId);

  const [completed, setCompletedState] = useState(() => {
    try {
      return localStorage.getItem(storageKey) === 'true';
    } catch {
      return false;
    }
  });

  useEffect(() => {
    try {
      let done = localStorage.getItem(storageKey) === 'true';
      if (!done && userId && localStorage.getItem(LEGACY_KEY) === 'true') {
        localStorage.setItem(storageKey, 'true');
        done = true;
      }
      setCompletedState(done);
    } catch {
      setCompletedState(false);
    }
  }, [storageKey, userId]);

  const completeOnboarding = useCallback(() => {
    try {
      localStorage.setItem(storageKey, 'true');
      setCompletedState(true);
    } catch (e) {
      setCompletedState(true);
    }
  }, [storageKey]);

  const resetOnboarding = useCallback(() => {
    try {
      localStorage.removeItem(storageKey);
      setCompletedState(false);
    } catch (e) {
      setCompletedState(false);
    }
  }, [storageKey]);

  return (
    <OnboardingContext.Provider value={{ completed, completeOnboarding, resetOnboarding }}>
      {children}
    </OnboardingContext.Provider>
  );
}

export function useOnboarding() {
  const context = useContext(OnboardingContext);
  return context || { completed: true, completeOnboarding: () => {}, resetOnboarding: () => {} };
}
