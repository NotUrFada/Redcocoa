# Chat Setup & Troubleshooting

If chats are not saving (messages disappear when you leave and return), check the following:

## 1. Supabase Configuration

Ensure `SUPABASE_URL` and `SUPABASE_ANON_KEY` are set in `Info.plist`. Without these, the app runs in demo mode—messages are never persisted.

## 2. Run Database Migrations

From the project root (with the web app), run:

```bash
cd "/Users/cream/Downloads/red-cocoa"
npx supabase db push
```

Or apply migrations manually in **Supabase Dashboard → SQL Editor**:
- `supabase/migrations/20250101000000_initial_schema.sql` (creates `matches` and `messages` tables)
- `supabase/migrations/20250105000000_realtime_messages.sql`
- `supabase/migrations/20250106000000_matches_insert_policy.sql`

## 3. Run RLS Policies

If you use custom RLS, run `supabase_rls_policies.sql` in **Supabase Dashboard → SQL Editor**.

## 4. Verify Tables Exist

In **Supabase Dashboard → Table Editor**, confirm:
- **matches** – columns: `id`, `user1_id`, `user2_id`, `created_at`
- **messages** – columns: `id`, `match_id`, `sender_id`, `content`, `created_at`

## 5. Error Handling

If a send fails, the app now shows an alert. Check the error message for RLS or schema issues.
