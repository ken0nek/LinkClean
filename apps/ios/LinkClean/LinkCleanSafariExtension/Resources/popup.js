// Phase 0 spike (plan 004): prove the popup -> native-handler -> cleaned-URL
// round-trip on a real device. Read the active tab's URL (granted by `activeTab`
// only when the user taps the toolbar button), hand it to the Swift handler via
// native messaging, and show what comes back. No cleaning logic lives here — the
// catalog stays in Swift, so there is nothing to drift.

async function run() {
    const statusEl = document.getElementById("status");
    const resultEl = document.getElementById("result");

    try {
        const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
        const url = tab && tab.url;

        if (!url) {
            statusEl.textContent = "No link to clean on this page.";
            return;
        }

        const response = await browser.runtime.sendNativeMessage("application.id", { url });

        if (response && response.cleaned) {
            statusEl.textContent = "Cleaned link:";
            resultEl.textContent = response.cleaned;
        } else if (response && response.error) {
            statusEl.textContent = "This isn't a web link.";
        } else {
            statusEl.textContent = "No response from LinkClean.";
        }
    } catch (error) {
        statusEl.textContent = "Error: " + (error && error.message ? error.message : String(error));
    }
}

document.addEventListener("DOMContentLoaded", run);
