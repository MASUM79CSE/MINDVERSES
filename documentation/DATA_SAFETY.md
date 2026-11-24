# MINDVERSE — Google Play Data Safety Declaration

Use this guide when filling out the Data Safety section in Google Play Console.

## Data Collection Summary

**Does your app collect or share any user data?**  
✅ **No** — MINDVERSE does not collect or share any user data.

### Detailed Answers for Play Console

When asked about data practices, select the following:

| Question | Answer |
|----------|--------|
| Does your app collect or share any user data? | **No** |
| Data collected | *(None — leave all options unchecked)* |
| Data shared | *(None — leave all options unchecked)* |
| Is the data collection mandatory? | *(N/A — no data collected)* |
| Can users request that data be deleted? | *(N/A — no data collected)* |

## Data Safety Practices

| Practice | Status |
|----------|--------|
| Data is encrypted in transit | ✅ Yes (N/A — no data transmitted) |
| Data can be deleted by the user | ✅ Yes — "Reset All Progress" in settings |
| Data is not collected | ✅ Yes |

## App Permissions

MINDVERSE requests **no special permissions** beyond those required by the Flutter framework:

- **No internet permission** — The app is fully offline.
- **No location access** — No location data is used.
- **No camera/microphone access** — No media capture.
- **No contacts/calendar access** — No personal data access.
- **No storage access** — Game data is stored in app-private storage only.

## Third-Party Services

MINDVERSE currently uses **no third-party services**:

- ❌ No analytics SDKs
- ❌ No advertising SDKs
- ❌ No crash reporting SDKs
- ❌ No cloud sync services
- ❌ No social media integrations

**Note:** If in-app purchases are enabled via Google Play Billing Library, Google Play handles payment processing. No payment data is collected by the app.

## Contact Information for Data Safety Questions

**Developer:** Mir Md. Masum  
**Email:** mirmasum@mail.com  
**Privacy Policy URL:** (Provide the hosted URL of the Privacy Policy)

## Compliance Notes

- **GDPR:** Compliant — no personal data collected.
- **CCPA:** Compliant — no personal data collected.
- **COPPA:** Compliant — no data collected from children.
- **Google Play Policies:** Compliant — offline app with no data collection.

## Hosting the Privacy Policy

Google Play requires a publicly accessible Privacy Policy URL. Options:

1. **GitHub Pages:** Host the `PRIVACY_POLICY.md` file from this repository.
2. **Google Sites:** Create a simple page with the privacy policy content.
3. **Any web hosting:** Upload the privacy policy to any accessible URL.

The URL must be provided in the Play Console app listing under "Contact information."
