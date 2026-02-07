import { useState, useRef } from 'react';
import '../styles/SwipeableCard.css';

const SWIPE_THRESHOLD = 80;
const ROTATION_FACTOR = 0.15;

export default function SwipeableCard({ profile, onSwipeLeft, onSwipeRight, onClick, isTop }) {
  const [drag, setDrag] = useState({ x: 0, y: 0 });
  const [isDragging, setIsDragging] = useState(false);
  const startPos = useRef({ x: 0, y: 0 });

  const handleStart = (clientX, clientY) => {
    if (!isTop) return;
    startPos.current = { x: clientX - drag.x, y: clientY - drag.y };
    setIsDragging(true);
  };

  const handleMove = (clientX, clientY) => {
    if (!isDragging || !isTop) return;
    const x = clientX - startPos.current.x;
    setDrag({ x, y: (clientY - startPos.current.y) * 0.2 });
  };

  const handleEnd = () => {
    if (!isDragging || !isTop) return;
    setIsDragging(false);

    if (drag.x < -SWIPE_THRESHOLD) {
      animateOut(-1, onSwipeLeft);
    } else if (drag.x > SWIPE_THRESHOLD) {
      animateOut(1, onSwipeRight);
    } else {
      setDrag({ x: 0, y: 0 });
    }
  };

  const animateOut = (direction, callback) => {
    setDrag({ x: direction * 500, y: 0 });
    setTimeout(() => {
      callback?.();
    }, 250);
  };

  const rotation = isTop ? (drag.x / 20) * ROTATION_FACTOR : 0;
  const opacity = isTop ? Math.min(1, 1 - Math.abs(drag.x) / 400) : 1;
  const transform = isTop
    ? `translate(${drag.x}px, ${drag.y}px) rotate(${rotation}deg)`
    : undefined;

  return (
    <div
      className={`swipe-card ${isTop ? 'top' : 'stacked'} ${isDragging ? 'dragging' : ''}`}
      style={{
        ...(transform && { transform }),
        opacity,
        zIndex: isTop ? 10 : 10 - 1,
      }}
      onMouseDown={(e) => handleStart(e.clientX, e.clientY)}
      onMouseMove={(e) => handleMove(e.clientX, e.clientY)}
      onMouseUp={handleEnd}
      onMouseLeave={handleEnd}
      onTouchStart={(e) => handleStart(e.touches[0].clientX, e.touches[0].clientY)}
      onTouchMove={(e) => handleMove(e.touches[0].clientX, e.touches[0].clientY)}
      onTouchEnd={handleEnd}
      onClick={(e) => {
        if (isTop && !isDragging && Math.abs(drag.x) < 10) onClick?.(e);
      }}
    >
      <div className="swipe-overlay swipe-nope" style={{ opacity: Math.min(1, -drag.x / 100) }}>
        NOPE
      </div>
      <div className="swipe-overlay swipe-like" style={{ opacity: Math.min(1, drag.x / 100) }}>
        LIKE
      </div>
      <div className="card-image-wrap">
        <img
          src={profile.image}
          alt={profile.name}
          className="card-image"
          draggable={false}
          onError={(e) => {
            e.target.onerror = null;
            e.target.src = 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600&h=800&fit=crop';
          }}
        />
        {(profile.prompt_responses && Object.keys(profile.prompt_responses).length > 0) || (profile.badges && profile.badges.length > 0) ? (
          <div className="card-highlight">
            {profile.prompt_responses && Object.keys(profile.prompt_responses).length > 0 && profile.badges?.length > 0
              ? 'Culture-aware and humor-compatible'
              : profile.prompt_responses && Object.keys(profile.prompt_responses).length > 0
                ? 'Proudly debunks internet myths'
                : 'Culture-aware'}
          </div>
        ) : null}
        <div className="card-indicators">
          {[1, 2, 3].map((i) => (
            <div key={i} className={`indicator ${i === 1 ? 'active' : ''}`} />
          ))}
        </div>
      </div>
      <div className="card-info">
        <h1 className="card-name">{profile.name}, {profile.age}</h1>
        <div className="card-location">
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
            <circle cx="12" cy="10" r="3" />
          </svg>
          <span className="card-location-text">{profile.location} • {profile.distance}</span>
        </div>
      </div>
    </div>
  );
}
