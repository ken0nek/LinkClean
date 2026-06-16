export interface Copy {
  meta: {
    title: string;
    description: string;
  };
  hero: {
    h1: string;
    lede: string;
  };
  appStoreLabel: string;
  /** Apple campaign-link URL with locale-specific `ct=` token so App Store
   *  Connect → Sources can attribute traffic by language. */
  appStoreCampaign: string;
  footer: {
    tagline: string;
    bylinePrefix: string;
    lastUpdatedPrefix: string;
  };
}
