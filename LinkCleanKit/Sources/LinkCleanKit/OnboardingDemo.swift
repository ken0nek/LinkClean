//
//  OnboardingDemo.swift
//  LinkCleanKit
//
//  Created by Ken Tominaga on 6/7/26.
//

import Foundation

/// The sample link used by the onboarding / extension-guide "Try it" flow.
/// Shared between the app (which presents it) and the action extensions (which
/// recognize it so they don't persist a practice run to History).
public nonisolated enum OnboardingDemo {
    /// A real-looking link on the reserved `example.com` documentation domain,
    /// loaded with tracking junk (`utm_*`, `fbclid`) that the default parameter
    /// set strips.
    public static let url = URL(string: "https://www.example.com/products/sneakers?utm_source=newsletter&utm_medium=email&utm_campaign=spring_sale&fbclid=abc123")!

    /// Whether `candidate` is the onboarding sample link. The action extension
    /// uses this to skip saving the demo to History — the user is practicing,
    /// not cleaning a real link. Matches host + path so the share sheet's
    /// query re-encoding can't defeat it; `example.com` is reserved, so a real
    /// link can't collide.
    public static func matches(_ candidate: URL) -> Bool {
        guard
            let lhs = URLComponents(url: candidate, resolvingAgainstBaseURL: false),
            let rhs = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return false
        }
        return lhs.host == rhs.host && lhs.path == rhs.path
    }

    public static func matches(urlString: String) -> Bool {
        guard let candidate = URL(string: urlString) else { return false }
        return matches(candidate)
    }
}
