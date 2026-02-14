-- Scientific matching metrics on profiles (Big Five personality, attachment style)
alter table public.profiles
  add column if not exists big_five_openness int,
  add column if not exists big_five_conscientiousness int,
  add column if not exists big_five_extraversion int,
  add column if not exists big_five_agreeableness int,
  add column if not exists big_five_neuroticism int,
  add column if not exists attachment_style text;

comment on column public.profiles.big_five_openness is 'Big Five Openness 0-100';
comment on column public.profiles.big_five_conscientiousness is 'Big Five Conscientiousness 0-100';
comment on column public.profiles.big_five_extraversion is 'Big Five Extraversion 0-100';
comment on column public.profiles.big_five_agreeableness is 'Big Five Agreeableness 0-100';
comment on column public.profiles.big_five_neuroticism is 'Big Five Neuroticism 0-100';
comment on column public.profiles.attachment_style is 'Attachment style: Secure, Anxious, Avoidant, Anxious-Avoidant';
