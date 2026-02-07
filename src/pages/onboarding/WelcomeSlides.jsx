import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import '../../styles/Onboarding.css';

const slides = [
  {
    id: 1,
    title: 'Find your match',
    subtitle: 'Swipe through profiles of people nearby who share your interests.',
    icon: '💕',
  },
  {
    id: 2,
    title: 'Connect meaningfully',
    subtitle: 'Start conversations that matter. No games, just real connections.',
    icon: '💬',
  },
  {
    id: 3,
    title: 'Meet in person',
    subtitle: 'When you\'re ready, take it offline. Your perfect date is nearby.',
    icon: '📍',
  },
];

export default function WelcomeSlides() {
  const [current, setCurrent] = useState(0);
  const navigate = useNavigate();
  const slide = slides[current];
  const isLast = current === slides.length - 1;

  const handleNext = () => {
    if (isLast) {
      navigate('/onboarding/consent');
    } else {
      setCurrent((c) => c + 1);
    }
  };

  const handleSkip = () => {
    navigate('/onboarding/consent');
  };

  return (
    <div className="onboarding-page welcome-slides">
      <div className="slide-content">
        <div className="slide-icon">{slide.icon}</div>
        <h1 className="slide-title">{slide.title}</h1>
        <p className="slide-subtitle">{slide.subtitle}</p>
      </div>

      <div className="slide-indicators">
        {slides.map((_, i) => (
          <div
            key={i}
            className={`indicator ${i === current ? 'active' : ''}`}
            onClick={() => setCurrent(i)}
          />
        ))}
      </div>

      <div className="onboarding-actions">
        <button className="btn-skip" onClick={handleSkip}>
          Skip
        </button>
        <button className="btn-primary" onClick={handleNext}>
          {isLast ? 'Get Started' : 'Next'}
        </button>
      </div>
    </div>
  );
}
