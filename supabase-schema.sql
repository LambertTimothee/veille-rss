-- ══════════════════════════════════════════════════════════
-- VEILLE RSS — Schéma Supabase
-- À coller dans : Supabase Dashboard → SQL Editor → New query
-- ══════════════════════════════════════════════════════════

-- 1. CATÉGORIES
create table if not exists categories (
  id        text primary key,
  name      text not null,
  color     text not null default '#c8b89a',
  position  integer default 0,
  created_at timestamptz default now()
);

-- 2. SOURCES (flux RSS + sources web)
create table if not exists sources (
  id          text primary key,
  name        text not null,
  url         text not null,
  type        text not null check (type in ('rss','web')),
  cat_id      text references categories(id) on delete set null,
  -- Web source only
  description text,
  freq        integer default 1440,
  last_fetch  timestamptz,
  last_hash   text,
  last_method text,
  extracted_items jsonb,
  created_at  timestamptz default now()
);

-- 3. ARTICLES
create table if not exists articles (
  id            text primary key,
  title         text not null,
  link          text not null,
  summary       text default '',
  published_at  timestamptz default now(),
  source_id     text references sources(id) on delete cascade,
  cat_id        text references categories(id) on delete set null,
  type          text default 'rss',
  extract_method text,
  created_at    timestamptz default now()
);

-- 4. ÉTAT DE LECTURE (par article)
create table if not exists article_states (
  article_id  text primary key references articles(id) on delete cascade,
  is_read     boolean default false,
  is_saved    boolean default false,
  ai_summary  text,
  updated_at  timestamptz default now()
);

-- 5. CONFIG UTILISATEUR (clé/valeur)
create table if not exists user_config (
  key   text primary key,
  value text
);

-- ── INDEX pour les requêtes fréquentes ──
create index if not exists articles_published_idx on articles(published_at desc);
create index if not exists articles_source_idx    on articles(source_id);
create index if not exists articles_cat_idx       on articles(cat_id);
create index if not exists states_read_idx        on article_states(is_read);
create index if not exists states_saved_idx       on article_states(is_saved);

-- ══════════════════════════════════════════════════════════
-- ROW LEVEL SECURITY
-- Par défaut Supabase bloque tout. On autorise tout
-- avec la clé anon (usage personnel, app côté client).
-- ══════════════════════════════════════════════════════════
alter table categories    enable row level security;
alter table sources        enable row level security;
alter table articles       enable row level security;
alter table article_states enable row level security;
alter table user_config    enable row level security;

-- Policies : accès complet via anon key (usage solo)
create policy "allow all categories"    on categories    for all using (true) with check (true);
create policy "allow all sources"       on sources        for all using (true) with check (true);
create policy "allow all articles"      on articles       for all using (true) with check (true);
create policy "allow all states"        on article_states for all using (true) with check (true);
create policy "allow all config"        on user_config    for all using (true) with check (true);

-- ══════════════════════════════════════════════════════════
-- DONNÉES PAR DÉFAUT
-- ══════════════════════════════════════════════════════════
insert into categories (id, name, color, position) values
  ('tech',    'Technologie',             '#7aa2c8', 0),
  ('ia',      'Intelligence artificielle','#b07ac8', 1),
  ('design',  'Design',                  '#7ac89a', 2),
  ('actu',    'Actualités',              '#c87a7a', 3),
  ('science', 'Sciences',                '#c8b89a', 4)
on conflict (id) do nothing;

insert into sources (id, name, url, type, cat_id) values
  ('feed_hn',      'Hacker News',      'https://news.ycombinator.com/rss',          'rss', 'tech'),
  ('feed_smashing','Smashing Magazine','https://www.smashingmagazine.com/feed/',     'rss', 'design'),
  ('feed_mit',     'MIT Tech Review',  'https://www.technologyreview.com/feed/',     'rss', 'ia')
on conflict (id) do nothing;
