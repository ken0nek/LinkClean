//
//  ActionViewController.swift
//  LinkCleanMarkdownAction
//
//  Created by Ken Tominaga on 2/6/26.
//

import LinkCleanExtensionUI

/// The "Copy as you want" action extension — a configuration of the shared host:
/// pick the ``TemplateOutputStrategy`` (render the user's selected link format,
/// fail closed to the free Markdown default), inherit the pipeline + UIKit
/// presentation. Evolved from the former "Copy as Markdown" action: Markdown is
/// now just the free default preset of the one template engine (`copy-as-you-want`
/// §6.4), so this target gained formats without gaining code.
class ActionViewController: ActionHostViewController {
    override var strategy: any ActionOutputStrategy { TemplateOutputStrategy() }
}
