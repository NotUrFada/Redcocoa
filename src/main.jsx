import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import { AuthProvider } from './context/AuthContext'
import { OnboardingProvider } from './context/OnboardingContext'
import { UserPreferencesProvider } from './context/UserPreferencesContext'
import App from './App.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <AuthProvider>
      <OnboardingProvider>
        <UserPreferencesProvider>
          <App />
        </UserPreferencesProvider>
      </OnboardingProvider>
    </AuthProvider>
  </StrictMode>,
)
