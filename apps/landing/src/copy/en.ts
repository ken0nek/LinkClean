import { APP_STORE_ID } from "../brand";
import type { Copy } from "./types";

export const en: Copy = {
  meta: {
    title: "LinkClean — strip tracking parameters before you share",
    description:
      "LinkClean is a privacy-first iOS app that removes tracking parameters from links so you can share clean URLs from anywhere.",
  },
  hero: {
    h1: "Share clean links.",
    lede: "LinkClean strips tracking parameters from any URL before you share it — on iPhone, in the share sheet, and from Shortcuts.",
  },
  appStoreLabel: "Download on the App Store",
  appStoreCampaign: `https://apps.apple.com/app/apple-store/id${APP_STORE_ID}?pt=10674868&ct=landing&mt=8`,
  footer: {
    tagline: "Privacy-first URL cleaning for iOS.",
    bylinePrefix: "Built by",
    lastUpdatedPrefix: "Updated",
  },
};
