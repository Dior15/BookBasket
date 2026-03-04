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

  List<EpubPage> paginate({
    required List<EpubSection> sections,
    required double maxHeight,
    required double maxWidth,
    required double horizontalPadding,
    Map<String, Size>? imageSizes, // Accept image sizes
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

        // Pass the imageSizes map into the measuring function
        double blockHeight = _measureHeight(blockHtml, availableWidth, imageSizes);

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

  // Measure exact image height based on the map, capping at 500px
  double _measureHeight(String html, double width, Map<String, Size>? imageSizes) {
    if (html.contains('<img')) {
      if (imageSizes != null) {
        // Find the src attribute to identify the image
        final srcMatch = RegExp(r'src="([^"]+)"').firstMatch(html) ?? RegExp(r"src='([^']+)'").firstMatch(html);
        if (srcMatch != null) {
          final src = srcMatch.group(1)!;
          final size = imageSizes[src] ?? imageSizes[src.split('/').last];

          if (size != null) {
            double calculatedHeight = size.height;
            // Scale height proportionally if image is wider than the screen
            if (size.width > width) {
              calculatedHeight = (size.height / size.width) * width;
            }

            // FIX: Reserve exact size UNLESS it's taller than 500, then cap it at 500!
            return calculatedHeight > 400.0 ? 400.0 : calculatedHeight;
          }
        }
      }
      return 400.0; // Fallback if image isn't found
    }

    final text = html.replaceAll(RegExp(r'<[^>]*>|&[^;]+;'), '').trim();
    if (text.isEmpty) return 0;

    double measureSize = html.contains('<h') ? fontSize * 1.5 : fontSize;
    final tp = TextPainter(
      text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: measureSize,
            height: lineHeight,
            fontWeight: html.contains('<h') ? FontWeight.bold : FontWeight.normal,
            fontFamily: fontFamily,
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
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, height: lineHeight, fontFamily: fontFamily)),
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