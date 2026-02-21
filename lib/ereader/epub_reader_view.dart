import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:epub_parser/epub_parser.dart' hide Image;
import 'package:shared_preferences/shared_preferences.dart';

import 'epub_models.dart';
import 'epub_parser.dart';

class EpubReaderPage extends StatefulWidget {
  final Uint8List epubBytes;
  const EpubReaderPage({super.key, required this.epubBytes});

  @override
  State<EpubReaderPage> createState() => _EpubReaderPageState();
}

class _EpubReaderPageState extends State<EpubReaderPage> {
  bool _isInitialized = false;
  String? _title, _error;
  final List<EpubSection> _sections = [];
  List<EpubPage> _pages = [];
  final Map<String, Uint8List> _images = {};

  PageController? _pageController;
  int _currentPage = 0;
  final EpubParser _parser = EpubParser();

  @override
  void initState() {
    super.initState();
    _prepareBook();
  }

  Future<void> _prepareBook() async {
    try {
      final book = await EpubReader.readBook(widget.epubBytes);
      _title = book.Title ?? "EPUB Reader";
      book.Content?.Images?.forEach((k, v) {
        if (v.Content != null) _images[k] = Uint8List.fromList(v.Content!);
      });
      _extractSections(book.Chapters ?? []);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _extractSections(List<EpubChapter> chapters, [int depth = 0]) {
    for (final ch in chapters) {
      if (ch.HtmlContent?.trim().isNotEmpty ?? false) {
        _sections.add(EpubSection(title: ch.Title ?? "Section", html: ch.HtmlContent!, depth: depth));
      }
      if (ch.SubChapters != null) _extractSections(ch.SubChapters!, depth + 1);
    }
  }

  Future<void> _initializeReader(BoxConstraints constraints) async {
    if (_isInitialized || _title == null) return;

    _pages = _parser.paginate(
      sections: _sections,
      maxHeight: constraints.maxHeight,
      maxWidth: constraints.maxWidth,
      horizontalPadding: 24.0,
    );

    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt('epub_pos_${_title!.hashCode}') ?? 0;

    _currentPage = (savedPage < _pages.length) ? savedPage : 0;
    _pageController = PageController(initialPage: _currentPage);

    if (mounted) setState(() => _isInitialized = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(body: Center(child: Text("Error: $_error")));

    return Scaffold(
      appBar: AppBar(title: Text(_isInitialized ? _sections[_pages[_currentPage].sectionIndex].title : "Loading...")),
      drawer: _isInitialized ? _buildDrawer() : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!_isInitialized && _title != null && constraints.maxWidth > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _initializeReader(constraints));
              return const Center(child: CircularProgressIndicator());
            }
            if (!_isInitialized) return const Center(child: CircularProgressIndicator());

            return Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _pages.length,
                  onPageChanged: (i) {
                    setState(() => _currentPage = i);
                    _saveProgress(i);
                  },
                  itemBuilder: (context, index) => _buildPageContent(index),
                ),
                _buildNavigationArrows(),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveProgress(int index) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('epub_pos_${_title!.hashCode}', index);
  }

  Widget _buildPageContent(int index) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
      child: SingleChildScrollView(
        child: Html(
          data: _pages[index].html,
          extensions: [
            TagExtension(
              tagsToExtend: {"img"},
              builder: (ctx) {
                String? src = ctx.attributes['src'];
                if (src != null) {
                  final imageData = _images[src] ?? _images[src.split('/').last];
                  if (imageData != null) return Image.memory(imageData);
                }
                return const SizedBox.shrink();
              },
            ),
          ],
          style: {
            "body": Style(fontSize: FontSize(_parser.fontSize), lineHeight: LineHeight(_parser.lineHeight), margin: Margins.zero),
            "p": Style(margin: Margins.only(bottom: _parser.paragraphSpacing)),
          },
        ),
      ),
    );
  }

  Widget _buildNavigationArrows() {
    return Positioned(
      bottom: 10, left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 20),
            onPressed: _currentPage > 0 ? () => _pageController?.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
          ),
          Text("Page ${_currentPage + 1} of ${_pages.length}"),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios, size: 20),
            onPressed: _currentPage < _pages.length - 1 ? () => _pageController?.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView.builder(
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final s = _sections[index];
          return ListTile(
            contentPadding: EdgeInsets.only(left: 16 + (s.depth * 16.0)),
            title: Text(s.title),
            onTap: () {
              final pIndex = _pages.indexWhere((p) => p.sectionIndex == index);
              if (pIndex != -1) _pageController?.jumpToPage(pIndex);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}