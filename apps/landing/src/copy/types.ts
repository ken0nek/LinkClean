export interface AppStoreBadge {
  file: string;
  alt: string;
  width: number;
  height: number;
}

export interface FaqItem {
  q: string;
  a: string;
}

export interface BenefitItem {
  num: string;
  title: string;
  body: string;
}

export interface ComparisonRow {
  feature: string;
  linkclean: string;
  other: string;
}

export interface Copy {
  meta: {
    title: string;
    description: string;
  };
  /** SoftwareApplication JSON-LD copy. */
  schema: {
    alternateName: string;
    description: string;
    featureList: ReadonlyArray<string>;
  };
  appStoreBadge: AppStoreBadge;
  /** Apple campaign-link URL with a `ct=` token so App Store Connect →
   *  Sources can attribute traffic. */
  appStoreCampaign: string;
  hero: {
    h1: string;
    lede: string;
    sub: string;
  };
  /** Above-the-fold "What LinkClean does" demo — dirty URL → clean URL. */
  demo: {
    h2: string;
    intro: string;
    dirtyLabel: string;
    dirtyUrl: string;
    cleanLabel: string;
    cleanUrl: string;
    strippedLabel: string;
    strippedNote: string;
  };
  /** Three-up "what makes it tick" benefits. */
  benefits: {
    h2: string;
    items: ReadonlyArray<BenefitItem>;
  };
  /** "How it differs from a browser extension" comparison table. */
  comparison: {
    h2: string;
    linkcleanHeader: string;
    otherHeader: string;
    rows: ReadonlyArray<ComparisonRow>;
  };
  /** "Surfaces (where cleaning happens)" — app / share extension / Shortcuts. */
  surfaces: {
    h2: string;
    items: ReadonlyArray<{ title: string; body: string }>;
  };
  /** Glossary entry point that surfaces the /trackers/ hub. */
  trackersCta: {
    h2: string;
    body: string;
    linkLabel: string;
  };
  faqSection: {
    h2: string;
  };
  faq: ReadonlyArray<FaqItem>;
  footer: {
    tagline: string;
    bylinePrefix: string;
    privacyLabel: string;
    termsLabel: string;
    lastUpdatedPrefix: string;
  };
  localePicker: {
    ariaLabel: string;
  };
}
