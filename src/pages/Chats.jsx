import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { chats as mockChats, newMatches as mockNewMatches } from '../data/mockData';
import { useAuth } from '../context/AuthContext';
import { getChats } from '../lib/api';
import { hasSupabase } from '../lib/supabase';
import Header from '../components/Header';
import '../styles/Chats.css';

const TAB_ALL = 'all';
const TAB_UNREAD = 'unread';
const TAB_MATCHES = 'matches';
const TAB_ARCHIVE = 'archive';

export default function Chats() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [activeTab, setActiveTab] = useState(TAB_ALL);
  const [searchQuery, setSearchQuery] = useState('');
  const [showSearch, setShowSearch] = useState(false);
  const [chats, setChats] = useState(mockChats);
  const [newMatches, setNewMatches] = useState(mockNewMatches);
  const [loading, setLoading] = useState(hasSupabase);

  const isProduction = hasSupabase && user?.id !== 'demo';

  useEffect(() => {
    if (!isProduction) return;
    setLoading(true);
    getChats(user.id)
      .then((list) => {
        setChats(list || []);
        setNewMatches((list || []).slice(0, 5).map((c) => ({ ...c, online: false })));
      })
      .catch(() => setChats([]))
      .finally(() => setLoading(false));
  }, [isProduction, user?.id]);

  const matchIds = new Set(newMatches.map((m) => m.id));

  const filteredChats = chats.filter((c) => {
    if (searchQuery.trim()) {
      if (!c.name.toLowerCase().includes(searchQuery.toLowerCase())) return false;
    }
    if (activeTab === TAB_UNREAD) return c.unread > 0;
    if (activeTab === TAB_MATCHES) return matchIds.has(c.id);
    if (activeTab === TAB_ARCHIVE) return false;
    return true;
  });

  return (
    <div className="chats-page">
      <Header
        title="Messages"
        rightAction={
          <button className="icon-btn" onClick={() => setShowSearch((s) => !s)}>
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
              <circle cx="11" cy="11" r="8" />
              <line x1="21" y1="21" x2="16.65" y2="16.65" />
            </svg>
          </button>
        }
      />

      {showSearch && (
        <div className="chats-search-wrap">
          <input
            type="text"
            className="chats-search-input"
            placeholder="Search conversations..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            autoFocus
          />
        </div>
      )}

      <div className="filter-tabs">
        <button className={`filter-tab ${activeTab === TAB_ALL ? 'active' : ''}`} onClick={() => setActiveTab(TAB_ALL)}>All</button>
        <button className={`filter-tab ${activeTab === TAB_UNREAD ? 'active' : ''}`} onClick={() => setActiveTab(TAB_UNREAD)}>Unread</button>
        <button className={`filter-tab ${activeTab === TAB_MATCHES ? 'active' : ''}`} onClick={() => setActiveTab(TAB_MATCHES)}>Matches</button>
        <button className={`filter-tab ${activeTab === TAB_ARCHIVE ? 'active' : ''}`} onClick={() => setActiveTab(TAB_ARCHIVE)}>Archive</button>
      </div>

      <div className="chats-content">
        {loading ? (
          <div style={{ padding: 40, textAlign: 'center' }}>Loading...</div>
        ) : chats.length === 0 ? (
          <div className="chats-empty-state">
            <div className="chats-empty-icon">
              <svg width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.5">
                <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" />
              </svg>
            </div>
            <h3>No messages yet</h3>
            <p>When you match with someone, your conversations will appear here.</p>
            <button className="btn btn-primary" onClick={() => navigate('/')}>
              Start matching
            </button>
          </div>
        ) : (
          <>
            {newMatches.length > 0 && (
              <div className="new-matches-section">
                <h2 className="section-title">New Matches</h2>
                <div className="match-row">
                  {newMatches.map((match) => (
                    <div
                      key={match.id}
                      className="match-bubble"
                      onClick={() => navigate(`/chat/${match.id}`)}
                    >
                      <div className="match-img-container">
                        <img src={match.image} className="match-img" alt={match.name} />
                        {match.online && <div className="online-dot" />}
                      </div>
                      <span className="match-name">{match.name}</span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            <div className="message-list">
              {filteredChats.length === 0 ? (
                <div className="chats-empty-filter">
                  <p>No conversations match your filter.</p>
                  <button className="btn btn-outline-sm" onClick={() => setActiveTab(TAB_ALL)}>Show all</button>
                </div>
              ) : filteredChats.map((chat) => (
                <div
                  key={chat.id}
                  className="message-item"
                  onClick={() => navigate(`/chat/${chat.id}`)}
                >
                  <div className="msg-avatar-container">
                    <img src={chat.image} className="msg-avatar" alt={chat.name} />
                  </div>
                  <div className="msg-body">
                    <div className="msg-top">
                      <span className="msg-name">{chat.name}</span>
                      <span className="msg-time">{chat.time}</span>
                    </div>
                    <div className="msg-preview-container">
                      <span className={`msg-preview ${chat.unread ? 'unread' : ''}`}>
                        {chat.lastMessage}
                      </span>
                      {chat.unread > 0 && (
                        <div className="unread-badge">{chat.unread}</div>
                      )}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </>
        )}
      </div>
    </div>
  );
}
