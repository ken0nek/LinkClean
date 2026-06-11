//
//  ActionViewController.swift
//  LinkCleanMarkdownAction
//
//  Created by Ken Tominaga on 2/6/26.
//

import LinkCleanExtensionUI

/// The "Copy as Markdown" action extension — a configuration of the shared host:
/// pick the Markdown strategy (JS title / LPMetadata / URL-only), inherit the
/// pipeline + UIKit presentation.
class ActionViewController: ActionHostViewController {
    override var strategy: any ActionOutputStrategy { MarkdownLinkStrategy() }
}
