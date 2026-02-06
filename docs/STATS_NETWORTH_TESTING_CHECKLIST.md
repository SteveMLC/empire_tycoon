# Stats Page & Net Worth – Testing Checklist

Use this after the stats/net worth overhaul to confirm behavior.

## Gaps Addressed in Code Review

1. **Prune after load** – After loading both `persistentNetWorthHistory` and `runNetWorthHistory` from save, we now call `_prunePersistentNetWorthHistory()` so the 7-day window and 50-entry cap are applied immediately (no oversized maps until the next 30‑min tick).

2. **Reincorporation snapshot** – Right before reset, we record the current net worth into `persistentNetWorthHistory` so the lifetime chart shows the peak at the moment of reincorporation.

3. **Run history seed after reincorporation** – After the reset completes, we add one entry to `runNetWorthHistory` with the new run’s starting net worth so “Current Run” has at least one point and doesn’t show empty.

## Manual Test Scenarios

### 1. Fresh / first open

- Open app (new install or cleared data).
- Go to Stats.
- **Expect:** Net worth card shows “Net Worth – Lifetime” (or “Current Run” if toggled), subtitle text, and either “No net worth history available yet” or a single “Tracking started” message once the first snapshot exists (after load bootstrap or first 30‑min tick).
- Toggle between **Lifetime** and **Current Run** – both should behave (empty or one point).

### 2. Play and return

- Play for a bit (earn money, buy something).
- Leave app (or background) and come back (or trigger a save/load).
- Open Stats.
- **Expect:** Lifetime (and run) history still present; if load ran, bootstrap may have added a point if history was empty. Chart shows at least one point; after 30+ minutes of play, multiple points.

### 3. Reincorporation

- Reach reincorporation threshold and reincorporate.
- Open Stats.
- **Lifetime:** Should show history including the pre‑reset peak (new point at reincorporation time) and then the next point(s) as the new run progresses.
- **Current Run:** Should show only the new run: one point (starting net worth) at first, then more points every 30 minutes.
- Play again for a while, then open Stats again.
- **Expect:** Lifetime keeps growing; Current Run only shows growth since last reincorporation.

### 4. Save / load

- Play, then force a save (e.g. background and wait for autosave, or use in‑app save if any).
- Fully close and reopen app (or clear process and reopen).
- **Expect:** Both net worth histories restored; chart(s) look correct; no duplicate or missing segments. Pruning (7 days, 50 entries) should have been applied on load.

### 5. Edge cases

- **Single data point:** Chart shows “Tracking started” and short message instead of a flat line.
- **Empty run after reincorporation:** “Current Run” shows one point (starting net worth) right after reincorporation.
- **Toggle and scroll:** Switching Lifetime ↔ Current Run updates title, subtitle, and data; no crash or stale data.

## Quick Run (device or emulator)

```bash
flutter run
```

Then: open Stats tab → check net worth card (title, toggle, empty/single/multi point) → play → reincorporate (if available) → check again.

## Notes

- Net worth is sampled every **30 minutes** in the update loop (and at reincorporation for lifetime).
- Old saves without `runNetWorthHistory` get `{}` on load and are bootstrapped with one point if still empty after prune.
- `persistentNetWorthHistory` is never cleared by reincorporation; only `runNetWorthHistory` is cleared and then seeded with the new run’s first net worth.
