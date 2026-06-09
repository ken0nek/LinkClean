# App Store Connect Metadata — LinkClean 1.0.0

Draft copy for the App Store listing. Character limits noted; counts are current.
English (primary). No localization for 1.0.0 (per TODO), so this is the only locale.

---

## App Name — max 30

```
LinkClean – URL Cleaner
```
(23 chars.) Brand + tagline, matching the house style (cf. `Whyzard – Learn Together`). The tagline adds "URL" and "Cleaner" — high-value search terms the subtitle doesn't cover. Fallback: plain `LinkClean` (9 chars) if you prefer just the brand. (Set in `fastlane/metadata/en-US/name.txt`.)

## Subtitle — max 30

```
Remove trackers from links
```
(26 chars.) Recommended. Alternatives: `Clean tracking junk from URLs` (29) · `Strip trackers from your links` (30).

## Promotional Text — max 170 (editable anytime without review)

```
Strip utm_source, fbclid, and dozens more tracking tags from any link — right in your Share Sheet. See what's removed, copy a clean link, share it privately.
```
(157 chars.) Use this slot for timely messages later (sales, new features) since it updates without a review.

## Description — max 4000

```
LinkClean strips tracking junk from any link, so what you share is the clean destination — not a trail of who shared it, from where, and when.

Paste a link and LinkClean instantly removes tracking parameters like utm_source, fbclid, and dozens more. You see exactly what was taken out and what's left, then copy a clean link with a single tap.

CLEAN AS YOU SHARE
Add LinkClean to your Share Sheet and clean a link without leaving the app you're in:
• Clean Link — copies the tidied URL, ready to paste
• Copy as Markdown — copies the link as a Markdown [title](url), with the page title filled in for you

SEE WHAT YOU'RE REMOVING
Every clean shows a calm summary of how many trackers were removed — tap to see exactly which ones. Anything left behind is shown too, and you can tap a leftover parameter to strip it from now on.

MAKE IT YOURS
• Turn the built-in tracker list on or off
• Add your own parameters to always remove
• Keep a searchable History of everything you've cleaned — ready to copy, share, re-clean, or reopen

PRIVATE BY DESIGN
Cleaning happens entirely on your device. The links you clean are never sent to us or to anyone else. LinkClean uses only anonymous, aggregate analytics to learn which features matter — never the contents of your links. See the privacy policy for the full picture.

Built for iOS 26 with a fast, native, Liquid Glass interface.

—

Privacy Policy: https://ken0nek.com/apps/linkclean/privacy-policy/
```
(~1,450 chars — room to expand if you want testimonials/FAQ later.) The Privacy Policy line is also surfaced in the dedicated App Store Connect Privacy Policy URL field, so it's optional in the body; it's kept here because privacy is LinkClean's core pitch. Drop it if you'd rather not duplicate the link.

## Keywords — max 100, comma-separated, NO spaces

```
utm,fbclid,gclid,url,privacy,tracking,share,markdown,copy,paste,parameter,query,redirect,utm_source
```
(99 chars — 1 to spare.) `gclid` (Google Ads click ID) was added next to its siblings `fbclid`/`utm` — it's an active default tracker LinkClean removes (`TrackingParameters.swift`, `ads` section), so it's literally true and high-intent, a better fill than generic terms like `deeplink`/`clipboard`. Words already in the App Name ("link", "clean") and Subtitle ("remove", "trackers", "from", "links") are indexed automatically — they're intentionally omitted here to avoid wasting space. Apple stems plurals, so `tracker`/`trackers` are covered.

## What's New (release notes) — max 4000

```
Welcome to LinkClean 1.0!

• Clean tracking parameters from any link
• Clean Link and Copy-as-Markdown actions, right in the Share Sheet
• See exactly what was removed — and tap a leftover parameter to remove it for good
• A searchable History of everything you've cleaned
• 100% on-device cleaning — your links never leave your device

Thanks for trying LinkClean. Feedback is always welcome.
```

## URLs

| Field | Value | Notes |
|---|---|---|
| Support URL | `https://github.com/ken0nek` | Required. |
| Privacy Policy URL | `https://ken0nek.com/apps/linkclean/privacy-policy/` | **Must be live before you can submit** (TODO #7). Currently 404s. |

Marketing URL is intentionally omitted (it's optional in App Store Connect). **Open decision —** whether to buy `linkclean.app` (cf. `whyzard.app`): tracked in [docs/TODO.md](../TODO.md). If purchased, revisit these URLs.

## Categories

- **Primary:** Utilities
- **Secondary:** Productivity

## Age Rating

**4+.** In the questionnaire, "Unrestricted Web Access" = **No** — LinkClean opens links in the system browser and reads page titles, but embeds no in-app web browser. No other content descriptors apply.

## Still needed (not copy — your tasks)

- **Screenshots** — iPhone 6.9" and iPad 13" required sizes (TODO #5). I can generate raw simulator captures of the key flows when you want.
- **App icon** — already done (1024×1024 marketing icon comes from the asset catalog).
- **Build** — archive & upload via Xcode, then attach in ASC.
