import type { Locale } from "../i18n/locales";

export interface HowToStep {
  /** Short imperative title. */
  title: string;
  /** One- or two-sentence body explaining the step. */
  body: string;
}

export interface GuideContent {
  title: string;
  description: string;
  tldr: string;
  /** Optional intro paragraphs above the step list. */
  intro?: ReadonlyArray<string>;
  steps: ReadonlyArray<HowToStep>;
  /** Optional outro paragraphs below the steps. */
  outro?: ReadonlyArray<string>;
  /** Related slugs (tracker spokes, other guides, learn pillars). */
  related?: ReadonlyArray<{ label: string; href: string }>;
}

export interface GuideArticle {
  /** URL slug under `/guides/`. */
  slug: string;
  content: Partial<Record<Locale, GuideContent>>;
}
