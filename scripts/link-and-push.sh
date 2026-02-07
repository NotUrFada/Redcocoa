#!/bin/bash
# Link Supabase project and push migrations
#
# First time: npx supabase login   (opens browser)
# Then run:   ./scripts/link-and-push.sh
# Or:        npm run supabase:link && npm run supabase:push

set -e
cd "$(dirname "$0")/.."

if [ -z "$SUPABASE_ACCESS_TOKEN" ]; then
  echo "Note: Run 'npx supabase login' first if you get auth errors."
fi

echo "Linking project gvbmhnbnvdexdvjxrhhz..."
npx supabase link --project-ref gvbmhnbnvdexdvjxrhhz

echo "Pushing migrations..."
npx supabase db push

echo "Done."
