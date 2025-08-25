import Foundation

struct Config {
    static var geminiAPIKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String else {
            fatalError("GEMINI_API_KEY not found in Info.plist. Please add it to your Info.plist file.")
        }
        return key
    }
}
