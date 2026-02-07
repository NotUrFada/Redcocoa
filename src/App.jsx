import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './context/AuthContext';
import AppLayout from './components/AppLayout';
import Discover from './pages/Discover';
import Profile from './pages/Profile';
import Likes from './pages/Likes';
import Chats from './pages/Chats';
import Chat from './pages/Chat';
import Settings from './pages/Settings';
import EditProfile from './pages/EditProfile';
import Login from './pages/Login';
import Signup from './pages/Signup';
import ForgotPassword from './pages/ForgotPassword';
import ResetPassword from './pages/ResetPassword';
import AuthCallback from './pages/AuthCallback';
import OnboardingLayout from './pages/onboarding/OnboardingLayout';
import WelcomeSlides from './pages/onboarding/WelcomeSlides';
import Consent from './pages/onboarding/Consent';
import ProfileSetup from './pages/onboarding/ProfileSetup';
import Permissions from './pages/onboarding/Permissions';
import PrivacyPolicy from './pages/PrivacyPolicy';
import TermsOfService from './pages/TermsOfService';
import Blocked from './pages/Blocked';
import { hasSupabase } from './lib/supabase';
import { useOnboarding } from './context/OnboardingContext';
import './components/AppLayout.css';

function ProtectedRoute({ children }) {
  const { user, loading } = useAuth();
  const { completed: onboardingComplete } = useOnboarding();
  if (loading) return <div className="loading-screen" />;
  if (hasSupabase && !user) return <Navigate to="/login" replace />;
  if (user && !onboardingComplete) return <Navigate to="/onboarding" replace />;
  return children;
}

function OnboardingRoute({ children }) {
  const { user, loading } = useAuth();
  const { completed: onboardingComplete } = useOnboarding();
  if (loading) return <div className="loading-screen" />;
  if (hasSupabase && !user) return <Navigate to="/login" replace />;
  if (user && onboardingComplete) return <Navigate to="/" replace />;
  return children;
}

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route path="/login" element={<Login />} />
        <Route path="/signup" element={<Signup />} />
        <Route path="/forgot-password" element={<ForgotPassword />} />
        <Route path="/reset-password" element={<ResetPassword />} />
        <Route path="/auth/callback" element={<AuthCallback />} />
        <Route path="/onboarding" element={
          <OnboardingRoute>
            <OnboardingLayout />
          </OnboardingRoute>
        }>
          <Route index element={<WelcomeSlides />} />
          <Route path="consent" element={<Consent />} />
          <Route path="profile" element={<ProfileSetup />} />
          <Route path="permissions" element={<Permissions />} />
        </Route>
        <Route path="/" element={
          <ProtectedRoute>
            <AppLayout />
          </ProtectedRoute>
        }>
          <Route index element={<Discover />} />
          <Route path="likes" element={<Likes />} />
          <Route path="chats" element={<Chats />} />
          <Route path="profile" element={<Settings />} />
          <Route path="profile/edit" element={<EditProfile />} />
        </Route>
        <Route path="/profile/:id" element={<ProtectedRoute><Profile /></ProtectedRoute>} />
        <Route path="/chat/:id" element={<ProtectedRoute><Chat /></ProtectedRoute>} />
        <Route path="/privacy" element={<PrivacyPolicy />} />
        <Route path="/terms" element={<TermsOfService />} />
        <Route path="/blocked" element={<ProtectedRoute><Blocked /></ProtectedRoute>} />
      </Routes>
    </BrowserRouter>
  );
}
