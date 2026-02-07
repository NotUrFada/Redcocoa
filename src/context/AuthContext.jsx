import { createContext, useContext, useEffect, useState } from 'react';
import { supabase, hasSupabase } from '../lib/supabase';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(null);
  const [profile, setProfile] = useState(null);
  const [loading, setLoading] = useState(true);
  const [recoverySession, setRecoverySession] = useState(false);

  useEffect(() => {
    if (!hasSupabase) {
      setUser({ id: 'demo', email: 'demo@redcocoa.app' });
      setProfile({ id: 'demo', name: 'Demo User' });
      setLoading(false);
      return;
    }

    supabase.auth.getSession().then(({ data: { session } }) => {
      setUser(session?.user ?? null);
      if (session?.user) {
        fetchProfile(session.user.id);
      } else {
        setLoading(false);
      }
    });

    const { data: { subscription } } = supabase.auth.onAuthStateChange(
      async (event, session) => {
        setUser(session?.user ?? null);
        setRecoverySession(event === 'PASSWORD_RECOVERY');
        if (session?.user) {
          await fetchProfile(session.user.id);
        } else {
          setProfile(null);
        }
        setLoading(false);
      }
    );

    return () => subscription.unsubscribe();
  }, []);

  async function fetchProfile(userId) {
    const { data } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();
    setProfile(data);
    setLoading(false);
  }

  const value = {
    user,
    profile,
    loading,
    signIn: async (email, password) => {
      if (!hasSupabase) {
        setUser({ id: 'demo', email });
        setProfile({ id: 'demo', name: email.split('@')[0] });
        return { user: { id: 'demo', email } };
      }
      const { data, error } = await supabase.auth.signInWithPassword({ email, password });
      if (error) throw error;
      return data;
    },
    signUp: async (email, password, metadata = {}) => {
      if (!hasSupabase) {
        setUser({ id: 'demo', email });
        setProfile({ id: 'demo', name: metadata.name || email.split('@')[0] });
        return { user: { id: 'demo', email }, isNewUser: true };
      }
      const redirectTo = `${window.location.origin}/#/auth/callback`;
      const { data, error } = await supabase.auth.signUp({
        email,
        password,
        options: { data: metadata, emailRedirectTo: redirectTo },
      });
      if (error) throw error;
      return { ...data, isNewUser: true };
    },
    signOut: async () => {
      if (hasSupabase) await supabase.auth.signOut();
      setUser(null);
      setProfile(null);
    },
    updateProfile: async (updates) => {
      if (!user) return;
      if (!hasSupabase) {
        setProfile((p) => ({ ...p, ...updates }));
        return { ...profile, ...updates };
      }
      const { data, error } = await supabase
        .from('profiles')
        .update({ ...updates, updated_at: new Date().toISOString() })
        .eq('id', user.id)
        .select()
        .single();
      if (error) throw error;
      setProfile(data);
      return data;
    },
    updateUserMetadata: async (metadata) => {
      if (!user) return;
      if (!hasSupabase) {
        setUser((u) => ({ ...u, user_metadata: { ...u?.user_metadata, ...metadata } }));
        return;
      }
      const { data, error } = await supabase.auth.updateUser({ data: metadata });
      if (error) throw error;
      if (data?.user) setUser(data.user);
    },
    updateEmail: async (email) => {
      if (!user) return;
      if (!hasSupabase) {
        setUser((u) => ({ ...u, email: email.trim() || u?.email }));
        return;
      }
      const { data, error } = await supabase.auth.updateUser({ email: email.trim() });
      if (error) throw error;
      if (data?.user) setUser(data.user);
    },
    resetPasswordForEmail: async (email) => {
      if (!hasSupabase) return;
      const redirectTo = `${window.location.origin}/#/reset-password`;
      const { error } = await supabase.auth.resetPasswordForEmail(email.trim(), { redirectTo });
      if (error) throw error;
    },
    updatePassword: async (password) => {
      if (!user) return;
      if (!hasSupabase) return;
      const { error } = await supabase.auth.updateUser({ password });
      if (error) throw error;
      setRecoverySession(false);
    },
    clearRecoverySession: () => setRecoverySession(false),
    recoverySession,
  };

  return (
    <AuthContext.Provider value={value}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const context = useContext(AuthContext);
  if (!context) {
    return {
      user: null,
      profile: null,
      loading: false,
      signIn: async () => {},
      signUp: async () => {},
      signOut: async () => {},
      updateProfile: async () => {},
      updateUserMetadata: async () => {},
      updateEmail: async () => {},
      resetPasswordForEmail: async () => {},
      updatePassword: async () => {},
      clearRecoverySession: () => {},
      recoverySession: false,
    };
  }
  return context;
}
