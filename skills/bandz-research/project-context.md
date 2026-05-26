# B&Z Builds Project Context

## What B&Z Builds Is

A "build in public" hub co-owned by two creators: **bettercallzaal** (developer/ZAO community builder) and **Ohnahji** (artist/creator). The platform showcases both of their journeys side-by-side with a split-theme design — ZAO/bettercallzaal on the left, Ohnahji on the right. Activity feeds aggregate both creators' output across GitHub, Twitter/X, YouTube, Spotify, Twitch, podcasts, and NFT/Web3. Research should serve both creators equally.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Next.js 16.2 (App Router) + React 19 |
| Language | TypeScript 5 (strict mode) |
| Styling | Tailwind CSS v4 (config in globals.css, no tailwind.config.ts) |
| Auth | NextAuth v5 (Auth.js beta 5.0.0-beta.30) — GitHub OAuth only |
| Database | Neon PostgreSQL (via Vercel Storage integration) |
| ORM | Prisma v6.19.2 |
| Deployment | Vercel |
| Image Storage | Vercel Blob (planned) |

## Key Architecture Decisions

- Monolithic Next.js app (App Router)
- Admin-only auth: GitHub OAuth checks username against `Member.platformLinks.github` in DB
- Two founding admins: `bettercallzaal` and `Ohnahji` (Ohnahji's GitHub handle TBD)
- Middleware uses `getToken` (next-auth/jwt) directly — NOT `auth` wrapper — to stay under Vercel 1MB edge function limit
- Prisma migrations run via `prisma migrate deploy` in the Vercel build script
- Split-theme design: ZAO colors (#141e27 navy + #e0ddaa cream) on left, Ohnahji colors (#FE517E pink + #3C0010 burgundy + #F1C40F gold) on right

## Data Models

- **Member** — platform profiles with `platformLinks` JSON (github, twitter, youtube, spotify, twitch, etc.)
- **MemberIntegration** — OAuth tokens/API keys per member per platform
- **Content** — curated content pieces (video, music, article, clip, nft)
- **FeedItem** — auto-pulled activity (tweet, github_commit, youtube_video, spotify_track, etc.)
- **LearningTrack / Lesson** — structured learning content
- **Event** — IRL/virtual events

## The Two Creators

Both are co-founders, co-admins, and the primary subjects of the platform:

| | bettercallzaal | Ohnahji |
|--|--|--|
| **Role** | Developer, ZAO community builder | Artist, creator |
| **Theme** | ZAO: #141e27 navy + #e0ddaa cream | #FE517E pink + #3C0010 burgundy + #F1C40F gold |
| **Side** | Left | Right |
| **Platforms** | GitHub, Twitch, Twitter/X, YouTube, Spotify | Twitch, Twitter/X, YouTube, Spotify, music platforms |
| **Handle** | `bettercallzaal` on all platforms | `ohnahji` on all platforms |

**Important:** Platform usernames are `bettercallzaal` and `ohnahji` (lowercase) across GitHub, Twitch, Twitter/X, YouTube, Spotify.

## Community

- Public-facing site: https://b-zbuild-2.vercel.app
- GitHub repo: https://github.com/bettercallzaal/B-ZBUILD2
- Platform philosophy: Build in public, curate everything manually, admin controls who appears

## Roadmap Phases (7 Plans)

1. **Foundation** — auth, DB, admin shell ✅ done
2. **Members & Profiles** — member pages, bio, social links
3. **Content Curation** — admin content management
4. **Activity Feeds** — auto-pull from GitHub, Twitter, YouTube, Spotify, Twitch
5. **Learning Tracks** — structured curriculum
6. **Events & Homepage Polish** — event listings, homepage refinement
7. **Visual Polish** — animations, final theming

## Important Rules

- Admin UI is under `/admin/*` — protected by middleware
- All public content is curated by admins (no user-generated content from public)
- Twitch embed parent domain: `b-zbuild-2.vercel.app`
- Never import Prisma in middleware (edge function size limit)
- NextAuth v5 API: use `auth()` not `getServerSession()`, handlers export GET/POST
