import { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { profiles, chats, messages as mockMessages } from '../data/mockData';
import { useAuth } from '../context/AuthContext';
import { getProfileById, getMessages, getMatchId, sendMessage } from '../lib/api';
import { ICEBREAKER_CARDS, REACTION_STICKERS } from '../data/profileOptions';
import { hasSupabase, supabase } from '../lib/supabase';
import FullScreenLayout from '../components/FullScreenLayout';
import '../styles/Chat.css';

export default function Chat() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [inputValue, setInputValue] = useState('');
  const [chatUser, setChatUser] = useState(null);
  const [chatMessages, setChatMessages] = useState([]);
  const [loading, setLoading] = useState(true);
  const [icebreakerDismissed, setIcebreakerDismissed] = useState(false);
  const [showIcebreakerCards, setShowIcebreakerCards] = useState(false);
  const [showReactions, setShowReactions] = useState(false);
  const [matchId, setMatchId] = useState(null);
  const contentRef = useRef(null);

  const ICEBREAKER_SUGGESTIONS = [
    'Serious question: how many souls do you currently own?',
    'Which stereotype about you is the most wrong?',
    "What makes you feel most respected when dating?",
    "What's something from your culture you love sharing?",
  ];
  const icebreakerSuggestion = chatMessages.length === 0 && !icebreakerDismissed && chatUser?.humor_preference !== 'not_for_me'
    ? ICEBREAKER_SUGGESTIONS[Math.floor(Math.random() * ICEBREAKER_SUGGESTIONS.length)]
    : null;

  const isProduction = hasSupabase && user?.id !== 'demo';

  useEffect(() => {
    if (!id) return;
    if (isProduction) {
      Promise.all([
        getProfileById(id, user?.id),
        getMessages(user?.id, id),
        getMatchId(user?.id, id),
      ]).then(([profile, msgs, mId]) => {
        setChatUser(profile);
        setChatMessages(msgs || []);
        setMatchId(mId);
        setLoading(false);
      });
    } else {
      const mockUser = chats.find((c) => c.id === id) || profiles.find((p) => p.id === id);
      const mock = mockMessages[id] || mockMessages.amara || [];
      setChatUser(mockUser);
      setChatMessages(mock.map((m) => ({ ...m, sender_id: m.sent ? user?.id : id })));
      setLoading(false);
    }
  }, [id, isProduction, user?.id]);

  // Real-time subscription for new messages
  useEffect(() => {
    if (!hasSupabase || !supabase || !matchId || !user?.id || !id) return;
    const channel = supabase
      .channel(`messages:${matchId}`)
      .on(
        'postgres_changes',
        {
          event: 'INSERT',
          schema: 'public',
          table: 'messages',
          filter: `match_id=eq.${matchId}`,
        },
        (payload) => {
          const row = payload.new;
          if (!row || row.sender_id === user.id) return; // Skip our own (already added optimistically)
          setChatMessages((prev) => [
            ...prev,
            {
              text: row.content,
              time: new Date(row.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
              sent: false,
            },
          ]);
        }
      )
      .subscribe();
    return () => {
      supabase.removeChannel(channel);
    };
  }, [matchId, user?.id, id]);

  useEffect(() => {
    contentRef.current?.scrollTo(0, contentRef.current.scrollHeight);
  }, [chatMessages]);

  const handleSend = async (textToSend) => {
    const text = (textToSend ?? inputValue).trim();
    if (!text || !chatUser) return;
    if (isProduction && user?.id) {
      await sendMessage(user.id, id, text);
      setChatMessages((prev) => [...prev, { text, time: 'Now', sent: true }]);
    } else {
      setChatMessages((prev) => [...prev, { text, time: 'Now', sent: true }]);
    }
    setInputValue('');
    setShowIcebreakerCards(false);
  };

  const handleReaction = (emoji, label) => {
    const content = label ? `${emoji} ${label}` : emoji;
    handleSend(content);
    setShowReactions(false);
  };

  if (loading || !chatUser) {
    return (
      <FullScreenLayout>
        <div className="chat-page">
          <div className="chat-content" style={{ padding: 40, textAlign: 'center' }}>Loading...</div>
        </div>
      </FullScreenLayout>
    );
  }

  const displayName = chatUser.name;
  const avatar = chatUser.image || `https://images.unsplash.com/photo-1531746020798-e6953c6e8e04?w=100&h=100&fit=crop`;

  return (
    <FullScreenLayout>
    <div className="chat-page">
      <header className="chat-header">
        <button className="chat-header-back-btn" onClick={() => navigate('/chats')} aria-label="Back to chats">
          <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
            <polyline points="15 18 9 12 15 6" />
          </svg>
        </button>
        <div className="header-profile">
          <img src={avatar} className="header-avatar" alt={displayName} />
          <div className="header-info">
            <h2>{displayName}</h2>
            <div className="status">
              <div className="status-dot" />
              Active now
            </div>
          </div>
        </div>
        <button className="chat-header-menu-btn" onClick={() => navigate(`/profile/${id}`)} aria-label="View profile">
          <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <circle cx="12" cy="12" r="1" />
            <circle cx="12" cy="5" r="1" />
            <circle cx="12" cy="19" r="1" />
          </svg>
        </button>
      </header>

      <div className="chat-content" ref={contentRef}>
        <div className="date-divider">Today</div>

        {chatMessages.length === 0 && (
          <div className="chat-empty-state">
            <div className="chat-empty-icon">
              <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
              </svg>
            </div>
            <p className="chat-empty-title">No messages yet</p>
            <p className="chat-empty-subtitle">Say hi to start the conversation!</p>
          </div>
        )}

        {icebreakerSuggestion && (
          <div className="icebreaker-suggestion">
            <p className="icebreaker-label">Icebreaker idea</p>
            <p className="icebreaker-text">{icebreakerSuggestion}</p>
            <div className="icebreaker-actions">
              <button type="button" className="icebreaker-use" onClick={() => handleSend(icebreakerSuggestion)}>Use this</button>
              <button type="button" className="icebreaker-dismiss" onClick={() => setIcebreakerDismissed(true)}>Dismiss</button>
            </div>
          </div>
        )}

        {chatMessages.map((msg, i) => (
          <div key={i} className={`message-row ${msg.sent ? 'sent' : 'received'}`}>
            <div className="bubble">{msg.text}</div>
            <span className="timestamp">{msg.time}</span>
          </div>
        ))}
      </div>

      {showIcebreakerCards && (
        <div className="icebreaker-cards-bar">
          <button type="button" className="icebreaker-cards-close" onClick={() => setShowIcebreakerCards(false)}>×</button>
          <div className="icebreaker-cards-scroll">
            {ICEBREAKER_CARDS.map((card) => (
              <button
                key={card.id}
                type="button"
                className="icebreaker-card"
                onClick={() => handleSend(`${card.emoji} ${card.text}`)}
              >
                <span className="icebreaker-card-emoji">{card.emoji}</span>
                <span className="icebreaker-card-text">{card.text}</span>
              </button>
            ))}
          </div>
        </div>
      )}

      {showReactions && (
        <div className="reactions-picker">
          {REACTION_STICKERS.map((r) => (
            <button
              key={r.id}
              type="button"
              className="reaction-btn"
              onClick={() => handleReaction(r.emoji, r.label)}
              title={r.label || r.emoji}
            >
              {r.emoji}
            </button>
          ))}
        </div>
      )}

      <div className="input-area">
        <button
          type="button"
          className="action-btn btn-icebreaker"
          onClick={() => setShowIcebreakerCards(!showIcebreakerCards)}
          title="Icebreaker cards"
        >
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
            <rect x="3" y="3" width="18" height="18" rx="2" />
            <path d="M3 9h18M9 21V9" />
          </svg>
        </button>
        <button
          type="button"
          className="action-btn btn-reactions"
          onClick={() => setShowReactions(!showReactions)}
          title="Reactions"
        >
          <span className="reaction-emoji-preview">✨</span>
        </button>
        <div className="input-container">
          <input
            type="text"
            placeholder="Type a message..."
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSend()}
          />
        </div>
        <button className="action-btn btn-send" onClick={() => handleSend()}>
          <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5">
            <line x1="22" y1="2" x2="11" y2="13" />
            <polygon points="22 2 15 22 11 13 2 9 22 2" />
          </svg>
        </button>
      </div>
    </div>
    </FullScreenLayout>
  );
}
