import type { Locale } from "../i18n/locales";

export interface LearnSection {
  heading: string;
  paragraphs: ReadonlyArray<string>;
  /** Optional bullet list. */
  bullets?: ReadonlyArray<string>;
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
