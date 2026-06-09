<!--
DRAFT — review before publishing (ideally skim with the App Store / GDPR lens once).
Publish at: https://ken0nek.com/apps/linkclean/privacy-policy/
Before publishing: set the effective date, confirm the support email, and confirm the
TelemetryDeck privacy-policy link. This is the gate for App Store metadata (TODO #7 → #6).
-->

# LinkClean Privacy Policy

**Last updated: [set on publish — drafted 8 June 2026]**

LinkClean removes tracking parameters from links. Privacy isn't a feature we bolted on — it's the entire point of the app. This policy explains, plainly, what LinkClean does and does not do with your data.

**The short version:** the links you clean never leave your device. LinkClean processes them entirely on-device and never sends them to us or anyone else. The only data the app transmits is anonymous, aggregate usage analytics that can't be tied to you or to any link you've cleaned.

## What we never collect

LinkClean never collects, transmits, or stores:

- The URLs or links you clean — not the full link, not the domain, not the query string, not even a hashed version
- Anything on your clipboard
- Text you type into the search box in History
- The names of any custom parameters you add
- Page titles or preview images of the links you clean

None of the above ever reaches our analytics or any server.

## On-device processing

The actual cleaning — detecting and stripping tracking parameters — happens entirely on your device using local logic. No network connection is required or used to clean a link.

## When LinkClean connects to the internet

There are only two cases:

1. **Fetching a link's title and preview.** When you use the **Copy as Markdown** action, or when LinkClean shows a title/preview for a link in your History, the app connects **directly to that link's website** to read its title and preview image. This is a direct connection from your device to the website — it does not pass through any LinkClean server or third party. LinkClean requests the **already-cleaned** link, so tracking parameters are never sent over the network. Any title or preview retrieved this way is stored only on your device, in your History.

2. **Anonymous analytics.** Described below.

## Analytics

To understand which features people use and where the app can improve, LinkClean uses [TelemetryDeck](https://telemetrydeck.com), a privacy-focused analytics service. TelemetryDeck is designed so that the data it receives cannot be traced back to an individual.

**What is sent:**

- An anonymized, untraceable identifier generated per app installation (salted and hashed on your device before transmission, so even TelemetryDeck cannot reverse it)
- Names of actions you take in the app, such as "a link was cleaned" or "settings opened" — never the content involved
- Bucketed, rounded counts — for example, roughly how many trackers a clean removed (exact values are never sent)
- Which *categories* of built-in trackers were involved (such as "utm" or "ads"), and the public, well-known names of trackers from our built-in tracker list — never the names of parameters you added yourself
- Standard device metadata: app version, operating-system version, device model, and region/locale
- A timestamp rounded to the nearest hour

**What is never sent through analytics:** your links, domains, query strings, clipboard contents, search text, custom parameter names, page titles, or preview images.

TelemetryDeck does **not** receive or store IP addresses, and LinkClean does not use cookies or cross-app tracking technologies. For details on how TelemetryDeck handles data, see [TelemetryDeck's privacy policy](https://telemetrydeck.com/privacy/).

## Tracking

LinkClean does **not** track you. We do not use your data — or any third party's data — to follow you across apps or websites, and we do not show ads. No App Tracking Transparency prompt is shown because there is nothing to track.

## Data storage and retention

- **Your History** (cleaned links, and any titles or previews) is stored **only on your device**. You can delete individual entries or clear your entire History at any time in the app, and disabling "Save History" removes saved entries. Deleting the app removes all of it.
- **Analytics data** is anonymous and aggregate; because it isn't linked to you, individual entries can't be identified or removed.

## Your choices

LinkClean has no accounts and asks for no personal information. Because analytics data is fully anonymized and cannot be linked to you or your device, there is no personal data for us to access, export, or delete on your behalf. This version of LinkClean does not include an in-app analytics toggle. If you have any questions or concerns, please reach out using the contact details below.

## Children's privacy

LinkClean does not knowingly collect any personal information from anyone, including children.

## Legal basis (EEA/UK users)

Where the GDPR applies, we rely on our legitimate interest in collecting anonymized, non-identifying usage data to maintain and improve the app (Art. 6(1)(f) GDPR). No personal data is processed for this purpose.

## Changes to this policy

If we change how LinkClean handles data, we'll update this page and revise the "Last updated" date above. Material changes will be reflected before they take effect.

## Contact

Questions about this policy or your privacy? Contact us at **[your support email — e.g. privacy@ken0nek.com]**.
