# AquaPulse

SwiftUI iOS water reminder and consistency tracker. All logs stay on the iPhone. Sign in with Apple is optional.

Site: https://aquapulse-tau.vercel.app  
Privacy: https://aquapulse-tau.vercel.app/privacy  
Terms: https://aquapulse-tau.vercel.app/terms  
Support: https://aquapulse-tau.vercel.app/support

The app includes:

- First-run onboarding (name, goal, optional extra rituals)
- Native `TabView` (system Liquid Glass tab pill on iOS 26)
- Daily hydration goal, glass size, and sequential glass check-in
- Consistency rituals you add yourself (stretch, read, walk, custom)
- Weekly board that only fills on days you complete
- Local reminders
- Profile: Sign in with Apple, name, photo, delete local data

## Run

Open `AquaPulse.xcodeproj` in Xcode (team `337LP258Y2`) and run the `AquaPulse` scheme.

Optional launch arguments:

- `-screen rituals` / `week` / `glasses` / `profile`
- Debug only: `-seedSession` finishes onboarding with a real 3-glass start (not shipped in Release)

See [STORE_LISTING.md](STORE_LISTING.md) for App Store Connect copy.
