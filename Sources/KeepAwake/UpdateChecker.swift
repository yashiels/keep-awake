import Foundation

@Observable
final class UpdateChecker {
    private(set) var latestVersion: String?
    private(set) var releaseURL: URL?
    private(set) var isChecking = false

    var updateAvailable: Bool {
        guard let latest = latestVersion else { return false }
        let current = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"
        return latest.compare(current, options: .numeric) == .orderedDescending
    }

    func checkForUpdates() {
        guard !isChecking else { return }
        isChecking = true

        let url = URL(string: "https://api.github.com/repos/yashiels/keep-awake/releases/latest")!
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            defer { DispatchQueue.main.async { self?.isChecking = false } }
            guard let data, error == nil,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String,
                  let htmlURL = json["html_url"] as? String else { return }

            let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
            guard let parsed = URL(string: htmlURL),
                  parsed.scheme == "https",
                  parsed.host == "github.com" else { return }
            DispatchQueue.main.async {
                self?.latestVersion = version
                self?.releaseURL = parsed
            }
        }.resume()
    }
}
