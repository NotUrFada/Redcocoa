-- Ensure matches and messages can be created when chatting
-- Recreate policies in case they were dropped or misconfigured
DROP POLICY IF EXISTS "Users can create matches they are part of" ON public.matches;
DROP POLICY IF EXISTS "Users can insert matches" ON public.matches;
CREATE POLICY "Users can create matches they are part of"
  ON public.matches FOR INSERT
  WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

DROP POLICY IF EXISTS "Users can send messages in their matches" ON public.messages;
CREATE POLICY "Users can send messages in their matches" ON public.messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id
    AND EXISTS (
      SELECT 1 FROM public.matches m
      WHERE m.id = match_id AND (m.user1_id = auth.uid() OR m.user2_id = auth.uid())
    )
  );
