import 'package:flutter/material.dart';
import 'epub_models.dart';

class EpubParser {
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;

  EpubParser({
    this.fontSize = 18.0,
    this.lineHeight = 1.4,
    this.paragraphSpacing = 16.0,
  });

  List<EpubPage> paginate({
    required List<EpubSection> sections,
    required double maxHeight,
    required double maxWidth,
    required double horizontalPadding,
  }) {
    final List<EpubPage> pages = [];
    final double availableWidth = maxWidth - (horizontalPadding * 2);
    final double targetHeight = maxHeight - (horizontalPadding * 2) - 120; // Accounting for UI

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      // Indent paragraphs for a book-like feel
      final processedHtml = section.html.replaceAll('<p>', '<p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;');
      final List<String> blocks = _splitHtmlIntoBlocks(processedHtml);

      String currentPageHtml = "";
      double currentPageHeight = 0;

      for (int j = 0; j < blocks.length; j++) {
        String blockHtml = blocks[j];
        double blockHeight = _measureHeight(blockHtml, availableWidth);

        if (currentPageHeight + blockHeight <= targetHeight) {
          currentPageHtml += blockHtml;
          currentPageHeight += blockHeight + (blockHtml.contains('<h') ? 24 : paragraphSpacing);
        } else {
          final split = _splitBlockToFit(blockHtml, availableWidth, targetHeight - currentPageHeight);
          if (split.fits.isNotEmpty) currentPageHtml += split.fits;
          pages.add(EpubPage(html: currentPageHtml, sectionIndex: i));

          if (split.remains.isNotEmpty) blocks.insert(j + 1, split.remains);
          currentPageHtml = "";
          currentPageHeight = 0;
        }
      }
      if (currentPageHtml.isNotEmpty) {
        pages.add(EpubPage(html: currentPageHtml, sectionIndex: i));
      }
    }
    return pages;
  }

  double _measureHeight(String html, double width) {
    if (html.contains('<img')) return 250.0; // Estimated image height
    final text = html.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();
    if (text.isEmpty) return 0;

    double measureSize = html.contains('<h') ? fontSize * 1.5 : fontSize;
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
              fontSize: measureSize,
              height: lineHeight,
              fontWeight: html.contains('<h') ? FontWeight.bold : FontWeight.normal
          )
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: width);
    return tp.size.height;
  }

  List<String> _splitHtmlIntoBlocks(String html) {
    final regex = RegExp(
      r'(<p[\s\S]*?>[\s\S]*?<\/p>|<div[\s\S]*?>[\s\S]*?<\/div>|<h[1-6][\s\S]*?>[\s\S]*?<\/h[1-6]>|<li[\s\S]*?>[\s\S]*?<\/li>|<title[\s\S]*?>[\s\S]*?<\/title>|<img[\s\S]*?>|<figure[\s\S]*?>[\s\S]*?<\/figure>)',
      caseSensitive: false,
    );
    final matches = regex.allMatches(html);
    return matches.isEmpty ? [html] : matches.map((m) {
      String block = m.group(0)!;
      return block.startsWith('<li') ? '<ul>$block</ul>' : block;
    }).toList();
  }

  SplitResult _splitBlockToFit(String html, double width, double remainingHeight) {
    if (html.contains('<img')) return SplitResult(fits: "", remains: html);
    final text = html.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '');
    if (text.isEmpty) return SplitResult(fits: "", remains: html);

    final tagMatch = RegExp(r'<(p|h[1-6]|div|li|title)[^>]*>', caseSensitive: false).firstMatch(html);
    final String tagName = tagMatch?.group(1) ?? "p";
    final String openTag = tagMatch?.group(0) ?? "<$tagName>";

    final tp = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, height: lineHeight)),
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: width);
    final List<LineMetrics> lines = tp.computeLineMetrics();

    double currentHeight = 0;
    int charOffset = 0;
    for (int i = 0; i < lines.length; i++) {
      if (currentHeight + lines[i].height > remainingHeight) break;
      currentHeight += lines[i].height;
      charOffset = tp.getPositionForOffset(Offset(width, currentHeight - (lines[i].height / 2))).offset;
    }

    return SplitResult(
      fits: charOffset == 0 ? "" : "$openTag${text.substring(0, charOffset)}</$tagName>",
      remains: "$openTag${text.substring(charOffset)}</$tagName>",
    );
  }
}