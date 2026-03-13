import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:epub_parser/epub_parser.dart' hide Image;
import 'package:shared_preferences/shared_preferences.dart';

import 'epub_models.dart';
import 'epub_parser.dart';
import '../animations/page_flip.dart';

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

  final Map<String, Size> _imageSizes = {};

  PageController? _pageController;
  int _currentPage = 0;

  // NEW: Store bookmarked page indices
  Set<int> _bookmarks = {};

  EpubParser _parser = EpubParser();
  ReaderTheme _readerTheme = ReaderTheme.light;

  String _fontFamily = 'System Default';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _prepareBook();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final themeName = prefs.getString('reader_theme') ?? 'light';
    final savedFontFamily = prefs.getString('reader_font_family') ?? 'System Default';

    if (mounted) {
      setState(() {
        _readerTheme = ReaderTheme.values.firstWhere(
              (e) => e.name == themeName,
          orElse: () => ReaderTheme.light,
        );
        _fontFamily = savedFontFamily;

        _parser = EpubParser(
          fontFamily: _fontFamily == 'System Default' ? null : _fontFamily,
        );
      });
    }
  }

  Future<void> _saveTheme(ReaderTheme theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reader_theme', theme.name);
  }

  Future<void> _saveFontFamily(String family) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reader_font_family', family);
  }

  // NEW: Load persistent bookmarks
  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    if (_title != null) {
      final savedBookmarks = prefs.getStringList('epub_bookmarks_${_title!.hashCode}');
      if (savedBookmarks != null) {
        if (mounted) {
          setState(() {
            _bookmarks = savedBookmarks.map((e) => int.parse(e)).toSet();
          });
        }
      }
    }
  }

  // NEW: Save persistent bookmarks
  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    if (_title != null) {
      final bookmarksList = _bookmarks.map((e) => e.toString()).toList();
      await prefs.setStringList('epub_bookmarks_${_title!.hashCode}', bookmarksList);
    }
  }

  Future<void> _prepareBook() async {
    try {
      final book = await EpubReader.readBook(widget.epubBytes);

      book.Content?.Images?.forEach((k, v) {
        if (v.Content != null) _images[k] = Uint8List.fromList(v.Content!);
      });

      for (var entry in _images.entries) {
        final decodedImage = await decodeImageFromList(entry.value);
        _imageSizes[entry.key] = Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      }

      _extractSections(book.Chapters ?? []);

      _title = book.Title ?? "EPUB Reader";

      // Load bookmarks for this specific book
      await _loadBookmarks();

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

    List<EpubPage> newPages = [];

    for (int i = 0; i < _sections.length; i++) {
      final chunk = _parser.paginate(
        sections: [_sections[i]],
        maxHeight: constraints.maxHeight - 57.0,
        maxWidth: constraints.maxWidth,
        horizontalPadding: 24.0,
        imageSizes: _imageSizes,
      );

      newPages.addAll(chunk.map((p) => EpubPage(html: p.html, sectionIndex: i)));
      await Future.delayed(Duration.zero);
    }

    _pages = newPages;

    final prefs = await SharedPreferences.getInstance();
    final savedPage = prefs.getInt('epub_pos_${_title!.hashCode}') ?? 0;

    _currentPage = (savedPage < _pages.length) ? savedPage : 0;
    _pageController = PageController(initialPage: _currentPage);

    if (mounted) setState(() => _isInitialized = true);
  }

  void _changeFontFamily(String newFamily) {
    if (!_isInitialized || _fontFamily == newFamily) return;

    int currentSection = _pages.isNotEmpty ? _pages[_currentPage].sectionIndex : 0;

    setState(() {
      _fontFamily = newFamily;

      _parser = EpubParser(
        fontFamily: newFamily == 'System Default' ? null : newFamily,
      );

      _isInitialized = false;
    });

    _saveFontFamily(newFamily);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      int fallbackIndex = _pages.indexWhere((p) => p.sectionIndex == currentSection);
      if (fallbackIndex == -1) fallbackIndex = 0;
      await prefs.setInt('epub_pos_${_title!.hashCode}', fallbackIndex);
    });
  }

  void _jumpToPreviousChapter() {
    if (_pages.isEmpty) return;
    int currentSection = _pages[_currentPage].sectionIndex;
    int firstPageOfCurrentChapter = _pages.indexWhere((p) => p.sectionIndex == currentSection);

    if (_currentPage > firstPageOfCurrentChapter) {
      _pageController?.jumpToPage(firstPageOfCurrentChapter);
    } else if (currentSection > 0) {
      int prevChapterPageIndex = _pages.indexWhere((p) => p.sectionIndex == currentSection - 1);
      if (prevChapterPageIndex != -1) {
        _pageController?.jumpToPage(prevChapterPageIndex);
      }
    }
  }

  void _jumpToNextChapter() {
    if (_pages.isEmpty) return;
    int currentSection = _pages[_currentPage].sectionIndex;
    int nextChapterPageIndex = _pages.indexWhere((p) => p.sectionIndex > currentSection);

    if (nextChapterPageIndex != -1) {
      _pageController?.jumpToPage(nextChapterPageIndex);
    } else {
      _pageController?.jumpToPage(_pages.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) return Scaffold(body: Center(child: Text("Error: $_error")));

    final themeColors = ReaderThemeColors.get(_readerTheme);

    return Scaffold(
      backgroundColor: themeColors.background,
      appBar: AppBar(
        title: Text(_isInitialized && _pages.isNotEmpty ? _sections[_pages[_currentPage].sectionIndex].title : "Loading..."),
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
          Builder(
            builder: (context) => IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context)
            ),
          )
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
                _buildTapZones(),
                _buildBookmarkIcon(),     // NEW: Render the bookmark ribbon
                _buildBookmarkTapZone(),  // NEW: Tap zone specifically for the bookmark
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

  Widget _buildTapZones() {
    return Positioned.fill(
      child: Row(
        children: [
          Expanded(
            flex: 1,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_currentPage > 0) {
                  _pageController?.previousPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutQuad,
                  );
                }
              },
            ),
          ),
          const Expanded(flex: 2, child: IgnorePointer()),
          Expanded(
            flex: 1,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_currentPage < _pages.length - 1) {
                  _pageController?.nextPage(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutQuad,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // NEW: Tap zone exclusively for toggling the bookmark in the top right corner
  Widget _buildBookmarkTapZone() {
    return Positioned(
      top: 0,
      right: 0,
      width: 100,
      height: 100,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          setState(() {
            if (_bookmarks.contains(_currentPage)) {
              _bookmarks.remove(_currentPage);
            } else {
              _bookmarks.add(_currentPage);
            }
          });
          _saveBookmarks();
        },
      ),
    );
  }

  // NEW: Visual indicator if the current page is bookmarked
  Widget _buildBookmarkIcon() {
    if (!_bookmarks.contains(_currentPage)) return const SizedBox.shrink();

    final themeColors = ReaderThemeColors.get(_readerTheme);
    return Positioned(
      top: 0,
      right: 24, // Aligned with your 24px HTML padding
      child: Icon(
        Icons.bookmark,
        size: 48,
        color: Color(0xFF1A237E).withOpacity(0.5),
      ),
    );
  }

  Widget _buildPageContent(int index) {
    if (_pages.isEmpty) return const SizedBox.shrink();

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
                  if (imageData != null) {
                    return SizedBox(
                      width: double.infinity,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 400.0,
                          ),
                          child: Image.memory(imageData),
                        ),
                      ),
                    );
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ],
          style: {
            "body": Style(
              fontFamily: _fontFamily == 'System Default' ? null : _fontFamily,
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
            icon: Icon(Icons.skip_previous, size: 24, color: themeColors.text),
            onPressed: _currentPage > 0 ? _jumpToPreviousChapter : null,
          ),
          Text(
            _pages.isNotEmpty ? "Page ${_currentPage + 1} of ${_pages.length}" : "Loading...",
            style: TextStyle(color: themeColors.text),
          ),
          IconButton(
            icon: Icon(Icons.skip_next, size: 24, color: themeColors.text),
            onPressed: _currentPage < _pages.length - 1 ? _jumpToNextChapter : null,
          ),
        ],
      ),
    );
  }

  // UPDATED: Now uses a DefaultTabController for Chapters and Bookmarks
  Widget _buildDrawer(ReaderThemeColors themeColors) {
    // Sort and filter out any bookmarks that are mathematically out of bounds
    // (which can happen if font size changes result in fewer pages)
    final validBookmarks = _bookmarks.where((b) => b < _pages.length).toList()..sort();

    return Drawer(
      backgroundColor: themeColors.background,
      child: SafeArea(
        child: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                labelColor: themeColors.text,
                unselectedLabelColor: themeColors.text.withOpacity(0.5),
                indicatorColor: themeColors.text,
                tabs: const [
                  Tab(text: "Chapters"),
                  Tab(text: "Bookmarks"),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Chapters
                    ListView.builder(
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
                    // Tab 2: Bookmarks
                    validBookmarks.isEmpty
                        ? Center(
                      child: Text(
                        "No bookmarks yet.\nTap the top right corner of a page to add one.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: themeColors.text.withOpacity(0.7)),
                      ),
                    )
                        : ListView.builder(
                      itemCount: validBookmarks.length,
                      itemBuilder: (context, index) {
                        int pageIndex = validBookmarks[index];
                        int sectionIndex = _pages[pageIndex].sectionIndex;
                        String chapterTitle = _sections[sectionIndex].title;

                        return ListTile(
                          leading: Icon(Icons.bookmark, color: Color(0xFF1A237E)),
                          title: Text(
                              "Page ${pageIndex + 1}",
                              style: TextStyle(color: themeColors.text)
                          ),
                          subtitle: Text(
                              chapterTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: themeColors.text.withOpacity(0.6))
                          ),
                          onTap: () {
                            _pageController?.jumpToPage(pageIndex);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
              title: Text("Font", style: TextStyle(color: themeColors.text)),
              trailing: DropdownButton<String>(
                value: _fontFamily,
                dropdownColor: themeColors.background,
                style: TextStyle(color: themeColors.text, fontSize: 16),
                underline: Container(height: 1, color: themeColors.text.withOpacity(0.5)),
                iconEnabledColor: themeColors.text,
                items: ['Arial', 'Times New Roman', 'Comic Sans MS', 'Bebas Neue', 'Special Elite']
                    .map((String font) => DropdownMenuItem<String>(
                  value: font,
                  child: Text(
                      font,
                      style: TextStyle(fontFamily: font == 'Arial' ? null : font)
                  ),
                ))
                    .toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    _changeFontFamily(newValue);
                    Navigator.pop(context);
                  }
                },
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