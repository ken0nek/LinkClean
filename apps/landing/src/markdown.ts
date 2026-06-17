import { raw } from "hono/html";

function escape(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

/** Render the inline-markdown subset we author in content:
 *
 *  - `code`        → <code>code</code>
 *  - **bold**      → <strong>bold</strong>
 *  - [text](url)   → <a href="url">text</a>   (root-relative URLs only — drops external)
 *
 *  HTML metacharacters in the input are escaped first, so it's safe to use on
 *  any authored string. Returns an HtmlEscapedString suitable for JSX child
 *  insertion. Use everywhere user-facing prose is rendered (paragraphs, FAQ
 *  answers, bullets, TL;DR text). */
export function inline(text: string) {
  return raw(
    escape(text)
      // Links FIRST so the URL doesn't get **/`` mangled
      .replace(
        /\[([^\]]+)\]\((\/[^)\s]*)\)/g,
        '<a href="$2">$1</a>',
      )
      .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
      .replace(/`([^`]+)`/g, "<code>$1</code>"),
  );
}
