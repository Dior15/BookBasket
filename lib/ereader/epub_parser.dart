import 'package:flutter/material.dart';
import 'epub_models.dart';

class EpubParser {
  final double fontSize;
  final double lineHeight;
  final double paragraphSpacing;
  final String? fontFamily;

  EpubParser({
    this.fontSize = 18.0,
    this.lineHeight = 1.4,
    this.paragraphSpacing = 16.0,
    this.fontFamily,
  });

  /// Scale factor applied to every text-block height measured by TextPainter.
  /// flutter_html's rendering pipeline (RichText → RenderParagraph → HtmlWidget)
  /// consistently produces slightly taller output than raw TextPainter layout.
  /// 1.12 was calibrated against real EPUB content across portrait and landscape.
  static const double _kHeightScale = 1.12;

  List<EpubPage> paginate({
    required List<EpubSection> sections,
    required double contentHeight,
    required double contentWidth,
    Map<String, Size>? imageSizes,
  }) {
    final List<EpubPage> pages = [];
    final double availableWidth = contentWidth;
    // Clamp to a minimum so landscape mode never goes zero/negative
    final double targetHeight = contentHeight < 50.0 ? 50.0 : contentHeight;

    for (int i = 0; i < sections.length; i++) {
      final section = sections[i];
      // Indent paragraphs for a book-like feel
      final processedHtml = section.html.replaceAll('<p>', '<p>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;');
      final List<String> blocks = _splitHtmlIntoBlocks(processedHtml);

      String currentPageHtml = "";
      double currentPageHeight = 0;

      for (int j = 0; j < blocks.length; j++) {
        String blockHtml = blocks[j];

        // Pass the imageSizes map into the measuring function
        double blockHeight = _measureHeight(blockHtml, availableWidth, imageSizes);

        if (currentPageHeight + blockHeight <= targetHeight) {
          currentPageHtml += blockHtml;
          currentPageHeight += blockHeight + (blockHtml.contains('<h') ? 24 : paragraphSpacing);
        } else {
          final split = _splitBlockToFit(blockHtml, availableWidth, targetHeight - currentPageHeight);

          if (split.fits.isNotEmpty) {
            // Some text fit — add it and re-queue the remainder
            currentPageHtml += split.fits;
            pages.add(EpubPage(html: currentPageHtml, sectionIndex: i));
            if (split.remains.isNotEmpty) blocks.insert(j + 1, split.remains);
          } else if (currentPageHeight > 0) {
            // Nothing fit but current page has content — flush page and retry this block
            pages.add(EpubPage(html: currentPageHtml, sectionIndex: i));
            blocks.insert(j + 1, blockHtml);
          } else {
            // Nothing fit AND page is empty — force entire block onto its own page
            // to guarantee forward progress (prevents infinite loop for images, etc.)
            pages.add(EpubPage(html: blockHtml, sectionIndex: i));
          }

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

  /// Decodes common HTML entities to their real Unicode characters, then
  /// strips all remaining HTML tags. This ensures TextPainter measures the
  /// exact same character sequence that flutter_html renders — including the
  /// &nbsp; indent spaces we inject — so line-wrap counts are accurate.
  String _htmlToPlainText(String html) {
    // 1. Strip tags first
    String text = html.replaceAll(RegExp(r'<[^>]*>'), '');
    // 2. Decode entities to real characters so TextPainter sees them
    text = text
        .replaceAll('&nbsp;', '\u00A0') // non-breaking space
        .replaceAll('&amp;',  '&')
        .replaceAll('&lt;',   '<')
        .replaceAll('&gt;',   '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&apos;', "'")
        .replaceAll('&mdash;', '\u2014')
        .replaceAll('&ndash;', '\u2013')
        .replaceAll('&lsquo;', '\u2018')
        .replaceAll('&rsquo;', '\u2019')
        .replaceAll('&ldquo;', '\u201C')
        .replaceAll('&rdquo;', '\u201D')
        // Numeric entities: &#160; or &#xA0;
        .replaceAllMapped(RegExp(r'&#x([0-9a-fA-F]+);'), (m) =>
            String.fromCharCode(int.parse(m.group(1)!, radix: 16)))
        .replaceAllMapped(RegExp(r'&#([0-9]+);'), (m) =>
            String.fromCharCode(int.parse(m.group(1)!)));
    return text.trim();
  }

  // Measure exact image height based on the map, capping at 400px
  double _measureHeight(String html, double width, Map<String, Size>? imageSizes) {
    if (html.contains('<img')) {
      if (imageSizes != null) {
        final srcMatch = RegExp(r'src="([^"]+)"').firstMatch(html)
            ?? RegExp(r"src='([^']+)'").firstMatch(html);
        if (srcMatch != null) {
          final src = srcMatch.group(1)!;
          final size = imageSizes[src] ?? imageSizes[src.split('/').last];
          if (size != null) {
            double calculatedHeight = size.height;
            if (size.width > width) {
              calculatedHeight = (size.height / size.width) * width;
            }
            return calculatedHeight > 400.0 ? 400.0 : calculatedHeight;
          }
        }
      }
      return 400.0;
    }

    // Use entity-aware conversion so TextPainter sees &nbsp; as a real space
    final text = _htmlToPlainText(html);
    if (text.isEmpty) return 0;

    final bool isHeading = html.contains('<h');
    final double measureSize = isHeading ? fontSize * 1.5 : fontSize;
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: measureSize,
          height: lineHeight,
          fontWeight: isHeading ? FontWeight.bold : FontWeight.normal,
          fontFamily: fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: width);
    // Scale up to match flutter_html's actual rendered height
    return tp.size.height * _kHeightScale;
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

    // Decode entities so character offsets match the rendered text
    final text = _htmlToPlainText(html);
    if (text.isEmpty) return SplitResult(fits: "", remains: html);

    final tagMatch = RegExp(r'<(p|h[1-6]|div|li|title)[^>]*>', caseSensitive: false).firstMatch(html);
    final String tagName = tagMatch?.group(1) ?? "p";
    final String openTag = tagMatch?.group(0) ?? "<$tagName>";

    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, height: lineHeight, fontFamily: fontFamily),
      ),
      textDirection: TextDirection.ltr,
    );
    tp.layout(maxWidth: width);
    final List<LineMetrics> lines = tp.computeLineMetrics();

    double currentHeight = 0;
    int charOffset = 0;
    for (int i = 0; i < lines.length; i++) {
      if (currentHeight + lines[i].height > remainingHeight && i > 0) break;
      currentHeight += lines[i].height;
      charOffset = tp.getPositionForOffset(
        Offset(width, currentHeight - (lines[i].height / 2)),
      ).offset;
      // Always fit at least one line to guarantee forward progress
      if (i == 0 && charOffset == 0 && lines.isNotEmpty) {
        charOffset = tp.getPositionForOffset(Offset(width, lines[0].height / 2)).offset;
        if (charOffset == 0 && text.isNotEmpty) charOffset = 1;
      }
    }

    return SplitResult(
      fits: charOffset == 0 ? "" : "$openTag${text.substring(0, charOffset)}</$tagName>",
      remains: "$openTag${text.substring(charOffset)}</$tagName>",
    );
  }
}