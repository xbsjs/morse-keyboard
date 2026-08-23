import UIKit

class KeyboardViewController: UIInputViewController {

    private let statusLabel = UILabel()
    private var insertionHistory: [String] = []
    private var alternates: [UIButton: Character] = [:]
    private var longPressFired = false
    private var deleteTimer: Timer?
    private var cursorAnchor: CGPoint = .zero
    private var cursorApplied = 0
    private var refKey: UIButton!

    private lazy var reverseMorse: [String: Character] = {
        var r: [String: Character] = [:]
        for (k, v) in Morse.table { r[v] = k }
        return r
    }()

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

        let trans = makeButton("译", background: normalColor, action: #selector(translateTapped))
        trans.titleLabel?.font = .systemFont(ofSize: 15, weight: .semibold)

        let row3Keys = [("z", nil as Character?), ("x", nil), ("c", nil),
                        ("v", "/"), ("b", ","), ("n", "."), ("m", "?")]
            .map { makeCharKey($0.0, alternate: $0.1) }
        widthRules += equalize(row3Keys, to: refKey)

        let ret = makeButton("↵", background: accentColor, action: #selector(returnTapped))
        let drag = UILongPressGestureRecognizer(target: self, action: #selector(spaceDragged(_:)))
        drag.minimumPressDuration = 0.4
        ret.addGestureRecognizer(drag)
        let row3 = makeRow([trans] + row3Keys + [ret], spacing: 6)

        let stack = UIStackView(arrangedSubviews: [
            makeToolbar(), row1, row2, row3
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
        if let alt = alternate {
            alternates[b] = alt
            let g = UILongPressGestureRecognizer(target: self, action: #selector(longPressed(_:)))
            g.minimumPressDuration = 0.35
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

    private func makeButton(_ title: String, background: UIColor, action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 19, weight: .medium)
        b.titleLabel?.adjustsFontSizeToFitWidth = true
        b.backgroundColor = background
        b.layer.cornerRadius = 6
        b.heightAnchor.constraint(equalToConstant: 44).isActive = true
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
        insertMorse(alt, source: String(alt))
    }

    @objc private func returnTapped() {
        insert("\n")
    }

    @objc private func translateTapped() {
        guard let sel = textDocumentProxy.selectedText, !sel.isEmpty else {
            statusLabel.text = "请先长按选中一段摩斯码"
            return
        }
        let result = decodeMorseText(sel)
        statusLabel.text = "译 → \(result)"
    }

    private func decodeMorseText(_ text: String) -> String {
        var out = ""
        for token in text.split(separator: " ", omittingEmptySubsequences: true) {
            if token == "/" {
                out.append(" ")
            } else if let ch = reverseMorse[String(token)] {
                out.append(ch)
            } else {
                out += token
            }
        }
        return out
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
}
