import UIKit

private final class PopButton: UIButton {
    var popupHost: UIView?
    var popupEnabled = false
    private var bubble: UIView?
    private let bubbleLabel = UILabel()
    private var bLeading: NSLayoutConstraint?
    private var bTop: NSLayoutConstraint?
    private var bWidth: NSLayoutConstraint?
    private var bHeight: NSLayoutConstraint?

    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if popupEnabled {
            syncBubble(reference: touch.location(in: self))
        }
        return super.beginTracking(touch, with: event)
    }

    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        if popupEnabled {
            syncBubble(reference: touch.location(in: self))
        }
        return super.continueTracking(touch, with: event)
    }

    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        hideBubble()
        super.endTracking(touch, with: event)
    }

    override func cancelTracking(with event: UIEvent?) {
        hideBubble()
        super.cancelTracking(with: event)
    }

    func setBubbleText(_ text: String) {
        bubbleLabel.text = text
    }

    private func syncBubble(reference: CGPoint) {
        if bounds.contains(reference) {
            showBubble()
        } else {
            hideBubble()
        }
    }

    private func showBubble() {
        guard popupEnabled, let host = popupHost else { return }
        if bubble == nil {
            let b = UIView()
            b.backgroundColor = self.backgroundColor
            b.layer.cornerRadius = 6
            b.layer.masksToBounds = true
            b.isUserInteractionEnabled = false
            b.translatesAutoresizingMaskIntoConstraints = false
            bubbleLabel.font = .systemFont(ofSize: 22, weight: .semibold)
            bubbleLabel.textColor = .white
            bubbleLabel.textAlignment = .center
            bubbleLabel.isUserInteractionEnabled = false
            bubbleLabel.translatesAutoresizingMaskIntoConstraints = false
            b.addSubview(bubbleLabel)
            host.addSubview(b)
            bLeading = b.leadingAnchor.constraint(equalTo: host.leadingAnchor)
            bTop = b.topAnchor.constraint(equalTo: host.topAnchor)
            bWidth = b.widthAnchor.constraint(equalToConstant: 0)
            bHeight = b.heightAnchor.constraint(equalToConstant: 0)
            NSLayoutConstraint.activate([bLeading!, bTop!, bWidth!, bHeight!])
            NSLayoutConstraint.activate([
                bubbleLabel.centerXAnchor.constraint(equalTo: b.centerXAnchor),
                bubbleLabel.centerYAnchor.constraint(equalTo: b.centerYAnchor)
            ])
            bubble = b
        }
        bubbleLabel.text = currentTitle ?? ""
        let keyFrame = host.convert(bounds, from: self)
        let overlap: CGFloat = 10
        let popWidth = keyFrame.width + 14
        let margin: CGFloat = 3
        let padLeft = max(margin, keyFrame.midX - popWidth / 2)
        let padRight = max(margin, host.bounds.width - popWidth - margin)
        var x = min(padLeft, padRight)
        var y = keyFrame.minY + overlap - 50
        if y < 0 { y = 0 }
        if x < margin { x = min(margin, padRight) }
        bWidth?.constant = popWidth
        bHeight?.constant = 50
        bLeading?.constant = x
        bTop?.constant = y
        guard let bubble else { return }
        bubble.alpha = 0
        bubble.transform = CGAffineTransform(scaleX: 1, y: 0.7)
        host.layoutIfNeeded()
        UIView.animate(withDuration: 0.08) {
            bubble.alpha = 1
            bubble.transform = .identity
        }
    }

    private func hideBubble() {
        guard let bubble else { return }
        self.bubble = nil
        bubble.removeFromSuperview()
    }
}

class KeyboardViewController: UIInputViewController {

    private let statusLabel = UILabel()
    private var insertionHistory: [String] = []
    private var alternates: [UIButton: Character] = [:]
    private var longPressFired = false
    private var deleteTimer: Timer?
    private var cursorAnchor: CGPoint = .zero
    private var cursorApplied = 0
    private var refKey: UIButton!

    private let normalColor = UIColor(red: 0.29, green: 0.30, blue: 0.33, alpha: 1)
    private let specialColor = UIColor(red: 0.17, green: 0.18, blue: 0.20, alpha: 1)
    private let accentColor = UIColor(red: 0.22, green: 0.42, blue: 0.75, alpha: 1)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = specialColor
        buildLayout()
    }

    private func buildLayout() {
        let row1Specs: [(String, String)] = [
            ("q", "1"), ("w", "2"), ("e", "3"), ("r", "4"), ("t", "5"),
            ("y", "6"), ("u", "7"), ("i", "8"), ("o", "9"), ("p", "0")
        ]
        let row1Keys = row1Specs.map { makeCharKey($0.0, alternate: Character($0.1)) }
        refKey = row1Keys[0]
        let row1 = makeRow(row1Keys, spacing: 6)

        var widthRules: [NSLayoutConstraint] = []
        widthRules += equalize(row1Keys)

        let row2Keys = "asdfghjkl".map { makeCharKey(String($0), alternate: nil) }
        widthRules += equalize(row2Keys, to: refKey)

        let del = makeButton("⌫", background: normalColor, action: #selector(deleteTapped))
        let hold = UILongPressGestureRecognizer(target: self, action: #selector(deletePressed(_:)))
        hold.minimumPressDuration = 0.35
        del.addGestureRecognizer(hold)
        widthRules.append(del.widthAnchor.constraint(equalTo: refKey.widthAnchor))
        let row2 = makeRow(row2Keys + [del], spacing: 6)

        let trans = makeIconButton(systemName: "list.bullet", background: normalColor, action: #selector(showCodeTable))

        let row3Keys = [("z", nil as Character?), ("x", nil), ("c", nil),
                        ("v", "/"), ("b", ","), ("n", "."), ("m", "?")]
            .map { makeCharKey($0.0, alternate: $0.1) }
        widthRules += equalize(row3Keys, to: refKey)

        let ret = makeButton("↵", background: accentColor, action: #selector(returnTapped))
        let drag = UILongPressGestureRecognizer(target: self, action: #selector(spaceDragged(_:)))
        drag.minimumPressDuration = 0.4
        ret.addGestureRecognizer(drag)
        let row3 = makeRow([trans] + row3Keys + [ret], spacing: 6)

        let toolbar = makeToolbar()
        let stack = UIStackView(arrangedSubviews: [
            toolbar, row1, row2, row3
        ])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 4),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -4),
            stack.bottomAnchor.constraint(equalTo: view.layoutMarginsGuide.bottomAnchor, constant: -4)
        ])
        widthRules.append(refKey.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 0.1, constant: -5.4))
        widthRules.append(trans.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 0.15, constant: -5.1))
        widthRules.append(ret.widthAnchor.constraint(equalTo: stack.widthAnchor, multiplier: 0.15, constant: -5.1))
        NSLayoutConstraint.activate(widthRules)
    }

    private func makeToolbar() -> UIStackView {
        statusLabel.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        statusLabel.textColor = UIColor(white: 0.85, alpha: 1)
        statusLabel.textAlignment = .center
        statusLabel.text = ""
        statusLabel.adjustsFontSizeToFitWidth = true
        statusLabel.minimumScaleFactor = 0.5
        return makeRow([statusLabel], spacing: 0)
    }

    private func makeRow(_ views: [UIView], spacing: CGFloat) -> UIStackView {
        let s = UIStackView(arrangedSubviews: views)
        s.axis = .horizontal
        s.spacing = spacing
        s.distribution = .fill
        for case let b as UIButton in views {
            b.setContentHuggingPriority(.defaultLow, for: .horizontal)
            b.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        }
        return s
    }

    @discardableResult
    private func equalize(_ buttons: [UIButton], to ref: UIButton? = nil) -> [NSLayoutConstraint] {
        let target = ref ?? buttons[0]
        return buttons.filter { $0 !== target }.map { $0.widthAnchor.constraint(equalTo: target.widthAnchor) }
    }

    private func makeCharKey(_ title: String, alternate: Character?) -> UIButton {
        let b = makeButton(title, background: normalColor, action: #selector(charKeyTapped(_:)))
        b.popupEnabled = true
        if let alt = alternate {
            alternates[b] = alt
            let g = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
            g.minimumPressDuration = 0.35
            g.cancelsTouchesInView = false
            b.addGestureRecognizer(g)

            let hint = UILabel()
            hint.text = String(alt)
            hint.font = .systemFont(ofSize: 10, weight: .semibold)
            hint.textColor = UIColor(white: 0.72, alpha: 1)
            hint.translatesAutoresizingMaskIntoConstraints = false
            b.addSubview(hint)
            NSLayoutConstraint.activate([
                hint.topAnchor.constraint(equalTo: b.topAnchor, constant: 2),
                hint.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: -5)
            ])
        }
        return b
    }

    private func makeButton(_ title: String, background: UIColor, action: Selector) -> PopButton {
        let b = PopButton(type: .system)
        b.popupHost = view
        b.setTitle(title, for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 19, weight: .medium)
        b.titleLabel?.adjustsFontSizeToFitWidth = true
        b.backgroundColor = background
        b.layer.cornerRadius = 6
        b.heightAnchor.constraint(equalToConstant: 46).isActive = true
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    private func makeIconButton(systemName: String, background: UIColor, action: Selector) -> PopButton {
        let b = PopButton(type: .system)
        b.popupHost = view
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .medium)
        b.setImage(UIImage(systemName: systemName, withConfiguration: config), for: .normal)
        b.tintColor = .white
        b.backgroundColor = background
        b.layer.cornerRadius = 6
        b.heightAnchor.constraint(equalToConstant: 46).isActive = true
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    @objc private func charKeyTapped(_ sender: UIButton) {
        if longPressFired {
            longPressFired = false
            return
        }
        guard let title = sender.currentTitle, let ch = title.first else { return }
        insertMorse(ch, source: title)
    }

    @objc private func longPressed(_ g: UILongPressGestureRecognizer) {
        guard g.state == .began,
              let btn = g.view as? UIButton,
              let alt = alternates[btn] else { return }
        longPressFired = true
        (btn as? PopButton)?.setBubbleText(String(alt))
        insertMorse(alt, source: String(alt))
    }

    @objc private func returnTapped() {
        insert("\n")
    }

    @objc private func deletePressed(_ g: UILongPressGestureRecognizer) {
        switch g.state {
        case .began:
            performDelete()
            let t = Timer(timeInterval: 0.15, repeats: true) { [weak self] _ in
                self?.performDelete()
            }
            RunLoop.main.add(t, forMode: .common)
            deleteTimer = t
        case .ended, .cancelled, .failed:
            deleteTimer?.invalidate()
            deleteTimer = nil
        default:
            break
        }
    }

    private func performDelete() {
        if let last = insertionHistory.popLast() {
            for _ in last { textDocumentProxy.deleteBackward() }
        } else {
            textDocumentProxy.deleteBackward()
        }
        statusLabel.text = ""
    }

    @objc private func deleteTapped() {
        performDelete()
    }

    @objc private func spaceDragged(_ g: UILongPressGestureRecognizer) {
        guard let btn = g.view as? UIButton else { return }
        switch g.state {
        case .began:
            cursorAnchor = g.location(in: btn)
            cursorApplied = 0
            btn.setTitle("◀ 光标移动中 ▶", for: .normal)
            statusLabel.text = "拖动移动光标"
        case .changed:
            let loc = g.location(in: btn)
            let dx = loc.x - cursorAnchor.x
            let dy = loc.y - cursorAnchor.y
            let charsPerLine = max(10, Int(view.bounds.width / 7.2))
            let desired = Int((dx / 9).rounded())
                      + Int((dy / 42).rounded()) * charsPerLine
            var step = desired - cursorApplied
            if step > 0 {
                step = min(step, textDocumentProxy.documentContextAfterInput?.utf16.count ?? 0)
            } else {
                step = max(step, -(textDocumentProxy.documentContextBeforeInput?.utf16.count ?? 0))
            }
            if step != 0 {
                textDocumentProxy.adjustTextPosition(byCharacterOffset: step)
                cursorApplied += step
            } else {
                cursorApplied = desired
            }
        case .ended, .cancelled, .failed:
            btn.setTitle("↵", for: .normal)
            statusLabel.text = ""
        default:
            break
        }
    }

    private func insertMorse(_ ch: Character, source: String) {
        if ch == "/" {
            insert("/ ")
            statusLabel.text = "空格 → /"
            return
        }
        guard let code = Morse.encode(ch) else { return }
        insert(code + " ")
        statusLabel.text = "\(source) → \(code)"
    }

    private func insert(_ text: String) {
        textDocumentProxy.insertText(text)
        insertionHistory.append(text)
    }

    // MARK: - 翻译页面

    @objc private func showCodeTable() {
        var sections: [String] = []

        var letters: [String] = []
        for ch in "abcdefghijklmnopqrstuvwxyz" {
            if let code = Morse.table[ch] {
                letters.append("\(ch.uppercased()) \(code)")
            }
        }
        sections.append(letters.joined(separator: " · "))

        var nums: [String] = []
        for ch in "0123456789" {
            if let code = Morse.table[ch] {
                nums.append("\(ch) \(code)")
            }
        }
        sections.append(nums.joined(separator: " · "))

        var syms: [String] = []
        for (ch, code) in Morse.table.sorted(by: { $0.key < $1.key }) {
            if ch.isLetter || ch.isNumber { continue }
            syms.append("\(ch) \(code)")
        }
        sections.append(syms.joined(separator: " · "))

        statusLabel.text = "字母  " + sections[0] + "  │  数字  " + sections[1] + "  │  符号  " + sections[2]
    }
}
