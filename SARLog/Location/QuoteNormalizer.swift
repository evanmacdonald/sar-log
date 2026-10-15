import Foundation

/// iOS smart-punctuation rewrites `'` to `'` / `'` and `"` to `"` / `"` on
/// text fields that don't opt out. Coordinate parsers all look for the
/// straight ASCII forms, so normalize before matching. Also folds a few
/// other common look-alikes (prime, double-prime) to the same ASCII form.
enum QuoteNormalizer {
    static func normalize(_ input: String) -> String {
        var out = input
        let singleReplacements: [Character] = ["\u{2018}", "\u{2019}", "\u{201A}", "\u{201B}", "\u{2032}", "\u{2035}", "\u{02BC}", "`"]
        let doubleReplacements: [Character] = ["\u{201C}", "\u{201D}", "\u{201E}", "\u{201F}", "\u{2033}", "\u{2036}"]
        for ch in singleReplacements {
            out = out.replacingOccurrences(of: String(ch), with: "'")
        }
        for ch in doubleReplacements {
            out = out.replacingOccurrences(of: String(ch), with: "\"")
        }
        return out
    }
}
