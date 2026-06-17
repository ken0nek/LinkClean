import type { Locale } from "../i18n/locales";

/** Optional table inside a long-form section. `headers` labels the columns;
 *  each row is an array matching the headers. Useful for reference content
 *  (param-value tables, comparison rows). Rendered as <table> in HTML and as
 *  visible structure for LLMs / Google's structured-data extractor. */
export interface SectionTable {
  headers: ReadonlyArray<string>;
  rows: ReadonlyArray<ReadonlyArray<string>>;
  /** Optional caption rendered above the table. */
  caption?: string;
}

export interface LearnSection {
  heading: string;
  paragraphs: ReadonlyArray<string>;
  /** Optional bullet list. */
  bullets?: ReadonlyArray<string>;
  /** Optional reference table. */
  table?: SectionTable;
}

export interface LearnContent {
  title: string;
  description: string;
  /** Bolded one- or two-sentence TL;DR rendered at the top. */
  tldr: string;
  sections: ReadonlyArray<LearnSection>;
  faq?: ReadonlyArray<{ q: string; a: string }>;
  related?: ReadonlyArray<{ label: string; href: string }>;
}

export interface LearnArticle {
  /** URL slug under `/learn/`. */
  slug: string;
  content: Partial<Record<Locale, LearnContent>>;
}
