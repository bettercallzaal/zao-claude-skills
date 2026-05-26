# Research by Topic

Use this to quickly find if a topic has already been researched.

## Activity Feed APIs

_No research yet — priority area for Plan 4_

Research needed for **both** `bettercallzaal` and `ohnahji` on each platform:

- **GitHub API** (REST + GraphQL) — commits, PRs, repos, stars → primarily bettercallzaal
- **Twitter/X API v2** — tweets, timeline (note: API access tiers) → both creators
- **YouTube Data API v3** — videos, playlists, channel activity → both creators
- **Spotify Web API** — currently playing, recent tracks, playlists → both creators (Ohnahji is an artist — check artist endpoint vs listener endpoint)
- **Twitch API (Helix)** — stream status, VODs, clips → both creators (handles: `bettercallzaal`, `ohnahji`)
- **Podcast RSS feeds** — auto-pull episode data → both creators
- **NFT/Web3** — OpenSea API, wallet activity, on-chain events → both creators
- **Music-specific platforms** — SoundCloud, Audius, Bandcamp (Ohnahji as artist releasing music)

## Embeds & Streaming

_No research yet_

Topics to research (needed for both bettercallzaal and ohnahji):
- Twitch embed iframe (already implemented — `parent` param requirements)
- YouTube embed / `youtube-nocookie.com`
- Spotify Web Playback SDK vs embed widget (artist vs listener view)
- Live stream status detection (polling vs webhooks) — is either creator currently live?
- SoundCloud / Bandcamp embeds for Ohnahji's music releases

## Next.js & Infrastructure

_No research yet_

Topics to research:
- Next.js 16 App Router patterns (ISR, streaming, server components)
- Vercel Edge Functions vs Node.js runtime trade-offs
- Neon PostgreSQL connection pooling (PgBouncer) for serverless
- Prisma + Neon best practices (connection limits, pooled vs direct URL)
- Vercel Blob storage for member avatars

## Auth & Security

_No research yet_

Topics to research:
- NextAuth v5 (Auth.js beta) patterns and migration from v4
- GitHub OAuth scopes needed for activity feeds
- Rate limiting strategies (Vercel KV / Upstash)
- API key storage and rotation for member integrations

## Content & Media

_No research yet_

Topics to research:
- OpenGraph / oEmbed for link previews
- Image optimization (next/image + Vercel Blob)
- Video thumbnail fetching from YouTube/Twitch

## NFT & Web3

_No research yet_

Topics to research:
- OpenSea API (reading wallet NFTs without RPC calls)
- Alchemy/Moralis for wallet activity
- ENS resolution
- Displaying on-chain activity without requiring wallet connection

## UI & Design

_No research yet_

Topics to research:
- Tailwind CSS v4 config patterns (globals.css vs config file)
- Split-theme / dual-brand design patterns
- Dark mode with dual color palettes
- Animation libraries compatible with Next.js 16 (Framer Motion, etc.)
