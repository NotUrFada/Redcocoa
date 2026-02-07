import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { likes as mockLikes } from '../data/mockData';
import { useAuth } from '../context/AuthContext';
import { getLikes } from '../lib/api';
import { hasSupabase } from '../lib/supabase';
import Header from '../components/Header';
import '../styles/Likes.css';

export default function Likes() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [likes, setLikes] = useState(mockLikes);
  const [loading, setLoading] = useState(hasSupabase);

  const isProduction = hasSupabase && user?.id !== 'demo';

  useEffect(() => {
    if (!isProduction) return;
    setLoading(true);
    getLikes(user.id).then((list) => {
      setLikes(list || []);
      setLoading(false);
    });
  }, [isProduction, user?.id]);

  const newCount = likes.filter((l) => !l.isMatch).length;

  return (
    <div className="likes-page">
      <Header
        title="Likes & Matches"
        subtitle="Discover who's interested in you"
        rightAction={
          <button className="icon-btn">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M18 8A6 6 0 0 0 6 8c0 7-3 9-3 9h18s-3-2-3-9" />
              <path d="M13.73 21a2 2 0 0 1-3.46 0" />
            </svg>
          </button>
        }
      />

      <div className="likes-content">
        <div className="section-header">
          <span className="section-title">People who liked you</span>
          {newCount > 0 && <span className="count-tag">{newCount} New</span>}
        </div>

        {loading ? (
          <div className="likes-empty">Loading...</div>
        ) : likes.length === 0 ? (
          <div className="likes-empty">No likes yet. Keep swiping!</div>
        ) : (
          <div className="likes-grid">
            {likes.map((like) => (
              <div key={like.id} className="like-card">
                <div className="thumbnail-container">
                  {like.isMatch && <div className="match-badge">Match</div>}
                  <img src={like.image} className="thumbnail" alt={like.name} />
                </div>
                <div className="like-info">
                  <div className="name-age">{like.name}, {like.age}</div>
                  <div className="location">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                      <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z" />
                    </svg>
                    {like.location}
                  </div>
                  <div className="card-actions">
                    {like.isMatch ? (
                      <button
                        className="action-mini-btn btn-accept"
                        style={{ width: '100%', flex: 'none' }}
                        onClick={() => navigate(`/chat/${like.id}`)}
                      >
                        Send Message
                      </button>
                    ) : (
                      <>
                        <button className="action-mini-btn btn-reject">✕</button>
                        <button
                          className="action-mini-btn btn-accept"
                          onClick={() => navigate(`/profile/${like.id}`)}
                        >
                          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3">
                            <path d="M20 6L9 17l-5-5" />
                          </svg>
                        </button>
                      </>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
