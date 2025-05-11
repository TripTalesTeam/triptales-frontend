import Foundation

class Env {
    static let shared = Env()
    private var variables: [String: String] = [:]

    private init() {
        loadEnv()
    }

    private func loadEnv() {
        guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
            print(".env file not found in bundle")
            return
        }

        do {
            let content = try String(contentsOfFile: path)
            let lines = content.split(separator: "\n")

            for line in lines {
                let parts = line.split(separator: "=", maxSplits: 1)
                if parts.count == 2 {
                    let key = String(parts[0]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = String(parts[1]).trimmingCharacters(in: .whitespacesAndNewlines)
                    variables[key] = value
                }
            }
        } catch {
            print("Failed to read .env: \(error)")
        }
    }

    func get(_ key: String) -> String? {
        return variables[key]
    }
}
