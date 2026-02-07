import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { getBlockedUsers, unblockUser } from '../lib/api';
import { hasSupabase } from '../lib/supabase';
import Header from '../components/Header';
import '../styles/Settings.css';

export default function Blocked() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const [blockedList, setBlockedList] = useState([]);
  const [loading, setLoading] = useState(true);

  const isProduction = hasSupabase && user?.id !== 'demo';

  useEffect(() => {
    if (!isProduction) {
      setLoading(false);
      return;
    }
    getBlockedUsers(user.id).then(setBlockedList).finally(() => setLoading(false));
  }, [isProduction, user?.id]);

  return (
    <div className="settings-page">
      <Header title="Blocked Contacts" showBack />

      <div className="content">
        {loading ? (
          <div className="empty-state-simple">
            <p>Loading...</p>
          </div>
        ) : blockedList.length === 0 ? (
          <div className="empty-state-simple">
            <p>You haven't blocked anyone yet.</p>
            <p className="empty-hint">Blocked contacts will appear here if you block someone from their profile or chat.</p>
          </div>
        ) : (
          <div className="settings-group">
            {blockedList.map((blocked) => (
              <div key={blocked.id} className="settings-item">
                <div className="settings-info" style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
                  {blocked.image && (
                    <img src={blocked.image} alt="" style={{ width: 40, height: 40, borderRadius: 20, objectFit: 'cover' }} />
                  )}
                  <span className="settings-title">{blocked.name}</span>
                </div>
                <button
                  className="btn-unblock"
                  onClick={async () => {
                    if (isProduction) await unblockUser(user.id, blocked.id);
                    setBlockedList((prev) => prev.filter((b) => b.id !== blocked.id));
                  }}
                >
                  Unblock
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
