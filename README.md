# BetterRhythm

A Telegram bot that plans your day and learns how you really work.

You describe your day in one message. The bot builds a time-blocked schedule from your own history (how much longer tasks take than you estimate, when you focus best), your Google Calendar and the weather, writes it into a dedicated Google Calendar, and every evening report makes the next plan more realistic.

Built with n8n (self-hosted in Docker), Telegram, OpenRouter, Google Sheets, Google Calendar, Open-Meteo and JavaScript.

## Commands

| Command | Example | What happens |
| --- | --- | --- |
| `/plan` | `/plan finish report (1h30), emails, run (45 min), call mum 19:00` | Time-blocked plan for today (or tomorrow after 17:00), written to the calendar |
| `/replan` | `/replan dentist moved to 17:00` | Rebuilds the last plan around the change |
| `/done` | `/done report 9-12, emails 12-12:30, run skipped` | Compares plan and reality, updates the time factor and peak hours |
| `/help` | `/help` | List of commands |

## Repository layout

```
docker-compose.yml       n8n (pinned 2.38.7) + Postgres 16 (healthcheck) + Cloudflare tunnel
.env.example             template for the secrets (copy to .env, never commit .env)
db/init.sql              Postgres schema + 5-day demo history, loaded on first start
workflows/               the 3 n8n workflows exported as JSON
sheet-templates/         CSV templates for the Google Sheet tabs (profile, tasks, signals, errors)
docs/                    architecture proposal (PDF) and screenshots
```

## Setup: from clone to running

**Requirements:** Docker Desktop, a Telegram bot token (BotFather), an OpenRouter API key, a Google Cloud service account with the Sheets and Calendar APIs enabled.

1. **Clone**
   ```
   git clone https://github.com/<your-user>/betterrhythm.git
   cd betterrhythm
   ```

2. **Create `.env`**
   ```
   cp .env.example .env
   ```
   Fill in every value. `N8N_ENCRYPTION_KEY` must stay the same for the life of the `n8n_data` volume, because n8n uses it to encrypt saved credentials. On an existing install, read it with:
   ```
   docker run --rm -v n8n_data:/data alpine cat /data/config
   ```
   On a fresh install, generate one with `openssl rand -hex 32`.

3. **Create the n8n volume** (fresh install only; an existing `n8n_data` volume is reused as is)
   ```
   docker volume create n8n_data
   ```

4. **Start the tunnel first, to get the public address**
   ```
   docker compose up -d tunnel
   docker compose logs tunnel | grep trycloudflare.com
   ```
   Put that address in `WEBHOOK_URL` in `.env` (with a trailing `/`). The tunnel uses HTTP/2, which works on networks that block QUIC.

5. **Start everything**
   ```
   docker compose up -d
   docker compose ps
   ```
   `postgres` must show `healthy`; n8n only starts once it is. The editor is at http://localhost:5678.

6. **Import the workflows** (fresh install only): in n8n, *Create workflow → ⋯ → Import from file*, for each file in `workflows/`. Then create the credentials (Telegram, OpenRouter, Google service account), select them in the nodes, set the Sheet and calendar IDs, and publish SW-A, SW-B, then Main. In Main's settings, set *Error Workflow* to SW-B.

7. **Google Sheet:** create a sheet with four tabs named `profile`, `tasks`, `signals`, `errors`, import the matching CSV from `sheet-templates/`, and share it with the service account.

Stop with `docker compose down`. Volumes are kept, so workflows, credentials and data survive a `down` then `up`.

## Environment variables

| Variable | Used by | Purpose |
| --- | --- | --- |
| `N8N_ENCRYPTION_KEY` | n8n | Encrypts stored credentials; must match the key in `n8n_data` |
| `WEBHOOK_URL` | n8n | Public address Telegram calls (the tunnel address) |
| `TZ` | n8n, Postgres | Time zone used for planning (Europe/Paris) |
| `POSTGRES_USER`, `POSTGRES_PASSWORD`, `POSTGRES_DB` | Postgres | Database credentials |

## How to test

1. Send `/help` to the bot: the command list comes back within a few seconds (tunnel and webhook work).
2. Send `/plan finish report (1h30), emails, run (45 min), call mum 19:00`: a time-blocked plan comes back, and the blocks appear in the BetterRhythm calendar.
3. Send `/done report 9-12, emails 12-12:30, run skipped`: the reply shows the new time factor, and the `profile` tab is updated.
4. Send `/plan` again with the same tasks: blocks are longer (the learning loop).
5. Send `hello`: the usage message comes back (invalid input handled).
6. Error path: change the Open-Meteo URL to an invalid one and send `/plan`. The plan still arrives without weather; a crash in a workflow triggers the Error Workflow, which sends an alert with the workflow name and execution link.

Check *Executions* in n8n: recent runs are green.

## Error handling

- Retry On Fail ×3 on every HTTP, AI and Sheets node.
- Planning continues without weather or calendar if those APIs fail.
- The AI output is checked by a Structured Output Parser and a Validate node; if the AI fails, rules build the plan from the raw text.
- If the Writer AI fails, a Code node writes a plain plan.
- Expected failures go to Sub-workflow B, which logs them and replies to the user; unexpected crashes trigger the Error Workflow (Error Trigger), which alerts the developer.

## Screenshots

See `docs/screenshots/`.

## Secrets

No token, key or password is committed. Real values live only in `.env` (ignored by Git) and in n8n's encrypted credential store.
