/**
 * User-friendly messages for auth errors, especially Supabase rate limits.
 */
export function getAuthErrorMessage(err) {
  const msg = err?.message || String(err);
  const lower = msg.toLowerCase();

  if (lower.includes('rate limit') || lower.includes('rate_limit') || lower.includes('email rate limit')) {
    return 'Too many emails sent. Please try again in about an hour.';
  }
  if (lower.includes('invalid login') || lower.includes('invalid credentials')) {
    return 'Invalid email or password.';
  }
  if (lower.includes('user already registered')) {
    return 'An account with this email already exists. Try signing in.';
  }
  if (lower.includes('schema cache') || lower.includes('column') && lower.includes('not found')) {
    return 'Database update needed. Please run the latest migration in Supabase SQL Editor.';
  }

  return msg || 'Something went wrong. Please try again.';
}
