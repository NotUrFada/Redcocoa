import { Outlet } from 'react-router-dom';

export default function OnboardingLayout() {
  return (
    <div className="onboarding-wrapper">
      <div className="onboarding-brand">
        <div className="brand-dot" />
        <span>Red Cocoa</span>
      </div>
      <Outlet />
    </div>
  );
}
