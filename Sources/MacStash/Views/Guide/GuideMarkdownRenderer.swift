import SwiftUI
import AppKit

/// Rich Native SwiftUI Markdown Renderer for User Guide articles and documentation.
public struct MarkdownArticleView: View {
    @Environment(\.colorScheme) private var colorScheme
    public let markdown: String

    public init(markdown: String) {
        self.markdown = markdown
    }

    private enum Block: Identifiable {
        case heading(id: Int, level: Int, text: String)
        case paragraph(id: Int, text: String)
        case bullet(id: Int, text: String)
        case numbered(id: Int, prefix: String, text: String)
        case blockquote(id: Int, text: String)
        case codeBlock(id: Int, lines: [String])
        case table(id: Int, headers: [String], rows: [[String]])
        case divider(id: Int)

        var id: Int {
            switch self {
            case .heading(let id, _, _),
                 .paragraph(let id, _),
                 .bullet(let id, _),
                 .numbered(let id, _, _),
                 .blockquote(let id, _),
                 .codeBlock(let id, _),
                 .table(let id, _, _),
                 .divider(let id):
                return id
            }
        }
    }

    public var body: some View {
        let blocks = parseBlocks(from: markdown)
        VStack(alignment: .leading, spacing: 10) {
            ForEach(blocks) { block in
                renderBlock(block)
            }
        }
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func renderBlock(_ block: Block) -> some View {
        switch block {
        case .heading(_, let level, let text):
            VStack(alignment: .leading, spacing: 6) {
                inlineText(text)
                    .font(.system(
                        size: level == 1 ? 22 : (level == 2 ? 16 : 13.5),
                        weight: level <= 2 ? .bold : .semibold
                    ))
                    .foregroundColor(.primary)
                    .padding(.top, level == 1 ? 0 : 8)

                if level == 1 {
                    Divider()
                        .padding(.bottom, 4)
                }
            }

        case .paragraph(_, let text):
            inlineText(text)
                .font(.system(size: 13))
                .foregroundColor(.primary.opacity(0.9))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

        case .bullet(_, let text):
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 5, height: 5)
                    .padding(.top, 6)

                inlineText(text)
                    .font(.system(size: 13))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineSpacing(3.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 6)

        case .numbered(_, let prefix, let text):
            HStack(alignment: .top, spacing: 8) {
                Text(prefix)
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(.accentColor)
                    .frame(minWidth: 18, alignment: .trailing)

                inlineText(text)
                    .font(.system(size: 13))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineSpacing(3.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.leading, 4)

        case .blockquote(_, let text):
            HStack(alignment: .top, spacing: 10) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.accentColor)
                    .frame(width: 3)

                inlineText(text)
                    .font(.system(size: 12.5))
                    .foregroundColor(.secondary)
                    .lineSpacing(3.5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.accentColor.opacity(0.08))
            )

        case .codeBlock(_, let lines):
            Text(lines.joined(separator: "\n"))
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.primary)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(colorScheme == .dark ? Color.white.opacity(0.06) : Color.black.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.7)
                )

        case .table(_, let headers, let rows):
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    ForEach(Array(headers.enumerated()), id: \.offset) { colIdx, header in
                        inlineText(header)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        if colIdx < headers.count - 1 {
                            Divider()
                        }
                    }
                }
                .background(Color.primary.opacity(0.06))

                ForEach(Array(rows.enumerated()), id: \.offset) { rowIdx, row in
                    Divider()
                    HStack(spacing: 0) {
                        ForEach(0..<headers.count, id: \.self) { colIdx in
                            let cell = colIdx < row.count ? row[colIdx] : ""
                            inlineText(cell)
                                .font(.system(size: 12))
                                .foregroundColor(.primary.opacity(0.9))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            if colIdx < headers.count - 1 {
                                Divider()
                            }
                        }
                    }
                    .background(rowIdx % 2 == 1 ? Color.primary.opacity(0.025) : Color.clear)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.8)
            )

        case .divider:
            Divider()
                .padding(.vertical, 4)
        }
    }

    private func inlineText(_ raw: String) -> Text {
        if let attr = try? AttributedString(
            markdown: raw,
            options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        ) {
            return Text(attr)
        }
        return Text(raw)
    }

    private func parseBlocks(from raw: String) -> [Block] {
        let lines = raw.components(separatedBy: .newlines)
        var blocks: [Block] = []
        var idx = 0
        var nextID = 0

        func makeID() -> Int {
            defer { nextID += 1 }
            return nextID
        }

        while idx < lines.count {
            let line = lines[idx]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                idx += 1
                continue
            }

            if trimmed.hasPrefix("```") {
                idx += 1
                var codeLines: [String] = []
                while idx < lines.count && !lines[idx].trimmingCharacters(in: .whitespaces).hasPrefix("```") {
                    codeLines.append(lines[idx])
                    idx += 1
                }
                if idx < lines.count { idx += 1 }
                blocks.append(.codeBlock(id: makeID(), lines: codeLines))
                continue
            }

            if trimmed == "---" || trimmed == "***" {
                blocks.append(.divider(id: makeID()))
                idx += 1
                continue
            }

            if trimmed.hasPrefix("# ") {
                blocks.append(.heading(id: makeID(), level: 1, text: String(trimmed.dropFirst(2))))
                idx += 1
                continue
            }

            if trimmed.hasPrefix("## ") {
                blocks.append(.heading(id: makeID(), level: 2, text: String(trimmed.dropFirst(3))))
                idx += 1
                continue
            }

            if trimmed.hasPrefix("### ") {
                blocks.append(.heading(id: makeID(), level: 3, text: String(trimmed.dropFirst(4))))
                idx += 1
                continue
            }

            if trimmed.hasPrefix("> ") {
                var quoteLines = [String(trimmed.dropFirst(2))]
                idx += 1
                while idx < lines.count {
                    let nextTrimmed = lines[idx].trimmingCharacters(in: .whitespaces)
                    if nextTrimmed.hasPrefix("> ") {
                        quoteLines.append(String(nextTrimmed.dropFirst(2)))
                        idx += 1
                    } else {
                        break
                    }
                }
                blocks.append(.blockquote(id: makeID(), text: quoteLines.joined(separator: "\n")))
                continue
            }

            // Markdown table detection: | col1 | col2 |
            if trimmed.hasPrefix("|") && idx + 1 < lines.count {
                let separatorCandidate = lines[idx + 1].trimmingCharacters(in: .whitespaces)
                if separatorCandidate.hasPrefix("|") && separatorCandidate.contains("---") {
                    let headers = parseTableRow(trimmed)
                    idx += 2
                    var rows: [[String]] = []
                    while idx < lines.count {
                        let rowTrimmed = lines[idx].trimmingCharacters(in: .whitespaces)
                        if rowTrimmed.hasPrefix("|") {
                            rows.append(parseTableRow(rowTrimmed))
                            idx += 1
                        } else {
                            break
                        }
                    }
                    blocks.append(.table(id: makeID(), headers: headers, rows: rows))
                    continue
                }
            }

            if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                blocks.append(.bullet(id: makeID(), text: String(trimmed.dropFirst(2))))
                idx += 1
                continue
            }

            if let dotRange = trimmed.range(of: ". "),
               dotRange.lowerBound > trimmed.startIndex,
               let _ = Int(trimmed[..<dotRange.lowerBound]) {
                let prefix = String(trimmed[...dotRange.lowerBound])
                let rest = String(trimmed[dotRange.upperBound...])
                blocks.append(.numbered(id: makeID(), prefix: prefix, text: rest))
                idx += 1
                continue
            }

            // Merge consecutive plain lines into one paragraph
            var paraLines = [trimmed]
            idx += 1
            while idx < lines.count {
                let peek = lines[idx].trimmingCharacters(in: .whitespaces)
                if peek.isEmpty || peek.hasPrefix("#") || peek.hasPrefix("- ") || peek.hasPrefix("* ") ||
                    peek.hasPrefix("> ") || peek.hasPrefix("```") || peek.hasPrefix("|") || peek == "---" {
                    break
                }
                if let dotRange = peek.range(of: ". "),
                   dotRange.lowerBound > peek.startIndex,
                   let _ = Int(peek[..<dotRange.lowerBound]) {
                    break
                }
                paraLines.append(peek)
                idx += 1
            }
            blocks.append(.paragraph(id: makeID(), text: paraLines.joined(separator: " ")))
        }

        return blocks
    }

    private func parseTableRow(_ line: String) -> [String] {
        var trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("|") { trimmed.removeFirst() }
        if trimmed.hasSuffix("|") { trimmed.removeLast() }
        return trimmed.split(separator: "|", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
    }
}
