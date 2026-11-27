import AppKit
import CoreText

extension FolderSymbol {
    var title: String {
        switch self {
        case .star: return BrowserLocalization.text("Star")
        case .bookmark: return BrowserLocalization.text("Bookmark")
        case .heart: return BrowserLocalization.text("Heart")
        case .bolt: return BrowserLocalization.text("Lightning")
        case .triangle: return BrowserLocalization.text("Triangle")
        case .asterisk: return BrowserLocalization.text("Asterisk")
        case .bell: return BrowserLocalization.text("Bell")
        case .lightbulb: return BrowserLocalization.text("Lightbulb")
        case .chat: return BrowserLocalization.text("Chat")
        case .people: return BrowserLocalization.text("People")
        case .tools: return BrowserLocalization.text("Tools")
        case .egg: return BrowserLocalization.text("Egg")
        case .circle: return BrowserLocalization.text("Circle")
        case .moon: return BrowserLocalization.text("Moon")
        case .planet: return BrowserLocalization.text("Planet")
        case .leaf: return BrowserLocalization.text("Leaf")
        case .cloud: return BrowserLocalization.text("Cloud")
        case .paw: return BrowserLocalization.text("Paw")
        case .cutlery: return BrowserLocalization.text("Cutlery")
        case .airplane: return BrowserLocalization.text("Airplane")
        case .music: return BrowserLocalization.text("Music")
        case .video: return BrowserLocalization.text("Video")
        case .code: return BrowserLocalization.text("Code")
        case .skull: return BrowserLocalization.text("Skull")
        }
    }

    var image: NSImage { Self.images[self]! }

    private var character: String {
        switch self {
        case .star: return "\u{f53b}"
        case .bookmark: return "\u{f193}"
        case .heart: return "\u{f33d}"
        case .bolt: return "\u{f2e3}"
        case .triangle: return "\u{f598}"
        case .asterisk: return "\u{f3f7}"
        case .bell: return "\u{f42d}"
        case .lightbulb: return "\u{f1a8}"
        case .chat: return "\u{f1f3}"
        case .people: return "\u{f451}"
        case .tools: return "\u{f262}"
        case .egg: return "\u{f29b}"
        case .circle: return "\u{f29e}"
        case .moon: return "\u{f40f}"
        case .planet: return "\u{f472}"
        case .leaf: return "\u{f373}"
        case .cloud: return "\u{f23b}"
        case .paw: return "\u{f448}"
        case .cutlery: return "\u{f4e1}"
        case .airplane: return "\u{f109}"
        case .music: return "\u{f415}"
        case .video: return "\u{f5a4}"
        case .code: return "\u{f24d}"
        case .skull: return "\u{f52c}"
        }
    }

    private static let font: NSFont = {
        guard let url = Bundle.main.url(forResource: "Ionicons", withExtension: "ttf", subdirectory: "fonts"),
              let provider = CGDataProvider(url: url as CFURL), let font = CGFont(provider) else {
            preconditionFailure("Missing or invalid Ionicons font")
        }
        return CTFontCreateWithGraphicsFont(font, 16, nil, nil) as NSFont
    }()

    private static let images: [FolderSymbol: NSImage] = Dictionary(uniqueKeysWithValues: allCases.map { symbol in
        let text = NSAttributedString(string: symbol.character, attributes: [.font: font, .foregroundColor: NSColor.black])
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: false) { rect in
            let size = text.size()
            text.draw(at: NSPoint(x: (rect.width - size.width) / 2, y: (rect.height - size.height) / 2))
            return true
        }
        image.isTemplate = true
        return (symbol, image)
    })
}
