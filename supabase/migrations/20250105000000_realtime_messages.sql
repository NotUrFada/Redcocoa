-- Enable realtime for messages table so chat updates in real time
alter publication supabase_realtime add table public.messages;
