# Calculator

**Mission:** A strictly offline, privacy-first simple Calculator application for Android that supports basic arithmetic operations.

## Tech Decisions
- **Kotlin + Jetpack Compose:** Modern Android development stack for a reactive UI.
- **No External Libraries:** Kept dependencies minimal (only standard AndroidX/Jetpack libraries) to ensure privacy and small app size.
- **Local Logic:** All calculations are performed locally on the device.

## Manual Tasks
- **Verify UI Layout:** Check that the buttons are evenly spaced and the display area handles long numbers correctly on different screen sizes.
- **Check Dark Mode:** Ensure the UI colors (DarkGray background, White text) look good in both system light and dark modes (the app forces its own dark-ish theme).

## For Future Agents
- **Icon:** A simple generated icon is used. Might want to replace with a more polished vector asset if refined.
- **Theme:** The theme is currently defined inline/locally for simplicity. Scaling up might require moving back to a dedicated `Theme.kt`.
