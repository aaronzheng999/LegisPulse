# LegisPulse

LegisPulse tracks Georgia legislative bills and provides AI-generated bill analysis.

## Current Capabilities

- Sync Georgia bills from LegiScan
- Show newest bills first (higher bill number first)
- Search by bill number/text with improved exact matching (e.g. `HB10` and `HB 10`)
- Track/untrack bills
- Open direct bill PDFs (uses LegiScan `getBillText` flow when available)
- Fetch and display sponsor lists (cards + details)
- Generate and regenerate AI summaries from bill text context
- Persist app data locally in browser `localStorage`

## Tech Stack

- React + Vite
- Tailwind + Radix UI components
- Local mock API layer in `src/api/apiClient.js`

## Environment Variables

Create a local `.env` (or `.env.local`) file:

```env
VITE_LEGISCAN_API_KEY=your_legiscan_key
VITE_OPENAI_API_KEY=your_openai_key

# Optional
VITE_OPENAI_MODEL=gpt-4o-mini
VITE_OPENAI_BASE_URL=https://api.openai.com/v1
```

Notes:

- `.env` is gitignored in this repo.
- Keep real keys out of GitHub.

## Local Development

```bash
npm install
npm run dev
```

Other scripts:

```bash
npm run build
npm run preview
npm run lint
npm run lint:fix
npm run typecheck
```

## Deploying on Render

Use **Environment Variables** (not Secret Files) for this project.

Add these in Render service settings:

- `VITE_LEGISCAN_API_KEY`
- `VITE_OPENAI_API_KEY`
- optional `VITE_OPENAI_MODEL`
- optional `VITE_OPENAI_BASE_URL`

Then trigger **Save, rebuild, and deploy**.

## Security Warning (Important)

Because this is a Vite client app, any `VITE_*` variable is bundled into client code and can be inspected by users.

For production-grade secrecy (especially OpenAI keys), move AI calls to a backend/serverless endpoint and keep non-`VITE` secrets server-side.

## Data Model Behavior

- Bill, user, tracking, notification, and tweet data are stored in browser storage via `src/api/apiClient.js`.
- Sync replaces local bill records with fresh LegiScan data.
- AI-generated summary text is saved onto each bill (`summary`, `changes_analysis`).

## Project Structure (high level)

- `src/pages/Dashboard.jsx` – main bill list/search/filter flow
- `src/components/bills/BillDetailsModal.jsx` – bill details + AI analysis
- `src/components/bills/BillSyncButton.jsx` – LegiScan sync action
- `src/services/legiscan.js` – LegiScan fetch/parsing helpers
- `src/api/apiClient.js` – local data API + LLM integration wrapper
