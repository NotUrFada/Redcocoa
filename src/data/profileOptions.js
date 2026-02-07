export const ETHNICITY_OPTIONS = [
  'Black',
  'White',
  'Asian',
  'Hispanic/Latino',
  'Middle Eastern',
  'Mixed',
  'Other',
  'Prefer not to say',
];

export const HAIR_COLOR_OPTIONS = [
  'Black',
  'Brown',
  'Blonde',
  'Red/Ginger',
  'Gray',
  'Other',
  'Prefer not to say',
];

// Humor preference (onboarding/settings)
export const HUMOR_PREFERENCE_OPTIONS = [
  { value: 'love', label: 'Love it', emoji: '😄' },
  { value: 'sometimes', label: 'Sometimes', emoji: '😐' },
  { value: 'not_for_me', label: 'Not for me', emoji: '🚫' },
];

// Tone / vibe selector
export const TONE_OPTIONS = [
  { value: 'playful', label: 'Playful' },
  { value: 'dry', label: 'Dry' },
  { value: 'soft', label: 'Soft' },
  { value: 'serious', label: 'Serious' },
];

// Ginger prompt pack
export const GINGER_PROMPTS = [
  { id: 'ginger_1', text: 'The internet says gingers don\'t have souls. My evidence otherwise is ___.' },
  { id: 'ginger_2', text: 'A myth about redheads people still believe is ___.' },
  { id: 'ginger_3', text: 'Medieval Europe thought redheads were ___ (wrong answers only).' },
  { id: 'ginger_4', text: 'Apparently my hair color means I\'m ___.' },
];

// Black prompt pack
export const BLACK_PROMPTS = [
  { id: 'black_1', text: 'Something people always assume about me that\'s wrong is ___.' },
  { id: 'black_2', text: 'A part of my culture I love sharing with the right person is ___.' },
  { id: 'black_3', text: 'The most unhinged thing someone has said to me on a date was ___.' },
  { id: 'black_4', text: 'A boundary I learned the hard way is ___.' },
];

// Ginger badges (1-2 max)
export const GINGER_BADGES = [
  { id: 'ginger_soul', label: 'Has a Soul (Verified)', emoji: '🧠' },
  { id: 'ginger_fiery', label: 'Allegedly Fiery', emoji: '🔥' },
  { id: 'ginger_witch', label: 'Historically Accused Witch', emoji: '🧙' },
  { id: 'ginger_pain', label: 'Feels Pain, Just Dramatic', emoji: '😌' },
  { id: 'ginger_chaos', label: 'Chaos Magnet (Unconfirmed)', emoji: '✨' },
];

// Black badges (1-2 max)
export const BLACK_BADGES = [
  { id: 'black_culture', label: 'Culture Rich', emoji: '✨' },
  { id: 'black_soft', label: 'Soft Life Advocate', emoji: '😌' },
  { id: 'black_music', label: 'Music Snob (Respectfully)', emoji: '🎶' },
  { id: 'black_ei', label: 'Emotionally Intelligent', emoji: '🧠' },
  { id: 'black_preference', label: 'Knows the Difference Between Preference & Fetish', emoji: '🔥' },
  { id: 'black_been', label: 'Been Here Before', emoji: '👀' },
];

// Icebreaker cards (swipeable)
export const ICEBREAKER_CARDS = [
  { id: 'soul', text: 'Soul status: confirmed or pending?', emoji: '🧠' },
  { id: 'fiery', text: 'Allegedly fiery—true or propaganda?', emoji: '🔥' },
  { id: 'boundary', text: "What's a boundary you wish people respected more?", emoji: '👀' },
  { id: 'intentional', text: "What does dating intentionally mean to you?", emoji: '🤝' },
];

// Reaction stickers (opt-in)
export const REACTION_STICKERS = [
  { id: 'brain', emoji: '🧠' },
  { id: 'fire', emoji: '🔥' },
  { id: 'witch', emoji: '🧙' },
  { id: 'say_again', emoji: '😌', label: 'Say that again' },
  { id: 'side_eye', emoji: '👀', label: 'Side-eye but listening' },
  { id: 'respectfully', emoji: '🤝', label: 'Respectfully' },
  { id: 'ate', emoji: '✨', label: 'You ate that' },
];

// Discovery filter options
export const HUMOR_FILTER_OPTIONS = [
  { id: 'enjoys_humor', label: 'Enjoys playful humor' },
  { id: 'likes_banter', label: 'Likes banter' },
  { id: 'culture_aware', label: 'Culture-aware' },
];

export const TONE_FILTER_OPTIONS = [
  { id: 'playful', label: 'Playful' },
  { id: 'dry', label: 'Dry' },
  { id: 'soft', label: 'Soft' },
  { id: 'serious', label: 'Serious' },
];

export const VALUES_FILTER_OPTIONS = [
  { id: 'dating_intentionally', label: 'Dating intentionally' },
  { id: 'emotionally_available', label: 'Emotionally available' },
  { id: 'culture_aware', label: 'Culture-aware' },
  { id: 'here_for_real', label: 'Here for something real' },
];
