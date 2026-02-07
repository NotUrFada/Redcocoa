/**
 * Production API layer for Red Cocoa.
 * Uses Supabase when configured; falls back to mock data otherwise.
 */
import { supabase, hasSupabase } from './supabase';
import { profiles as mockProfiles, likes as mockLikes, chats as mockChats, messages as mockMessages, newMatches as mockNewMatches } from '../data/mockData';

function ageFromBirthDate(birthDate) {
  if (!birthDate) return null;
  const today = new Date();
  const birth = new Date(birthDate);
  let age = today.getFullYear() - birth.getFullYear();
  const m = today.getMonth() - birth.getMonth();
  if (m < 0 || (m === 0 && today.getDate() < birth.getDate())) age--;
  return age;
}

function haversineMiles(lat1, lon1, lat2, lon2) {
  if (!lat1 || !lon1 || !lat2 || !lon2) return 999;
  const R = 3959;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon / 2) * Math.sin(dLon / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function profileToCard(p, currentUserLat, currentUserLon) {
  const age = p.birth_date ? ageFromBirthDate(p.birth_date) : null;
  const photoUrls = p.photo_urls || [];
  const image = photoUrls[0] || 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=600&h=800&fit=crop';
  const distanceMiles = (currentUserLat && currentUserLon && p.latitude && p.longitude)
    ? Math.round(haversineMiles(currentUserLat, currentUserLon, p.latitude, p.longitude))
    : 5;
  return {
    id: p.id,
    name: p.name,
    age: age ?? 25,
    location: p.location || 'Unknown',
    distance: `${distanceMiles} miles away`,
    distanceMiles,
    bio: p.bio || '',
    image,
    interests: p.interests || [],
    height: p.height,
    sign: p.zodiac_sign,
    intent: p.intent,
    education: p.education,
    ethnicity: p.ethnicity,
    hair_color: p.hair_color,
    prompt_responses: p.prompt_responses || {},
    badges: p.badges || [],
    debunked_lines: p.debunked_lines || [],
    not_here_for: p.not_here_for || {},
    humor_preference: p.humor_preference,
    tone_vibe: p.tone_vibe,
  };
}

// --- Discovery ---
export async function getDiscoveryProfiles(userId, { ageMin, ageMax, maxDistance, interests, passedIds, preferredEthnicities, preferredHairColors, filterEnjoysHumor, filterLikesBanter, filterCultureAware, filterTone, filterDatingIntentionally, filterEmotionallyAvailable, filterHereForReal }) {
  if (!hasSupabase || !userId) return mockProfiles;

  const { data: myProfile } = await supabase.from('profiles').select('latitude, longitude').eq('id', userId).single();
  const myLat = myProfile?.latitude;
  const myLon = myProfile?.longitude;

  let query = supabase
    .from('profiles')
    .select('*')
    .neq('id', userId);

  const { data: blocked } = await supabase.from('blocked_users').select('blocked_id').eq('blocker_id', userId);
  const blockedIds = new Set((blocked || []).map((b) => b.blocked_id));

  const { data: passed } = await supabase.from('passed_users').select('passed_id').eq('user_id', userId);
  const passedIdsFromDb = new Set((passed || []).map((p) => p.passed_id));

  const { data: liked } = await supabase.from('likes').select('to_user_id').eq('from_user_id', userId);
  const likedIds = new Set((liked || []).map((l) => l.to_user_id));

  const { data: allProfiles, error } = await query;
  if (error) {
    console.warn('Discovery error:', error);
    return []; // Production: never show mock data on error
  }

  const excludeIds = new Set([...blockedIds, ...passedIdsFromDb, ...likedIds, ...(passedIds || []).map((id) => id)]);
  let list = (allProfiles || [])
    .filter((p) => !excludeIds.has(p.id))
    .map((p) => profileToCard(p, myLat, myLon));
  list = list.filter((p) => {
    if (p.age < (ageMin ?? 18) || p.age > (ageMax ?? 60)) return false;
    if (p.distanceMiles > (maxDistance ?? 100)) return false;
    if (interests?.length) {
      const overlap = (p.interests || []).some((pi) =>
        interests.some((ui) => String(pi).toLowerCase().includes(String(ui).toLowerCase()))
      );
      if (!overlap) return false;
    }
    if (preferredEthnicities?.length || preferredHairColors?.length) {
      const matchEthnicity = !preferredEthnicities?.length || (p.ethnicity && preferredEthnicities.includes(p.ethnicity));
      const matchHair = !preferredHairColors?.length || (p.hair_color && preferredHairColors.includes(p.hair_color));
      if (!matchEthnicity && !matchHair) return false;
    }
    if (filterEnjoysHumor && p.humor_preference === 'not_for_me') return false;
    if (filterLikesBanter && p.humor_preference === 'not_for_me') return false;
    if (filterCultureAware && !(p.prompt_responses && Object.keys(p.prompt_responses).length) && !(p.badges && p.badges.length)) return false;
    if (filterTone?.length && (!p.tone_vibe || !filterTone.includes(p.tone_vibe))) return false;
    return true;
  });

  return list;
}

export async function passOnProfile(userId, passedId) {
  if (!hasSupabase || !userId) return;
  const { error } = await supabase.from('passed_users').upsert({ user_id: userId, passed_id: passedId }, { onConflict: 'user_id,passed_id' });
  if (error) console.warn('Pass error:', error);
}

export async function likeProfile(userId, likedId) {
  if (!hasSupabase || !userId) return { isMatch: false };
  const { error: insertError } = await supabase.from('likes').insert({ from_user_id: userId, to_user_id: likedId });
  if (insertError) {
    if (insertError.code === '23505') {
      // Unique violation - already liked, still check for match
    } else {
      console.warn('Like error:', insertError);
      return { isMatch: false };
    }
  }
  const { data: mutual } = await supabase
    .from('likes')
    .select('id')
    .eq('from_user_id', likedId)
    .eq('to_user_id', userId)
    .single();
  if (mutual) {
    const u1 = userId < likedId ? userId : likedId;
    const u2 = userId < likedId ? likedId : userId;
    const { error: matchError } = await supabase.from('matches').upsert({ user1_id: u1, user2_id: u2 }, { onConflict: 'user1_id,user2_id' });
    if (!matchError) return { isMatch: true };
  }
  return { isMatch: false };
}

// --- Block & Report ---
export async function blockUser(blockerId, blockedId) {
  if (!hasSupabase || !blockerId) return;
  await supabase.from('blocked_users').upsert({ blocker_id: blockerId, blocked_id: blockedId }, { onConflict: 'blocker_id,blocked_id' });
}

export async function reportUser(reporterId, reportedId, reason, details = '') {
  if (!hasSupabase || !reporterId) return;
  await supabase.from('reports').insert({ reporter_id: reporterId, reported_id: reportedId, reason, details });
}

export async function getBlockedUsers(userId) {
  if (!hasSupabase || !userId) return [];
  const { data: blocks } = await supabase.from('blocked_users').select('blocked_id').eq('blocker_id', userId);
  if (!blocks?.length) return [];
  const ids = blocks.map((b) => b.blocked_id);
  const { data: profs } = await supabase.from('profiles').select('id, name, photo_urls').in('id', ids);
  const byId = Object.fromEntries((profs || []).map((p) => [p.id, p]));
  return ids.map((id) => ({
    id,
    name: byId[id]?.name || 'Unknown',
    image: (byId[id]?.photo_urls || [])[0],
  }));
}

export async function unblockUser(blockerId, blockedId) {
  if (!hasSupabase || !blockerId) return;
  await supabase.from('blocked_users').delete().eq('blocker_id', blockerId).eq('blocked_id', blockedId);
}

// --- Likes ---
export async function getLikes(userId) {
  if (!hasSupabase || !userId) return mockLikes;
  const { data: likes } = await supabase
    .from('likes')
    .select('from_user_id, created_at')
    .eq('to_user_id', userId);
  const { data: matches } = await supabase
    .from('matches')
    .select('user1_id, user2_id')
    .or(`user1_id.eq.${userId},user2_id.eq.${userId}`);
  const matchIds = new Set((matches || []).flatMap((m) => [m.user1_id, m.user2_id]).filter((id) => id !== userId));

  const ids = [...new Set((likes || []).map((l) => l.from_user_id))];
  const { data: profs } = await supabase.from('profiles').select('*').in('id', ids);
  const profilesById = Object.fromEntries((profs || []).map((p) => [p.id, p]));

  return (likes || []).map((l) => {
    const p = profilesById[l.from_user_id];
    const card = profileToCard(p);
    const timeAgo = l.created_at ? new Date(l.created_at).toLocaleDateString() : 'Recently';
    return {
      ...card,
      status: matchIds.has(l.from_user_id) ? 'Match' : `Liked you ${timeAgo}`,
      isMatch: matchIds.has(l.from_user_id),
    };
  });
}

// --- Chats & Messages ---
export async function getMatches(userId) {
  if (!hasSupabase || !userId) return [];
  const { data } = await supabase
    .from('matches')
    .select('user1_id, user2_id, id')
    .or(`user1_id.eq.${userId},user2_id.eq.${userId}`);
  return data || [];
}

export async function getChats(userId) {
  if (!hasSupabase || !userId) return mockChats;
  const matches = await getMatches(userId);
  const otherIds = matches.flatMap((m) => (m.user1_id === userId ? m.user2_id : m.user1_id));
  if (otherIds.length === 0) return [];

  const { data: profs } = await supabase.from('profiles').select('id, name, photo_urls').in('id', otherIds);
  const { data: lastMsgs } = await supabase
    .from('messages')
    .select('match_id, sender_id, content, created_at')
    .in('match_id', matches.map((m) => m.id))
    .order('created_at', { ascending: false });

  const matchByOther = Object.fromEntries(matches.map((m) => {
    const other = m.user1_id === userId ? m.user2_id : m.user1_id;
    return [other, m];
  }));

  const profsById = Object.fromEntries((profs || []).map((p) => [p.id, p]));
  const lastByMatch = {};
  (lastMsgs || []).forEach((msg) => {
    if (!lastByMatch[msg.match_id]) lastByMatch[msg.match_id] = msg;
  });

  return otherIds.map((id) => {
    const p = profsById[id];
    const m = matchByOther[id];
    const last = lastByMatch[m?.id];
    return {
      id,
      name: p?.name || 'Unknown',
      image: (p?.photo_urls || [])[0] || 'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?w=112&h=112&fit=crop',
      lastMessage: last?.content || 'No messages yet',
      time: last?.created_at ? new Date(last.created_at).toLocaleDateString() : '',
      unread: 0,
    };
  });
}

export async function getMatchId(userId, otherId) {
  if (!hasSupabase || !userId) return null;
  const { data: m1 } = await supabase.from('matches').select('id').eq('user1_id', userId).eq('user2_id', otherId).single();
  const { data: m2 } = await supabase.from('matches').select('id').eq('user1_id', otherId).eq('user2_id', userId).single();
  return (m1 || m2)?.id ?? null;
}

export async function getMessages(userId, otherId) {
  if (!hasSupabase || !userId) {
    const mock = mockMessages[otherId] || mockMessages.amara || [];
    return mock.map((m) => ({ ...m, sender_id: m.sent ? userId : otherId }));
  }
  const { data: m1 } = await supabase.from('matches').select('id').eq('user1_id', userId).eq('user2_id', otherId).single();
  const { data: m2 } = await supabase.from('matches').select('id').eq('user1_id', otherId).eq('user2_id', userId).single();
  const match = m1 || m2;
  if (!match) return [];

  const { data: msgs } = await supabase
    .from('messages')
    .select('*')
    .eq('match_id', match.id)
    .order('created_at', { ascending: true });

  return (msgs || []).map((m) => ({
    text: m.content,
    time: new Date(m.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }),
    sent: m.sender_id === userId,
  }));
}

export async function sendMessage(userId, otherId, content) {
  if (!hasSupabase || !userId) return;
  const u1 = userId < otherId ? userId : otherId;
  const u2 = userId < otherId ? otherId : userId;
  let { data: match } = await supabase.from('matches').select('id').eq('user1_id', u1).eq('user2_id', u2).single();
  if (!match) {
    await supabase.from('matches').insert({ user1_id: u1, user2_id: u2 });
    const { data: m } = await supabase.from('matches').select('id').eq('user1_id', u1).eq('user2_id', u2).single();
    match = m;
  }
  if (match) {
    await supabase.from('messages').insert({ match_id: match.id, sender_id: userId, content });
  }
}

// --- Profile by ID ---
export async function getProfileById(profileId, userId) {
  if (!hasSupabase || !profileId) {
    const mock = mockProfiles.find((p) => p.id === profileId) || mockProfiles[0];
    return mock;
  }
  const { data } = await supabase.from('profiles').select('*').eq('id', profileId).single();
  if (!data) return null;
  const myProfile = userId ? (await supabase.from('profiles').select('latitude, longitude').eq('id', userId).single())?.data : null;
  return profileToCard(data, myProfile?.latitude, myProfile?.longitude);
}

// --- Preferences sync ---
export async function getPreferences(userId) {
  if (!hasSupabase || !userId) return null;
  const { data } = await supabase.from('preferences').select('*').eq('user_id', userId).single();
  return data;
}

export async function updatePreferences(userId, updates) {
  if (!hasSupabase || !userId) return;
  const mapped = { ...updates };
  if ('preferredEthnicities' in updates) mapped.preferred_ethnicities = updates.preferredEthnicities || [];
  if ('preferredHairColors' in updates) mapped.preferred_hair_colors = updates.preferredHairColors || [];
  if ('filterEnjoysHumor' in updates) mapped.filter_enjoys_humor = updates.filterEnjoysHumor;
  if ('filterLikesBanter' in updates) mapped.filter_likes_banter = updates.filterLikesBanter;
  if ('filterCultureAware' in updates) mapped.filter_culture_aware = updates.filterCultureAware;
  if ('filterTone' in updates) mapped.filter_tone = updates.filterTone || [];
  if ('filterDatingIntentionally' in updates) mapped.filter_dating_intentionally = updates.filterDatingIntentionally;
  if ('filterEmotionallyAvailable' in updates) mapped.filter_emotionally_available = updates.filterEmotionallyAvailable;
  if ('filterHereForReal' in updates) mapped.filter_here_for_real = updates.filterHereForReal;
  const row = { user_id: userId, ...mapped };
  ['preferredEthnicities', 'preferredHairColors', 'filterEnjoysHumor', 'filterLikesBanter', 'filterCultureAware', 'filterTone', 'filterDatingIntentionally', 'filterEmotionallyAvailable', 'filterHereForReal'].forEach((k) => delete row[k]);
  await supabase.from('preferences').upsert(row, { onConflict: 'user_id' });
}

// --- Photo upload ---
export async function uploadProfilePhoto(userId, file) {
  if (!hasSupabase || !userId) return null;
  const ext = file.name.split('.').pop() || 'jpg';
  const path = `${userId}/${Date.now()}.${ext}`;
  const { error } = await supabase.storage.from('avatars').upload(path, file, { upsert: true });
  if (error) return null;
  const { data } = supabase.storage.from('avatars').getPublicUrl(path);
  return data.publicUrl;
}

export async function setProfilePhotos(userId, photoUrls) {
  if (!hasSupabase || !userId) return;
  await supabase.from('profiles').update({ photo_urls: photoUrls, updated_at: new Date().toISOString() }).eq('id', userId);
}
