//
//  ActionViewController.swift
//  LinkCleanAction
//
//  Created by Ken Tominaga on 2/1/26.
//

import LinkCleanExtensionUI

/// The "Clean URL" action extension — a configuration of the shared host: pick
/// the strategy, inherit the pipeline + UIKit presentation.
class ActionViewController: ActionHostViewController {
    override var strategy: any ActionOutputStrategy { CleanLinkStrategy() }
}
