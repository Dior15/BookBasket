import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:epub_parser/epub_parser.dart' hide Image;
import 'package:shared_preferences/shared_preferences.dart';

import 'epub_models.dart';
import 'epub_parser.dart';
import '../animations/page_flip.dart'; // Make sure to import the new file

enum ReaderTheme { light, dark, sepia }

class ReaderThemeColors {
  final Color background;
  final Color text;

  ReaderThemeColors({required this.background, required this.text});

  static ReaderThemeColors get(ReaderTheme theme) {
    switch (theme) {
      case ReaderTheme.dark:
        return ReaderThemeColors(
          background: const Color(0xFF121212),
          text: Colors.white70,
        );
      case ReaderTheme.sepia:
        return ReaderThemeColors(
          background: const Color(0xFFF4ECD8),
          text: const Color(0xFF5B4636),
        );
      case ReaderTheme.light:
      default:
        return ReaderThemeColors(
          background: Colors.white,
          text: Colors.black87,
        );
    }
  }
}

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
  ReaderTheme _readerTheme = ReaderTheme.light;

  @override
  void initState() {
    super.initState();
    _loadTheme();
    _prepareBook();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('reader_theme') ?? 'light';
    if (mounted) {
      setState(() {
        _readerTheme = ReaderTheme.values.firstWhere(
              (e) => e.name == themeName,
          orElse: () => ReaderTheme.light,
        );
      });
    }
  }

  Future<void> _saveTheme(ReaderTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reader_theme', theme.name);
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

    final themeColors = ReaderThemeColors.get(_readerTheme);

    return Scaffold(
      backgroundColor: themeColors.background,
      appBar: AppBar(
        title: Text(_isInitialized ? _sections[_pages[_currentPage].sectionIndex].title : "Loading..."),
        backgroundColor: themeColors.background,
        foregroundColor: themeColors.text,
        elevation: 0,
        actions: [
          if (_isInitialized)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
        ],
      ),
      drawer: _isInitialized ? _buildDrawer(themeColors) : null,
      endDrawer: _isInitialized ? _buildEndDrawer(themeColors) : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (!_isInitialized && _title != null && constraints.maxWidth > 0) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _initializeReader(constraints));
              return const Center(child: CircularProgressIndicator());
            }
            if (!_isInitialized) return const Center(child: CircularProgressIndicator());

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Cleanly utilize the isolated animation component here
                PageFlipView(
                  controller: _pageController!,
                  currentPage: _currentPage,
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
    final themeColors = ReaderThemeColors.get(_readerTheme);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: themeColors.background,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
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
            "body": Style(
              fontSize: FontSize(_parser.fontSize),
              lineHeight: LineHeight(_parser.lineHeight),
              margin: Margins.zero,
              color: themeColors.text,
            ),
            "p": Style(margin: Margins.only(bottom: _parser.paragraphSpacing)),
            "h1": Style(color: themeColors.text),
            "h2": Style(color: themeColors.text),
            "h3": Style(color: themeColors.text),
          },
        ),
      ),
    );
  }

  Widget _buildNavigationArrows() {
    final themeColors = ReaderThemeColors.get(_readerTheme);
    return Positioned(
      bottom: 10, left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios, size: 20, color: themeColors.text),
            onPressed: _currentPage > 0 ? () => _pageController?.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.easeOutQuad) : null,
          ),
          Text(
            "Page ${_currentPage + 1} of ${_pages.length}",
            style: TextStyle(color: themeColors.text),
          ),
          IconButton(
            icon: Icon(Icons.arrow_forward_ios, size: 20, color: themeColors.text),
            onPressed: _currentPage < _pages.length - 1 ? () => _pageController?.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeOutQuad) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(ReaderThemeColors themeColors) {
    return Drawer(
      backgroundColor: themeColors.background,
      child: ListView.builder(
        itemCount: _sections.length,
        itemBuilder: (context, index) {
          final s = _sections[index];
          return ListTile(
            contentPadding: EdgeInsets.only(left: 16 + (s.depth * 16.0)),
            title: Text(s.title, style: TextStyle(color: themeColors.text)),
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

  Widget _buildEndDrawer(ReaderThemeColors themeColors) {
    return Drawer(
      backgroundColor: themeColors.background,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Reader Settings",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: themeColors.text,
                ),
              ),
            ),
            Divider(color: themeColors.text.withOpacity(0.2)),
            ListTile(
              title: Text("Theme", style: TextStyle(color: themeColors.text)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _themeButton(ReaderTheme.light, Colors.white, Colors.black),
                    _themeButton(ReaderTheme.dark, Colors.black, Colors.white),
                    _themeButton(ReaderTheme.sepia, const Color(0xFFF4ECD8), const Color(0xFF5B4636)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeButton(ReaderTheme theme, Color bg, Color text) {
    bool isSelected = _readerTheme == theme;
    return GestureDetector(
      onTap: () {
        setState(() => _readerTheme = theme);
        _saveTheme(theme);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: bg,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.withOpacity(0.5),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 4, spreadRadius: 2)] : null,
        ),
        child: Center(
          child: Text(
            "A",
            style: TextStyle(color: text, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }
}