//
//  CopyFormatPresetName.swift
//  LinkClean
//
//  Created by Ken Tominaga on 6/14/26.
//

import SwiftUI
import LinkCleanCore

/// Maps a built-in ``LinkTemplate`` preset identifier (`"markdown"`, `"html"`, …)
/// to its localized display name. The domain ships identifiers, not copy
/// (ARCHITECTURE.md), so the mapping lives in the presenting layer where the
/// string catalog generates the symbols — exactly like ``parameterKindTitle``. A
/// custom template carries the user's own name, shown verbatim, so this only
/// handles the presets; an unknown id falls back to the raw identifier.
func copyFormatPresetName(_ id: String) -> Text {
    switch id {
    case "clean": Text(.copyFormatsPresetClean)
    case "markdown": Text(.copyFormatsPresetMarkdown)
    case "titleAndURL": Text(.copyFormatsPresetTitleAndURL)
    case "html": Text(.copyFormatsPresetHtml)
    case "quote": Text(.copyFormatsPresetQuote)
    case "citation": Text(.copyFormatsPresetCitation)
    case "slack": Text(.copyFormatsPresetSlack)
    case "plainTitle": Text(.copyFormatsPresetPlainTitle)
    default: Text(verbatim: id)
    }
}

/// The display name for any template — a localized preset name for built-ins, the
/// user's verbatim text for custom templates.
func copyFormatDisplayName(_ template: LinkTemplate) -> Text {
    template.isBuiltin ? copyFormatPresetName(template.name) : Text(verbatim: template.name)
}
