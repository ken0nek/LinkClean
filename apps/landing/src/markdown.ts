import { raw } from "hono/html";

function escape(s: string): string {
  return s
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

/** Render the inline-markdown subset we author in content:
 *
 *  - `code`   → <code>code</code>
 *  - **bold** → <strong>bold</strong>
 *
 *  HTML metacharacters in the input are escaped first, so it's safe to use on
 *  any authored string. Returns an HtmlEscapedString suitable for JSX child
 *  insertion. Use everywhere user-facing prose is rendered (paragraphs, FAQ
 *  answers, bullets, TL;DR text). */
export function inline(text: string) {
  return raw(
    escape(text)
      .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
      .replace(/`([^`]+)`/g, "<code>$1</code>"),
  );
}
