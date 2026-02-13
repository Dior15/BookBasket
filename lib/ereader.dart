import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:epub_parser/epub_parser.dart';

class EpubReaderPage extends StatefulWidget {
  final Uint8List epubBytes;

  const EpubReaderPage({super.key, required this.epubBytes});

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  bool _loading = true;
  String? _title;
  String? _error;
  List<_EpubSection> _sections = [];

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    try {
      final book = await EpubReader.readBook(widget.epubBytes);

      _title = book.Title ?? 'EPUB Reader';

      final sections = _extractSectionsFromChapters(book.Chapters ?? []);
      if (sections.isEmpty) {
        _error = 'No readable content found in this EPUB.';
      } else {
        _sections = sections;
      }
    } catch (e) {
      _error = 'Failed to parse EPUB: $e';
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<_EpubSection> _extractSectionsFromChapters(List<EpubChapter> chapters) {
    final sections = <_EpubSection>[];

    void walk(List<EpubChapter> list) {
      for (final ch in list) {
        final html = ch.HtmlContent;
        if (html != null && html.trim().isNotEmpty) {
          sections.add(
            _EpubSection(
              title: (ch.Title?.trim().isNotEmpty ?? false)
                  ? ch.Title!.trim()
                  : 'Section ${sections.length + 1}',
              html: html,
            ),
          );
        }
        if (ch.SubChapters != null && ch.SubChapters!.isNotEmpty) {
          walk(ch.SubChapters!);
        }
      }
    }

    walk(chapters);
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(_title ?? 'EPUB Reader')),
        body: Center(child: Text(_error!)),
      );
    }

    if (_sections.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(_title ?? 'EPUB Reader')),
        body: const Center(child: Text('No readable content found')),
      );
    }

    return DefaultTabController(
      length: _sections.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title ?? 'EPUB Reader'),
          bottom: TabBar(
            isScrollable: true,
            tabs: [
              for (int i = 0; i < _sections.length; i++)
                Tab(text: _sections[i].title),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            for (final section in _sections)
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Html(data: section.html),
              ),
          ],
        ),
      ),
    );
  }
}

class _EpubSection {
  final String title;
  final String html;

  _EpubSection({required this.title, required this.html});
}