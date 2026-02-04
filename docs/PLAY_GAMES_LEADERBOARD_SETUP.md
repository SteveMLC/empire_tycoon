# Google Play Games Leaderboard Setup

This document describes the "Highest Net Worth" leaderboard integration for Empire Tycoon: configuration, OAuth alignment, Sidekick overlay, and testing.

## Leaderboard ID and Score Format

- **Leaderboard ID (Android)**: `CgkI9ImIie0UEAIQAg` ("Highest Net Worth").
- **Score source**: Lifetime net worth = `lifetimeNetworkWorth + calculateNetWorth()` (persistent, only grows).
- **Currency (USD)**: Scores are submitted as **long integers** = 1/1,000,000th of a dollar. Submission formula: multiply dollar amount by 1,000,000. Examples: $1.00 → 1,000,000; $19.95 → 19,950,000. Conversion is in [lib/utils/leaderboard_config.dart](lib/utils/leaderboard_config.dart) via `LeaderboardConfig.toLeaderboardScore(double dollars)`. Play Games Services handles display (currency symbol and decimals by locale). Tamper protection is on for this leaderboard.

## Where IDs and Logic Live

- **Config**: [lib/utils/leaderboard_config.dart](lib/utils/leaderboard_config.dart) – `highestNetWorthIdAndroid`, `highestNetWorthIdIos`, `toLeaderboardScore()`.
- **Submit / show**: [lib/services/auth_service.dart](lib/services/auth_service.dart) – `submitHighestNetWorth(double)`, `showHighestNetWorthLeaderboard()`.
- **GameState**: [lib/models/game_state.dart](lib/models/game_state.dart) – `totalLifetimeNetWorth` getter.
- **Throttled submit**: When net worth is updated (every 30 minutes in [lib/models/game_state/update_logic.dart](lib/models/game_state/update_logic.dart)), the app submits the current lifetime net worth if the user is signed in and has games permission. Callback is wired in [lib/main.dart](lib/main.dart) after `authService.initialize()`.

## OAuth Alignment

To prevent login failures, the **OAuth 2.0 Client ID** used for Play Games sign-in must match across:

1. **Play Console** – Credentials (Web client or the client used for Play Games).
2. **android/app/google-services.json** – `oauth_client` entries.
3. **App code** – [lib/services/auth_service.dart](lib/services/auth_service.dart) `serverClientId` (and [android/app/src/main/res/values/strings.xml](android/app/src/main/res/values/strings.xml) `default_web_client_id` if used).

Current value in the app: `716473238772-mn9sh4e5c441ovk16l7oqc48le35bm9e.apps.googleusercontent.com`. Ensure Play Console has this same Web client ID configured for the game.

## Play Games Sidekick (Optional)

For production, you can enable the **Play Games Sidekick** overlay so players can view leaderboards and rewards without leaving the game:

- In **Play Console** → your app → **Release** → **Setup** → **App integrity** (or the release flow where you upload the bundle), enable **"Add Play Games Sidekick to app bundles you upload"**.
- No code changes are required; this is configuration only.

## CLIENT_RECONNECT_REQUIRED (26502)

Error **26502: CLIENT_RECONNECT_REQUIRED** means the game's connection to Google Play Games Services is stale or the auth token needs refreshing.

### Why this happens (Google reference)

- **Stale session**: The app ran in the background and the secure handshake with Google timed out.
- **Unfinished sign-in**: The user may look signed in, but the Games Services scope hasn’t been fully authorized yet.
- **OAuth mismatch**: After changing `google-services.json` or SHA-1 keys, the client may still be using the old project configuration.

### How the app fixes it

- **Before every leaderboard/achievement action**: Check `GameAuth.isSignedIn`; if false, call `GameAuth.signIn()` so the native client is connected. Known PigeonUserDetails callback errors are caught and ignored.
- **On 26502**: Force re-authentication with `GameAuth.signIn()` (via `_forcePlayGamesReauth()`), wait 500 ms, then retry the operation **once** (no unbounded recursion).

See [lib/services/auth_service.dart](lib/services/auth_service.dart): `_ensurePlayGamesClientConnected()`, `_forcePlayGamesReauth()`, `_isClientReconnectRequired()`, and the retry logic in `submitHighestNetWorth()` and `showHighestNetWorthLeaderboard()`.

### Final configuration checklist (before next build)

1. **Tester status**: Ensure the test account is under [Play Games Services → Testers](https://play.google.com/console) for the app.
2. **Currency units**: Confirm scores are multiplied by **1,000,000** (1/1,000,000th of USD) as required for the leaderboard.
3. **Publishing state**: If you changed leaderboard config, ensure it isn’t stuck in Draft—check the app’s Publishing overview and roll out if needed.

## Testing

1. **Signed-in user**: Sign in with Google Play Games from the profile screen (Game Connection section).
2. **Increase lifetime net worth**: Play until `totalLifetimeNetWorth` increases (earn money, reincorporate, etc.).
3. **Open leaderboard**: In profile, under the "Google Play Games Connected" block, tap the "Highest Net Worth" row to submit the latest score and open the native leaderboard.
4. **Verify**: Confirm your score appears on the "Highest Net Worth" leaderboard in Play Games and that the value matches the 1/1,000,000th-of-USD format (e.g. $1M net worth → score 1,000,000,000,000).
5. **Throttled submit**: Leave the app running (or play for 30+ minutes); the next net-worth update will submit again if signed in with games permission.
