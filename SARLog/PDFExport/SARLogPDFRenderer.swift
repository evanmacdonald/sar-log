import CoreGraphics
import CoreText
import Foundation
import UIKit

struct SARLogPDFRowLayout {
    var row: SARLogPDFLogRow
    var height: CGFloat
}

enum SARLogPDFLayout {
    static let pageSize = CGSize(width: 612, height: 792)
    static let contentX: CGFloat = 50
    static let contentWidth: CGFloat = 512
    static let headerY: CGFloat = 30
    static let headerHeight: CGFloat = 86
    static let tableTopSpacing: CGFloat = 12
    static let subjectInfoHeight: CGFloat = 32
    static let subjectInfoBottomSpacing: CGFloat = 8
    static let tableHeaderHeight: CGFloat = 40
    static let footerY: CGFloat = 742
    static let footerHeight: CGFloat = 22
    static let rowPadding: CGFloat = 6
    static let minRowHeight: CGFloat = 24
    static let notesTextY: CGFloat = 80
    static let notesTextPadding: CGFloat = 8
    static let timeColumnWidth: CGFloat = 70
    static let stationCalledColumnWidth: CGFloat = 62
    static let thisIsColumnWidth: CGFloat = 66
    static let rowFont = UIFont.systemFont(ofSize: 10)
    static let timeFont = UIFont.monospacedDigitSystemFont(ofSize: 10, weight: .regular)
    static let notesFont = UIFont.systemFont(ofSize: 11)
    static let headerLabelFont = UIFont.boldSystemFont(ofSize: 8)
    static let headerValueFont = UIFont.systemFont(ofSize: 8)
    static let headerValueLeading: CGFloat = 58
    static let headerHorizontalPadding: CGFloat = 6

    static var subjectColumnWidth: CGFloat {
        contentWidth - timeColumnWidth - stationCalledColumnWidth - thisIsColumnWidth
    }

    static var tableY: CGFloat {
        subjectInfoY + subjectInfoHeight + subjectInfoBottomSpacing
    }

    static var subjectInfoY: CGFloat {
        headerY + headerHeight + tableTopSpacing
    }

    static var tableRowsAvailableHeight: CGFloat {
        footerY - tableY - tableHeaderHeight
    }

    static var notesTextWidth: CGFloat {
        contentWidth - (notesTextPadding * 2)
    }

    static var notesTextHeight: CGFloat {
        footerY - notesTextY - (notesTextPadding * 3)
    }

    static func rowHeight(
        subject: String,
        subjectWidth: CGFloat = subjectColumnWidth,
        font: UIFont = rowFont
    ) -> CGFloat {
        let textWidth = max(1, subjectWidth - (rowPadding * 2))
        let boundingSize = CGSize(width: textWidth, height: CGFloat.greatestFiniteMagnitude)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineBreakMode = .byWordWrapping
        let rect = (subject as NSString).boundingRect(
            with: boundingSize,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [
                .font: font,
                .paragraphStyle: paragraphStyle
            ],
            context: nil
        )
        return max(minRowHeight, ceil(rect.height) + (rowPadding * 2))
    }

    static func paginateRows(
        _ rows: [SARLogPDFLogRow],
        availableHeight: CGFloat = tableRowsAvailableHeight,
        subjectWidth: CGFloat = subjectColumnWidth
    ) -> [[SARLogPDFRowLayout]] {
        guard !rows.isEmpty else { return [[]] }

        var pages: [[SARLogPDFRowLayout]] = []
        var currentPage: [SARLogPDFRowLayout] = []
        var usedHeight: CGFloat = 0

        for row in rows {
            let height = rowHeight(subject: row.subject, subjectWidth: subjectWidth)
            let layout = SARLogPDFRowLayout(row: row, height: height)
            if !currentPage.isEmpty, usedHeight + height > availableHeight {
                pages.append(currentPage)
                currentPage = []
                usedHeight = 0
            }

            currentPage.append(layout)
            usedHeight += height
        }

        pages.append(currentPage)
        return pages
    }

    static func totalPageCount(for report: SARLogPDFReport) -> Int {
        paginateRows(report.rows).count + noteRanges(for: report.notes).count
    }

    static func noteRanges(for notes: String) -> [NSRange] {
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedNotes.isEmpty else { return [] }

        let attributedString = NSAttributedString(
            string: trimmedNotes,
            attributes: [.font: notesFont]
        )
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        let textLength = (trimmedNotes as NSString).length
        let framePath = CGMutablePath()
        framePath.addRect(CGRect(x: 0, y: 0, width: notesTextWidth, height: notesTextHeight))

        var ranges: [NSRange] = []
        var start = 0
        while start < textLength {
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: start, length: 0),
                framePath,
                nil
            )
            let visibleRange = CTFrameGetVisibleStringRange(frame)
            guard visibleRange.length > 0 else { break }
            ranges.append(NSRange(location: start, length: visibleRange.length))
            start += visibleRange.length
        }

        return ranges
    }

    static func headerValueRect(in rect: CGRect) -> CGRect {
        let valueX = rect.minX + headerValueLeading
        let valueWidth = max(1, rect.maxX - valueX - headerHorizontalPadding)
        return CGRect(
            x: valueX,
            y: rect.minY + 3,
            width: valueWidth,
            height: max(1, rect.height - 6)
        )
    }

    static func standardTaskNumberFitsOnOneLine(_ taskNumber: String, in width: CGFloat) -> Bool {
        guard isStandardTaskNumber(taskNumber) else { return false }
        return oneLineTextWidth(taskNumber, font: standardTaskNumberFont(for: taskNumber, width: width)) <= width
    }

    static func standardTaskNumberFont(for taskNumber: String, width: CGFloat) -> UIFont {
        guard isStandardTaskNumber(taskNumber) else { return headerValueFont }

        let baseSize = headerValueFont.pointSize
        let measuredWidth = oneLineTextWidth(taskNumber, font: headerValueFont)
        guard measuredWidth > width, measuredWidth > 0 else { return headerValueFont }

        let fittedSize = max(6, floor(baseSize * width / measuredWidth))
        return .systemFont(ofSize: fittedSize)
    }

    private static func isStandardTaskNumber(_ taskNumber: String) -> Bool {
        let trimmed = taskNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count == 8 else { return false }

        let parts = trimmed.split(separator: "-", omittingEmptySubsequences: false)
        return parts.count == 2
            && parts[0].count == 2
            && parts[1].count == 5
            && parts.allSatisfy { $0.allSatisfy(\.isNumber) }
    }

    private static func oneLineTextWidth(_ text: String, font: UIFont) -> CGFloat {
        ceil((text as NSString).size(withAttributes: [.font: font]).width)
    }
}

enum SARLogPDFRenderer {
    static func data(for report: SARLogPDFReport) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextCreator as String: "SAR Log",
            kCGPDFContextTitle as String: "SAR Log \(displayOrBlank(report.taskNumber))"
        ]

        let renderer = UIGraphicsPDFRenderer(
            bounds: CGRect(origin: .zero, size: SARLogPDFLayout.pageSize),
            format: format
        )
        let rowPages = SARLogPDFLayout.paginateRows(report.rows)
        let notes = report.notes.trimmingCharacters(in: .whitespacesAndNewlines)
        let noteRanges = SARLogPDFLayout.noteRanges(for: notes)
        let totalPages = rowPages.count + noteRanges.count

        return renderer.pdfData { context in
            for (index, rows) in rowPages.enumerated() {
                context.beginPage()
                drawLogPage(
                    report: report,
                    rows: rows,
                    pageNumber: index + 1,
                    totalPages: totalPages,
                    in: context.cgContext
                )
            }

            for (index, range) in noteRanges.enumerated() {
                context.beginPage()
                drawNotesAppendix(
                    report: report,
                    notes: (notes as NSString).substring(with: range),
                    isContinuation: index > 0,
                    pageNumber: rowPages.count + index + 1,
                    totalPages: totalPages,
                    in: context.cgContext
                )
            }
        }
    }

    static func write(report: SARLogPDFReport, to url: URL) throws {
        try data(for: report).write(to: url, options: .atomic)
    }

    private static func drawLogPage(
        report: SARLogPDFReport,
        rows: [SARLogPDFRowLayout],
        pageNumber: Int,
        totalPages: Int,
        in context: CGContext
    ) {
        drawHeader(report: report, in: context)
        drawSubjectInfo(report: report, in: context)
        drawTableHeader(in: context)

        var y = SARLogPDFLayout.tableY + SARLogPDFLayout.tableHeaderHeight
        for row in rows {
            drawTableRow(row, y: y, in: context)
            y += row.height
        }

        drawFooter(pageNumber: pageNumber, totalPages: totalPages, in: context)
    }

    private static func drawHeader(report: SARLogPDFReport, in context: CGContext) {
        let x = SARLogPDFLayout.contentX
        let y = SARLogPDFLayout.headerY
        let width = SARLogPDFLayout.contentWidth
        let height = SARLogPDFLayout.headerHeight
        let leftWidth: CGFloat = 190
        let taskWidth: CGFloat = 135
        let middleWidth: CGFloat = 200
        let rowOneHeight: CGFloat = 34
        let rowTwoHeight: CGFloat = 24
        let rowThreeHeight = height - rowOneHeight - rowTwoHeight

        strokeRect(CGRect(x: x, y: y, width: width, height: height), lineWidth: 2, in: context)
        strokeLine(from: CGPoint(x: x, y: y + rowOneHeight), to: CGPoint(x: x + width, y: y + rowOneHeight), in: context)
        strokeLine(from: CGPoint(x: x, y: y + rowOneHeight + rowTwoHeight), to: CGPoint(x: x + width, y: y + rowOneHeight + rowTwoHeight), in: context)
        strokeLine(from: CGPoint(x: x + leftWidth, y: y), to: CGPoint(x: x + leftWidth, y: y + height), in: context)
        strokeLine(from: CGPoint(x: x + leftWidth + taskWidth, y: y), to: CGPoint(x: x + leftWidth + taskWidth, y: y + rowOneHeight), in: context)
        strokeLine(from: CGPoint(x: x + leftWidth + middleWidth, y: y + rowOneHeight + rowTwoHeight), to: CGPoint(x: x + leftWidth + middleWidth, y: y + height), in: context)

        drawText("LOG", in: CGRect(x: x, y: y + 6, width: leftWidth, height: 18), font: .boldSystemFont(ofSize: 17), alignment: .center)
        drawText("RECORD COMMS & MAJOR EVENTS", in: CGRect(x: x + 6, y: y + 25, width: leftWidth - 12, height: 12), font: .boldSystemFont(ofSize: 8), alignment: .center)

        drawTaskNumberLabelValue(value: report.taskNumber, in: CGRect(x: x + leftWidth, y: y, width: taskWidth, height: rowOneHeight))
        drawLabelValue(label: "FOR PERIOD:", value: dateTimeString(report.periodStart), in: CGRect(x: x + leftWidth + taskWidth, y: y, width: width - leftWidth - taskWidth, height: rowOneHeight / 2))
        drawLabelValue(label: "TO:", value: dateTimeString(report.periodEnd), in: CGRect(x: x + leftWidth + taskWidth, y: y + rowOneHeight / 2, width: width - leftWidth - taskWidth, height: rowOneHeight / 2))

        drawText("FOR OP.", in: CGRect(x: x + 6, y: y + rowOneHeight + 2, width: leftWidth - 12, height: 10), font: .systemFont(ofSize: 8), alignment: .left)
        drawText("PERIOD #", in: CGRect(x: x + 6, y: y + rowOneHeight + 13, width: leftWidth - 12, height: 10), font: .systemFont(ofSize: 8), alignment: .left)
        drawLabelValue(label: "TASK NAME:", value: report.taskName, in: CGRect(x: x + leftWidth, y: y + rowOneHeight, width: width - leftWidth, height: rowTwoHeight))

        drawLabelValue(label: "RADIO OP. (OPERATIONS):", value: "", in: CGRect(x: x, y: y + rowOneHeight + rowTwoHeight, width: leftWidth, height: rowThreeHeight))
        drawLabelValue(label: "LOG KEEPER:", value: report.logKeeper, in: CGRect(x: x + leftWidth, y: y + rowOneHeight + rowTwoHeight, width: middleWidth, height: rowThreeHeight))
        drawText("STATION", in: CGRect(x: x + leftWidth + middleWidth + 6, y: y + rowOneHeight + rowTwoHeight + 2, width: width - leftWidth - middleWidth - 12, height: 10), font: .systemFont(ofSize: 8), alignment: .left)
        drawText("CALLSIGN:", in: CGRect(x: x + leftWidth + middleWidth + 6, y: y + rowOneHeight + rowTwoHeight + 15, width: width - leftWidth - middleWidth - 12, height: 10), font: .systemFont(ofSize: 8), alignment: .left)
    }

    private static func drawTableHeader(in context: CGContext) {
        let x = SARLogPDFLayout.contentX
        let y = SARLogPDFLayout.tableY
        let timeWidth = SARLogPDFLayout.timeColumnWidth
        let calledWidth = SARLogPDFLayout.stationCalledColumnWidth
        let thisIsWidth = SARLogPDFLayout.thisIsColumnWidth
        let subjectWidth = SARLogPDFLayout.subjectColumnWidth
        let height = SARLogPDFLayout.tableHeaderHeight
        let stationHeaderHeight: CGFloat = 20

        UIColor(white: 0.9, alpha: 1).setFill()
        context.fill(CGRect(x: x, y: y, width: SARLogPDFLayout.contentWidth, height: height))

        strokeRect(CGRect(x: x, y: y, width: SARLogPDFLayout.contentWidth, height: height), in: context)
        strokeLine(from: CGPoint(x: x + timeWidth, y: y), to: CGPoint(x: x + timeWidth, y: y + height), in: context)
        strokeLine(from: CGPoint(x: x + timeWidth + calledWidth, y: y + stationHeaderHeight), to: CGPoint(x: x + timeWidth + calledWidth, y: y + height), in: context)
        strokeLine(from: CGPoint(x: x + timeWidth + calledWidth + thisIsWidth, y: y), to: CGPoint(x: x + timeWidth + calledWidth + thisIsWidth, y: y + height), in: context)
        strokeLine(from: CGPoint(x: x + timeWidth, y: y + stationHeaderHeight), to: CGPoint(x: x + timeWidth + calledWidth + thisIsWidth, y: y + stationHeaderHeight), in: context)

        drawText("TIME", in: CGRect(x: x, y: y + 13, width: timeWidth, height: 12), font: .systemFont(ofSize: 9), alignment: .center)
        drawText("STATION I.D.", in: CGRect(x: x + timeWidth, y: y + 5, width: calledWidth + thisIsWidth, height: 10), font: .systemFont(ofSize: 8), alignment: .center)
        drawText("STN.\nCALLED", in: CGRect(x: x + timeWidth, y: y + stationHeaderHeight + 2, width: calledWidth, height: 18), font: .boldSystemFont(ofSize: 8), alignment: .center)
        drawText("THIS IS", in: CGRect(x: x + timeWidth + calledWidth, y: y + stationHeaderHeight + 7, width: thisIsWidth, height: 10), font: .boldSystemFont(ofSize: 8), alignment: .center)
        drawText("SUBJECT", in: CGRect(x: x + timeWidth + calledWidth + thisIsWidth, y: y + 13, width: subjectWidth, height: 12), font: .systemFont(ofSize: 9), alignment: .center)
    }

    private static func drawSubjectInfo(report: SARLogPDFReport, in context: CGContext) {
        let rect = CGRect(
            x: SARLogPDFLayout.contentX,
            y: SARLogPDFLayout.subjectInfoY,
            width: SARLogPDFLayout.contentWidth,
            height: SARLogPDFLayout.subjectInfoHeight
        )
        strokeRect(rect, in: context)
        drawText(
            "SUBJECT / LOCATION",
            in: CGRect(x: rect.minX + 6, y: rect.minY + 4, width: 112, height: 10),
            font: SARLogPDFLayout.headerLabelFont,
            alignment: .left
        )

        let subject = displayOrBlank(report.taskName)
        let location = displayOrBlank(report.location)
        let value: String
        switch (subject.isEmpty, location.isEmpty) {
        case (true, true):
            value = ""
        case (false, true):
            value = "Subject: \(subject)"
        case (true, false):
            value = "Location: \(location)"
        case (false, false):
            value = "Subject: \(subject)    Location: \(location)"
        }

        drawText(
            value,
            in: CGRect(x: rect.minX + 6, y: rect.minY + 15, width: rect.width - 12, height: 14),
            font: SARLogPDFLayout.headerValueFont,
            alignment: .left,
            lineBreakMode: .byTruncatingTail
        )
    }

    private static func drawTableRow(_ layout: SARLogPDFRowLayout, y: CGFloat, in context: CGContext) {
        let x = SARLogPDFLayout.contentX
        let timeWidth = SARLogPDFLayout.timeColumnWidth
        let calledWidth = SARLogPDFLayout.stationCalledColumnWidth
        let thisIsWidth = SARLogPDFLayout.thisIsColumnWidth
        let subjectWidth = SARLogPDFLayout.subjectColumnWidth
        let height = layout.height

        strokeRect(CGRect(x: x, y: y, width: SARLogPDFLayout.contentWidth, height: height), in: context)
        strokeLine(from: CGPoint(x: x + timeWidth, y: y), to: CGPoint(x: x + timeWidth, y: y + height), in: context)
        strokeLine(from: CGPoint(x: x + timeWidth + calledWidth, y: y), to: CGPoint(x: x + timeWidth + calledWidth, y: y + height), in: context)
        strokeLine(from: CGPoint(x: x + timeWidth + calledWidth + thisIsWidth, y: y), to: CGPoint(x: x + timeWidth + calledWidth + thisIsWidth, y: y + height), in: context)

        drawText(
            timeString(layout.row.timestamp),
            in: CGRect(x: x + SARLogPDFLayout.rowPadding, y: y + SARLogPDFLayout.rowPadding, width: timeWidth - (SARLogPDFLayout.rowPadding * 2), height: height - (SARLogPDFLayout.rowPadding * 2)),
            font: SARLogPDFLayout.timeFont,
            alignment: .center
        )
        drawText(
            layout.row.subject,
            in: CGRect(
                x: x + timeWidth + calledWidth + thisIsWidth + SARLogPDFLayout.rowPadding,
                y: y + SARLogPDFLayout.rowPadding,
                width: subjectWidth - (SARLogPDFLayout.rowPadding * 2),
                height: height - (SARLogPDFLayout.rowPadding * 2)
            ),
            font: SARLogPDFLayout.rowFont,
            alignment: .left
        )
    }

    private static func drawNotesAppendix(
        report: SARLogPDFReport,
        notes: String,
        isContinuation: Bool,
        pageNumber: Int,
        totalPages: Int,
        in context: CGContext
    ) {
        let x = SARLogPDFLayout.contentX
        var y = SARLogPDFLayout.headerY
        let title = isContinuation ? "Notes Appendix (continued)" : "Notes Appendix"
        drawText(title, in: CGRect(x: x, y: y, width: SARLogPDFLayout.contentWidth, height: 26), font: .boldSystemFont(ofSize: 18), alignment: .left)
        y += 28
        drawText(
            "Task # \(displayOrBlank(report.taskNumber))   Task name: \(displayOrBlank(report.taskName))   Log keeper: \(displayOrBlank(report.logKeeper))",
            in: CGRect(x: x, y: y, width: SARLogPDFLayout.contentWidth, height: 16),
            font: .systemFont(ofSize: 9),
            alignment: .left
        )
        y += 22
        strokeRect(CGRect(x: x, y: y, width: SARLogPDFLayout.contentWidth, height: SARLogPDFLayout.footerY - y - 8), in: context)
        drawText(
            notes,
            in: CGRect(
                x: x + SARLogPDFLayout.notesTextPadding,
                y: y + SARLogPDFLayout.notesTextPadding,
                width: SARLogPDFLayout.notesTextWidth,
                height: SARLogPDFLayout.notesTextHeight
            ),
            font: SARLogPDFLayout.notesFont,
            alignment: .left
        )
        drawFooter(pageNumber: pageNumber, totalPages: totalPages, in: context)
    }

    private static func drawFooter(pageNumber: Int, totalPages: Int, in context: CGContext) {
        let x = SARLogPDFLayout.contentX
        let y = SARLogPDFLayout.footerY
        drawText("PAGE \(pageNumber) OF \(totalPages)", in: CGRect(x: x + 6, y: y + 10, width: 150, height: 12), font: .systemFont(ofSize: 8), alignment: .left)
        strokeRect(CGRect(x: x + SARLogPDFLayout.contentWidth - 64, y: y, width: 64, height: SARLogPDFLayout.footerHeight), lineWidth: 2, in: context)
        drawText("ICS 309", in: CGRect(x: x + SARLogPDFLayout.contentWidth - 64, y: y + 4, width: 64, height: 16), font: .boldSystemFont(ofSize: 14), alignment: .center)
        drawText("REV 04/12/13", in: CGRect(x: x + SARLogPDFLayout.contentWidth - 58, y: y + 26, width: 58, height: 10), font: .systemFont(ofSize: 7), alignment: .center)
    }

    private static func drawLabelValue(label: String, value: String, in rect: CGRect) {
        drawText(label, in: rect.insetBy(dx: SARLogPDFLayout.headerHorizontalPadding, dy: 3), font: SARLogPDFLayout.headerLabelFont, alignment: .left)
        guard !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        drawText(value, in: SARLogPDFLayout.headerValueRect(in: rect), font: SARLogPDFLayout.headerValueFont, alignment: .left)
    }

    private static func drawTaskNumberLabelValue(value: String, in rect: CGRect) {
        drawText("TASK #", in: rect.insetBy(dx: SARLogPDFLayout.headerHorizontalPadding, dy: 3), font: SARLogPDFLayout.headerLabelFont, alignment: .left)

        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let valueRect = SARLogPDFLayout.headerValueRect(in: rect)
        let font = SARLogPDFLayout.standardTaskNumberFont(for: trimmed, width: valueRect.width)
        drawText(trimmed, in: valueRect, font: font, alignment: .left, lineBreakMode: .byClipping)
    }

    private static func drawText(
        _ text: String,
        in rect: CGRect,
        font: UIFont,
        alignment: NSTextAlignment,
        lineBreakMode: NSLineBreakMode = .byWordWrapping
    ) {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        paragraphStyle.lineBreakMode = lineBreakMode
        (text as NSString).draw(
            in: rect,
            withAttributes: [
                .font: font,
                .foregroundColor: UIColor.black,
                .paragraphStyle: paragraphStyle
            ]
        )
    }

    private static func strokeRect(_ rect: CGRect, lineWidth: CGFloat = 0.75, in context: CGContext) {
        context.saveGState()
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(lineWidth)
        context.stroke(rect)
        context.restoreGState()
    }

    private static func strokeLine(from start: CGPoint, to end: CGPoint, lineWidth: CGFloat = 0.75, in context: CGContext) {
        context.saveGState()
        context.setStrokeColor(UIColor.black.cgColor)
        context.setLineWidth(lineWidth)
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
        context.restoreGState()
    }

    private static func dateTimeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm"
        return formatter.string(from: date)
    }

    private static func timeString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private static func displayOrBlank(_ value: String) -> String {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "" : trimmed
    }
}

enum SARLogPDFFileExporter {
    static func writeTemporaryPDF(report: SARLogPDFReport) throws -> URL {
        let filename = sanitizedFilename(for: report)
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try SARLogPDFRenderer.write(report: report, to: url)
        return url
    }

    private static func sanitizedFilename(for report: SARLogPDFReport) -> String {
        let titleParts = [
            "SARLog",
            report.taskNumber,
            report.taskName
        ]
        let base = titleParts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let fallback = base.isEmpty ? "SARLog-\(UUID().uuidString)" : base
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        let cleaned = fallback
            .replacingOccurrences(of: " ", with: "-")
            .unicodeScalars
            .map { allowed.contains($0) ? Character($0) : "-" }
        let collapsed = String(cleaned).replacingOccurrences(of: "--", with: "-")
        return "\(collapsed).pdf"
    }
}
