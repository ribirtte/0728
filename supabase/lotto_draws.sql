create extension if not exists pgcrypto;

create table if not exists public.lotto_draws (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  birth_date date not null,
  name text,
  question text,
  zodiac_key text not null,
  zodiac_name text not null,
  lucky_numbers int[] not null,
  explanation text not null,
  constellation_svg text,
  model text not null default 'gpt-5.4-mini'
);

create index if not exists lotto_draws_created_at_idx on public.lotto_draws (created_at desc);
create index if not exists lotto_draws_birth_date_idx on public.lotto_draws (birth_date);
create index if not exists lotto_draws_zodiac_key_idx on public.lotto_draws (zodiac_key);

