import Foundation

struct NotificationParser {

    struct ParsedTransaction {
        let amount: Double
        let merchant: String
        let card: CardType
    }

    // Parses Wallet notification text such as:
    // "עסקה בסך 150.00 ₪ ב-שופרסל עם כרטיס ישראכארט"
    // "חיוב של 200 ₪ ב Super-Pharm כרטיס מאסטרקארד"
    static func parse(_ text: String) -> ParsedTransaction? {
        guard let amount = extractAmount(from: text) else { return nil }
        let merchant = extractMerchant(from: text)
        let card = extractCard(from: text)
        return ParsedTransaction(amount: amount, merchant: merchant, card: card)
    }

    private static func extractAmount(from text: String) -> Double? {
        let patterns = [
            #"(\d+(?:[.,]\d{1,2})?)\s*₪"#,
            #"₪\s*(\d+(?:[.,]\d{1,2})?)"#,
            #"סך\s+(\d+(?:[.,]\d{1,2})?)"#,
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range),
               let valueRange = Range(match.range(at: 1), in: text) {
                let raw = text[valueRange].replacingOccurrences(of: ",", with: ".")
                if let value = Double(raw) { return value }
            }
        }
        return nil
    }

    private static func extractMerchant(from text: String) -> String {
        let patterns = [
            #"ב-([^\s,\n]+(?:\s+[^\s,\n]+)?)"#,
            #"ב ([A-Za-zא-ת][^\s,\n]+(?:\s+[^\s,\n]+)?)"#,
        ]
        for pattern in patterns {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            if let match = regex.firstMatch(in: text, range: range),
               let nameRange = Range(match.range(at: 1), in: text) {
                let name = String(text[nameRange])
                    .trimmingCharacters(in: .whitespaces)
                if !name.isEmpty { return name }
            }
        }
        return "עסקה"
    }

    private static func extractCard(from text: String) -> CardType {
        let lower = text.lowercased()
        if lower.contains("כאל") || lower.contains("cal") || lower.contains("mastercard") || lower.contains("מאסטרקארד") {
            return .cal
        }
        return .isracard
    }
}
