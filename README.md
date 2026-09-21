# Batch Auto-Rename Bot

Telegram bot (Pyrogram/Pyrofork + MongoDB) that renames, tags and posts anime files per **batch**, and can turn a **magnet link / .torrent** into a multi-quality encode ladder (1080p → 720p → 480p).

## Features

- **Batches**: per-anime settings (thumbnail, cover image, metadata, autorename/autocaption formats, media type, anime names, Top/Bottom posts, Sub/Main channels, custom link).
- **Auto-detection** of Season / Episode / Quality from filenames.
- **Posting flow**: Backup Channel (single upload) → Sub Channel (server-side copy) → Main Channel(s) with a download button.
- **Sequence mode**: collect many files, sort them, queue them in order.
- **Auto Post mode**: route every file to one chosen batch, skipping name matching.
- **Torrent pipeline**: download the episode file only, encode 1080p → 720p (from 1080p) → 480p (from 720p), each rung size-capped, uploaded to the Backup Channel, then copied to the Sub Channel in 480p → 720p → 1080p order. Temp files are deleted as it goes.
- **Access control**: only `ADMIN` / `MODERATOR` IDs get any reply.

## Requirements

- Docker + Docker Compose
- Telegram `API_ID` / `API_HASH` ([my.telegram.org](https://my.telegram.org)) and a `BOT_TOKEN` ([@BotFather](https://t.me/BotFather))
- A MongoDB database (e.g. Atlas). Allow the server's IP in Atlas Network Access.

## Setup

```bash
git clone <your-repo-url>
cd <your-repo>
cp .env.example .env        # fill in real values
docker compose up -d --build
docker compose logs -f bot
```

Success looks like `✅ Bot started as @yourbot`.

## Environment variables (`.env`)

| Variable | Required | Description |
|---|---|---|
| `API_ID` | yes | Telegram API ID |
| `API_HASH` | yes | Telegram API hash |
| `BOT_TOKEN` | yes | Bot token from @BotFather |
| `ADMIN` | yes | Numeric Telegram user ID(s), comma/space separated. Unlocks `/bot_settings` and `/encode_settings` |
| `MODERATOR` | no | Numeric user ID(s) allowed to use the bot |
| `DB_URL` | yes | MongoDB connection string |
| `DB_NAME` | no | Default `BatchAutoRenameBot` |
| `MAX_TORRENT_SIZE_GB` | no | Default `20` |
| `DISK_HEADROOM_FACTOR` | no | Default `2.5` |
| `TORRENT_METADATA_TIMEOUT` | no | Seconds, default `300` |
| `TORRENT_STALL_TIMEOUT` | no | Seconds, default `1800` |
| `ENCODE_TIMEOUT` | no | Seconds per rung, default `43200` |

Get your numeric user ID from [@userinfobot](https://t.me/userinfobot). If `ADMIN` is empty the bot ignores every message.

## First-time bot configuration

1. Add the bot as **admin** in your channels.
2. Post `/register` inside each channel (or add by link from the menus).
3. As admin, run `/bot_settings` and set:
   - **Backup Channel** (required for torrent jobs and channel posting)
   - **Thumb/Cover Channel** (required for thumbnails / cover images)
4. `/new_batch`, then configure it via `/edit_batch`.

## Commands

| Command | Purpose |
|---|---|
| `/start`, `/help` | Help |
| `/new_batch`, `/edit_batch` | Create / edit / delete batches |
| `/auto_post`, `/stop_auto_post` | Route all files (and torrents) to one batch |
| `/ssequence`, `/esequence`, `/sequence_mode` | Sequence mode |
| `/delete_channel` | Remove a channel from the registry |
| `/bot_settings` | Backup / Thumb-Cover channels (admin) |
| `/encode_settings` | Ladder, codec, CRF, preset, size targets (admin) |
| `/torrent_check` | Show installed torrent/encode tools and CPU info |
| `/cancel`, `/cancel_job` | Cancel a prompt / a running torrent job |

**Torrents**: turn on `/auto_post`, pick a batch, then send a magnet or `.torrent`. If the name has no season/episode, add it in the same message: `S02E07 magnet:?xt=...`

## Project layout

```
bot.py               # the bot
requirements.txt
Dockerfile
docker-compose.yml
.env.example
data/                # session file (mounted volume, not committed)
downloads/           # scratch space (mounted volume, not committed)
```

## Docker notes

- **`network_mode: host`** is used on purpose. On some hosts (including GitHub Codespaces) Docker's bridge network times out connecting to Telegram; host networking fixes it.
- **`pyrofork`** is used instead of `pyrogram` (provides `send_video(cover=...)`). Do not install both.
- **Session file** lives in `./data` (`SESSION_DIR=/app/data`) so the peer cache survives rebuilds. This is separate from MongoDB.

## Common commands

```bash
docker compose logs -f bot                  # logs
docker compose restart bot                  # restart
git pull && docker compose up -d --build    # update
docker compose down                         # stop
```

## Troubleshooting

| Problem | Fix |
|---|---|
| Logs loop on `Unable to connect ... DC2` | Ensure `network_mode: host` is in `docker-compose.yml`, then `docker compose up -d --force-recreate` |
| Bot online but never replies | Your ID isn't in `ADMIN`/`MODERATOR`. Check the console: it prints the ID of ignored users |
| `no cover parameter on send_video()` | `pyrogram` is installed instead of `pyrofork`. Fix `requirements.txt`, `docker compose build --no-cache` |
| `CHANNEL_INVALID` / `PEER_ID_INVALID` | Session/peer cache lost. Keep the `./data` volume, or post `/register` in the channel again |
| Mongo connection error | Allow the server IP in Atlas Network Access; check `DB_URL` |
| Torrent job refuses to start | Set a Backup Channel; run `/torrent_check` |
| Codespace runs old code | `git pull`, then `docker compose up -d --build` |

## Security

- Never commit `.env` or `data/*.session*`.
- If a token or DB password was ever committed, rotate it (BotFather `/revoke`, Atlas user password).

## Notes

- Codespaces sleep when idle and the bot stops with them. Use a VPS for 24/7 uptime.
- Encoding is CPU-bound (`x264`/`x265`); speed depends on core count.
