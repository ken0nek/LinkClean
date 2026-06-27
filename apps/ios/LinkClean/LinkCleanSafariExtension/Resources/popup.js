// Phase 1 (plan 004): the Safari toolbar popup. Read the active tab's link
// (granted by `activeTab` only when the user taps the toolbar button), send it to
// the Swift handler via native messaging, and present the cleaned result with
// Copy / Copy as Markdown / Share. No cleaning logic lives here — the catalog
// stays in Swift, so there is nothing to drift.

const els = {};
let cleaned = "";
let markdown = "";

// Localized string with an English fallback (so the popup still reads correctly
// if a locale is missing a key).
function t(key, fallback) {
    return browser.i18n.getMessage(key) || fallback;
}

function showStatusOnly(message) {
    els.status.textContent = message;
    els.result.hidden = true;
    els.actions.hidden = true;
}

function showResult(statusMessage) {
    els.status.textContent = statusMessage;
    els.result.textContent = cleaned;
    els.result.hidden = false;
    els.actions.hidden = false;
    // Share isn't available in every context — only offer it when supported.
    els.share.hidden = typeof navigator.share !== "function";
}

function flash(button, key, fallback) {
    const original = button.dataset.label;
    button.textContent = t(key, fallback);
    button.disabled = true;
    setTimeout(() => {
        button.textContent = original;
        button.disabled = false;
    }, 1200);
}

async function copyText(text, button) {
    try {
        await navigator.clipboard.writeText(text);
        flash(button, "popup_feedback_copied", "Copied");
    } catch (e) {
        els.status.textContent = t("popup_status_error", "Something went wrong.");
    }
}

async function run() {
    els.status = document.getElementById("status");
    els.result = document.getElementById("result");
    els.actions = document.getElementById("actions");
    els.copy = document.getElementById("copy");
    els.markdown = document.getElementById("markdown");
    els.share = document.getElementById("share");

    // Localize the button labels; remember each so a "Copied" flash can restore it.
    els.copy.textContent = els.copy.dataset.label = t("popup_action_copy", "Copy");
    els.markdown.textContent = els.markdown.dataset.label = t("popup_action_markdown", "Copy as Markdown");
    els.share.textContent = els.share.dataset.label = t("popup_action_share", "Share");
    els.status.textContent = t("popup_status_cleaning", "Cleaning this page's link…");

    els.copy.addEventListener("click", () => copyText(cleaned, els.copy));
    els.markdown.addEventListener("click", () => copyText(markdown, els.markdown));
    els.share.addEventListener("click", async () => {
        try {
            await navigator.share({ url: cleaned });
        } catch (e) {
            // User dismissed the share sheet — nothing to do.
        }
    });

    try {
        const [tab] = await browser.tabs.query({ active: true, currentWindow: true });
        const url = tab && tab.url;
        const title = tab && tab.title;

        if (!url) {
            showStatusOnly(t("popup_status_no_link", "No link to clean on this page."));
            return;
        }

        const response = await browser.runtime.sendNativeMessage("application.id", { url, title });

        if (!response || !response.cleaned) {
            const key = response && response.error ? "popup_status_not_web" : "popup_status_error";
            const fallback = response && response.error ? "This isn't a web link." : "Something went wrong.";
            showStatusOnly(t(key, fallback));
            return;
        }

        cleaned = response.cleaned;
        markdown = response.markdown || cleaned;

        if (cleaned === url) {
            showResult(t("popup_status_already_clean", "Already clean — nothing to remove."));
        } else {
            showResult(t("popup_status_cleaned", "Cleaned link"));
        }
    } catch (error) {
        showStatusOnly(t("popup_status_error", "Something went wrong."));
    }
}

document.addEventListener("DOMContentLoaded", run);
