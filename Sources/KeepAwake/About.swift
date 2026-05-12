import AppKit

func showAbout() {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.1.0"
    let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

    let credits = NSMutableAttributedString()
    let style = NSMutableParagraphStyle()
    style.alignment = .center

    let nameAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize),
        .paragraphStyle: style,
    ]
    credits.append(NSAttributedString(string: "Yashiel Sookdeo\n\n", attributes: nameAttrs))

    let linkAttrs: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize - 1),
        .link: URL(string: "https://github.com/yashiels/keep-awake")!,
        .paragraphStyle: style,
    ]
    credits.append(NSAttributedString(string: "GitHub", attributes: linkAttrs))

    NSApp.activate(ignoringOtherApps: true)
    NSApp.orderFrontStandardAboutPanel(options: [
        .applicationName: "KeepAwake",
        .applicationVersion: version,
        .version: build,
        .credits: credits,
        .applicationIcon: NSApp.applicationIconImage as Any,
    ])
}
