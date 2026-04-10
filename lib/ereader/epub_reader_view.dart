import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:epub_parser/epub_parser.dart' hide Image;
import 'package:shared_preferences/shared_preferences.dart';

import 'epub_models.dart';
import 'epub_parser.dart';
import '../animations/page_flip.dart';

import '../auth_service.dart';
import '../firebase_database/firebase_db.dart';

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
  static const Color _navSelectionAccent = Color(0xFF3949AB);
  static const Duration _layoutRefreshDebounce = Duration(milliseconds: 400);

  // Layout constants — kept in one place so paginator and renderer stay in sync
  static const double _pagePaddingH = 24.0; // horizontal padding inside page
  static const double _pagePaddingTop = 10.0;
  static const double _pagePaddingBottom = 10.0;
  static const double _navBarHeight = 48.0; // bottom navigation row
  static const double _navBarBottomMargin =
      15.0; // lift nav bar off bottom edge
  bool _isInitialized = false;
  bool _isInitializing =
      false; // Guard against concurrent _initializeReader calls
  String? _title, _error;
  final List<EpubSection> _sections = [];
  List<EpubPage> _pages = [];
  final Map<String, Uint8List> _images = {};

  final Map<String, Size> _imageSizes = {};

  PageController? _pageController;
  int _currentPage = 0;

  Set<int> _bookmarks = {};

  EpubParser _parser = EpubParser();
  ReaderTheme _readerTheme = ReaderTheme.light;

  String _fontFamily = 'System Default';
  double _fontSize = 18.0;

  Timer? _fontSizeDebounceTimer;
  Timer? _layoutRefreshDebounceTimer;
  BoxConstraints? _lastLayoutConstraints;

  @override
  void initState() {
    super.initState();
    // Chain: load settings first, then prepare book. This prevents the race
    // condition where both completing and calling setState would each schedule
    // a concurrent _initializeReader call before either finishes.
    _loadSettingsThenPrepare();
  }

  Future<void> _loadSettingsThenPrepare() async {
    await _loadSettings();
    await _prepareBook();
  }

  @override
  void dispose() {
    _fontSizeDebounceTimer?.cancel();
    _layoutRefreshDebounceTimer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final email = await AuthService.getEmail() ?? AuthService.userEmail;
      final prefs = await FirebaseDB.getReference().getUserPreferences(email);

      if (mounted) {
        setState(() {
          _readerTheme = ReaderTheme.values.firstWhere(
            (e) => e.name == prefs["readerTheme"],
            orElse: () => ReaderTheme.light,
          );
          _fontFamily =
              prefs["readerFontFamily"] as String? ?? 'System Default';
          // We use 'as num?' to safely handle if Firestore returns an int (like 18), a double (18.0), or null
          _fontSize = (prefs["readerFontSize"] as num?)?.toDouble() ?? 18.0;

          _parser = EpubParser(
            fontFamily: _fontFamily == 'System Default' ? null : _fontFamily,
            fontSize: _fontSize,
          );
        });
      }
    } catch (e) {
      debugPrint("Error loading cloud preferences: $e");
    }
  }

  Future<void> _saveTheme(ReaderTheme theme) async {
    try {
      final email = await AuthService.getEmail() ?? AuthService.userEmail;
      await FirebaseDB.getReference()
          .updateUserPreference(email, {"readerTheme": theme.name});
    } catch (e) {
      debugPrint("Error saving theme to cloud: $e");
    }
  }

  Future<void> _saveFontFamily(String family) async {
    try {
      final email = await AuthService.getEmail() ?? AuthService.userEmail;
      await FirebaseDB.getReference()
          .updateUserPreference(email, {"readerFontFamily": family});
    } catch (e) {
      debugPrint("Error saving font family to cloud: $e");
    }
  }

  Future<void> _saveFontSize(double size) async {
    try {
      final email = await AuthService.getEmail() ?? AuthService.userEmail;
      await FirebaseDB.getReference()
          .updateUserPreference(email, {"readerFontSize": size});
    } catch (e) {
      debugPrint("Error saving font size to cloud: $e");
    }
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    if (_title != null) {
      final savedBookmarks =
          prefs.getStringList('epub_bookmarks_${_title!.hashCode}');
      if (savedBookmarks != null) {
        if (mounted) {
          setState(() {
            _bookmarks = savedBookmarks.map((e) => int.parse(e)).toSet();
          });
        }
      }
    }
  }

  Future<void> _saveBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    if (_title != null) {
      final bookmarksList = _bookmarks.map((e) => e.toString()).toList();
      await prefs.setStringList(
          'epub_bookmarks_${_title!.hashCode}', bookmarksList);
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
        _imageSizes[entry.key] =
            Size(decodedImage.width.toDouble(), decodedImage.height.toDouble());
      }

      _extractSections(book.Chapters ?? []);

      _title = book.Title ?? "EPUB Reader";

      await _loadBookmarks();

      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _extractSections(List<EpubChapter> chapters, [int depth = 0]) {
    for (final ch in chapters) {
      if (ch.HtmlContent?.trim().isNotEmpty ?? false) {
        _sections.add(EpubSection(
            title: ch.Title ?? "Section", html: ch.HtmlContent!, depth: depth));
      }
      if (ch.SubChapters != null) _extractSections(ch.SubChapters!, depth + 1);
    }
  }

  Future<void> _initializeReader(BoxConstraints constraints) async {
    // _isInitializing is set synchronously (before any await) so concurrent
    // calls triggered by setState-rebuilds bail out immediately.
    if (_isInitialized || _isInitializing || _title == null) return;
    _isInitializing = true;

    List<EpubPage> newPages = [];

    // Overflow guard: compensates for flutter_html rendering slightly taller
    // than TextPainter measures. Uses shortestSide (the screen's smaller
    // dimension) so the guard is ORIENTATION-INDEPENDENT — same value in
    // portrait and landscape. Calibrated from two real devices:
    //   - 2000x1200 tablet  (short side 1200px, DPR≈2.0): 600/2.0 = 300
    //   - 2400x1080 phone   (short side 1080px, DPR≈3.0): 360/3.0 = 120
    // Clamped to 40px minimum so it can never go zero or negative.
    final double dpr = MediaQuery.of(context).devicePixelRatio;
    final double kOverflowGuard =
        (MediaQuery.of(context).size.shortestSide / dpr * 0.7)
            .clamp(40.0, double.infinity);
    final double contentHeight = constraints.maxHeight -
        _pagePaddingTop -
        _pagePaddingBottom -
        _navBarHeight -
        _navBarBottomMargin -
        kOverflowGuard;
    final double contentWidth = constraints.maxWidth - (_pagePaddingH * 2);

    for (int i = 0; i < _sections.length; i++) {
      final chunk = _parser.paginate(
        sections: [_sections[i]],
        contentHeight: contentHeight,
        contentWidth: contentWidth,
        imageSizes: _imageSizes,
      );

      newPages
          .addAll(chunk.map((p) => EpubPage(html: p.html, sectionIndex: i)));
      await Future.delayed(Duration.zero);
    }

    _pages = newPages;

    final email = await AuthService.getEmail() ?? AuthService.userEmail;
    final savedPage =
        await FirebaseDB.getReference().getReadingProgress(email, _title!);

    _currentPage = (savedPage < _pages.length) ? savedPage : 0;
    _pageController = PageController(initialPage: _currentPage);

    _isInitializing = false;
    if (mounted) setState(() => _isInitialized = true);
  }

  void _changeFontFamily(String newFamily) {
    if (!_isInitialized || _fontFamily == newFamily) return;

    int currentSection =
        _pages.isNotEmpty ? _pages[_currentPage].sectionIndex : 0;

    setState(() {
      _fontFamily = newFamily;

      _parser = EpubParser(
        fontFamily: newFamily == 'System Default' ? null : newFamily,
        fontSize: _fontSize,
      );

      _isInitialized = false;
    });

    _saveFontFamily(newFamily);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      int fallbackIndex =
          _pages.indexWhere((p) => p.sectionIndex == currentSection);
      if (fallbackIndex == -1) fallbackIndex = 0;

      final email = await AuthService.getEmail() ?? AuthService.userEmail;
      await FirebaseDB.getReference()
          .saveReadingProgress(email, _title!, fallbackIndex);
    });
  }

  void _changeFontSize(double newSize) {
    if (_fontSize == newSize) return;

    setState(() {
      _fontSize = newSize;
    });

    _fontSizeDebounceTimer?.cancel();

    _fontSizeDebounceTimer = Timer(const Duration(seconds: 1), () {
      _applyResizedFont(newSize);
    });
  }

  void _applyResizedFont(double newSize) {
    if (!mounted || !_isInitialized) return;

    int currentSection =
        _pages.isNotEmpty ? _pages[_currentPage].sectionIndex : 0;

    setState(() {
      _parser = EpubParser(
        fontFamily: _fontFamily == 'System Default' ? null : _fontFamily,
        fontSize: newSize,
      );

      _isInitialized = false;
    });

    _saveFontSize(newSize);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      int fallbackIndex =
          _pages.indexWhere((p) => p.sectionIndex == currentSection);
      if (fallbackIndex == -1) fallbackIndex = 0;
      await prefs.setInt('epub_pos_${_title!.hashCode}', fallbackIndex);
    });
  }

  bool _hasLayoutChanged(BoxConstraints constraints) {
    if (_lastLayoutConstraints == null) return false;

    return _lastLayoutConstraints!.maxWidth != constraints.maxWidth ||
        _lastLayoutConstraints!.maxHeight != constraints.maxHeight;
  }

  void _scheduleLayoutRefresh() {
    if (!_isInitialized || _isInitializing || _title == null) return;

    _layoutRefreshDebounceTimer?.cancel();
    _layoutRefreshDebounceTimer = Timer(_layoutRefreshDebounce, () {
      if (!mounted || !_isInitialized || _isInitializing || _title == null) {
        return;
      }
      _refreshForLayoutChange();
    });
  }

  void _refreshForLayoutChange() {
    final currentSection =
        _pages.isNotEmpty ? _pages[_currentPage].sectionIndex : 0;

    setState(() {
      _isInitialized = false;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      int fallbackIndex =
          _pages.indexWhere((p) => p.sectionIndex == currentSection);
      if (fallbackIndex == -1) fallbackIndex = 0;

      final email = await AuthService.getEmail() ?? AuthService.userEmail;
      await FirebaseDB.getReference()
          .saveReadingProgress(email, _title!, fallbackIndex);
    });
  }

  void _jumpToPreviousChapter() {
    if (_pages.isEmpty) return;
    int currentSection = _pages[_currentPage].sectionIndex;
    int firstPageOfCurrentChapter =
        _pages.indexWhere((p) => p.sectionIndex == currentSection);

    if (_currentPage > firstPageOfCurrentChapter) {
      _pageController?.jumpToPage(firstPageOfCurrentChapter);
    } else if (currentSection > 0) {
      int prevChapterPageIndex =
          _pages.indexWhere((p) => p.sectionIndex == currentSection - 1);
      if (prevChapterPageIndex != -1) {
        _pageController?.jumpToPage(prevChapterPageIndex);
      }
    }
  }

  void _jumpToNextChapter() {
    if (_pages.isEmpty) return;
    int currentSection = _pages[_currentPage].sectionIndex;
    int nextChapterPageIndex =
        _pages.indexWhere((p) => p.sectionIndex > currentSection);

    if (nextChapterPageIndex != -1) {
      _pageController?.jumpToPage(nextChapterPageIndex);
    } else {
      _pageController?.jumpToPage(_pages.length - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null)
      return Scaffold(body: Center(child: Text("Error: $_error")));

    final themeColors = ReaderThemeColors.get(_readerTheme);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: themeColors.background,
      appBar: AppBar(
        title: Text(_isInitialized && _pages.isNotEmpty
            ? _sections[_pages[_currentPage].sectionIndex].title
            : "Loading..."),
        backgroundColor: themeColors.background,
        foregroundColor: themeColors.text,
        surfaceTintColor: Colors.transparent,
        shadowColor: colorScheme.shadow.withOpacity(0.12),
        iconTheme: IconThemeData(color: themeColors.text),
        actionsIconTheme: IconThemeData(color: themeColors.text),
        titleTextStyle: TextStyle(
          fontFamily: 'Times New Roman',
          color: themeColors.text,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
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
                onPressed: () => Navigator.pop(context)),
          )
        ],
      ),
      drawer: _isInitialized ? _buildDrawer(themeColors) : null,
      endDrawer: _isInitialized ? _buildEndDrawer(themeColors) : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_isInitialized && _hasLayoutChanged(constraints)) {
            _lastLayoutConstraints = constraints;
            _scheduleLayoutRefresh();
          } else {
            _lastLayoutConstraints ??= constraints;
          }

          if (!_isInitialized && _title != null && constraints.maxWidth > 0) {
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _initializeReader(constraints));
            return const Center(child: CircularProgressIndicator());
          }
          if (!_isInitialized)
            return const Center(child: CircularProgressIndicator());

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
              _buildBookmarkIcon(),
              _buildBookmarkTapZone(),
              _buildNavigationArrows(),
            ],
          );
        },
      ),
    );
  }

  // --- NEW: Save progress to Firebase ---
  Future<void> _saveProgress(int index) async {
    if (_title == null) return;

    final email = await AuthService.getEmail() ?? AuthService.userEmail;
    await FirebaseDB.getReference().saveReadingProgress(email, _title!, index);
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

  Widget _buildBookmarkTapZone() {
    return Positioned(
      top: 0,
      left: 0,
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

  Widget _buildBookmarkIcon() {
    if (!_bookmarks.contains(_currentPage)) return const SizedBox.shrink();

    final themeColors = ReaderThemeColors.get(_readerTheme);
    return Positioned(
      top: 0,
      left: 24,
      child: Icon(
        Icons.bookmark,
        size: 48,
        color: themeColors.text.withOpacity(0.4),
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
      padding: EdgeInsets.fromLTRB(
        _pagePaddingH,
        _pagePaddingTop,
        _pagePaddingH,
        _pagePaddingBottom +
            _navBarHeight +
            _navBarBottomMargin, // reserve space for the bottom nav overlay
      ),
      child: ClipRect(
        child: Html(
          data: _pages[index].html,
          extensions: [
            TagExtension(
              tagsToExtend: {"img"},
              builder: (ctx) {
                String? src = ctx.attributes['src'];
                if (src != null) {
                  final imageData =
                      _images[src] ?? _images[src.split('/').last];
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
            "p": Style(
                margin: Margins.only(top: 0, bottom: _parser.paragraphSpacing)),
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
      bottom: _navBarBottomMargin,
      left: 0,
      right: 0,
      height: _navBarHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          IconButton(
            icon: Icon(Icons.skip_previous, size: 24, color: themeColors.text),
            onPressed: _currentPage > 0 ? _jumpToPreviousChapter : null,
          ),
          Text(
            _pages.isNotEmpty
                ? "Page ${_currentPage + 1} of ${_pages.length}"
                : "Loading...",
            style: TextStyle(color: themeColors.text),
          ),
          IconButton(
            icon: Icon(Icons.skip_next, size: 24, color: themeColors.text),
            onPressed:
                _currentPage < _pages.length - 1 ? _jumpToNextChapter : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(ReaderThemeColors themeColors) {
    final validBookmarks = _bookmarks.where((b) => b < _pages.length).toList()
      ..sort();
    final currentSection = (_isInitialized && _pages.isNotEmpty)
        ? _pages[_currentPage].sectionIndex
        : -1;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      backgroundColor: themeColors.background,
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            _buildChapterDrawerHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: themeColors.text.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  labelColor: _navSelectionAccent,
                  unselectedLabelColor: themeColors.text.withOpacity(0.65),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _navSelectionAccent.withOpacity(0.16),
                    border: Border.all(
                      color: _navSelectionAccent.withOpacity(0.28),
                      width: 1,
                    ),
                  ),
                  tabs: const [
                    Tab(text: 'Chapters'),
                    Tab(text: 'Bookmarks'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                    itemCount: _sections.length,
                    itemBuilder: (context, index) {
                      final section = _sections[index];
                      final isSelected = index == currentSection;
                      return _buildChapterTile(
                        title: section.title,
                        depth: section.depth,
                        selected: isSelected,
                        themeColors: themeColors,
                        onTap: () {
                          final pIndex =
                              _pages.indexWhere((p) => p.sectionIndex == index);
                          if (pIndex != -1) _pageController?.jumpToPage(pIndex);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                  validBookmarks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              'No bookmarks yet.\nTap the top left corner of a page to add one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: themeColors.text.withOpacity(0.65)),
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                          itemCount: validBookmarks.length,
                          itemBuilder: (context, index) {
                            final pageIndex = validBookmarks[index];
                            final sectionIndex = _pages[pageIndex].sectionIndex;
                            final chapterTitle = _sections[sectionIndex].title;

                            return _buildBookmarkTile(
                              pageLabel: 'Page ${pageIndex + 1}',
                              chapterTitle: chapterTitle,
                              themeColors: themeColors,
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
    );
  }

  Widget _buildChapterDrawerHeader() {
    final topInset = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF0D1B2A),
            Color(0xFF1A237E),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, topInset + 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _title ?? 'Current Book',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.82),
                fontSize: 20,
                height: 1.3,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${_sections.length} chapters',
              style: TextStyle(
                color: Colors.white.withOpacity(0.62),
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChapterTile({
    required String title,
    required int depth,
    required bool selected,
    required ReaderThemeColors themeColors,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: selected
            ? _navSelectionAccent.withOpacity(0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: EdgeInsets.fromLTRB(12 + (depth * 12.0), 12, 12, 12),
            decoration: selected
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _navSelectionAccent.withOpacity(0.3),
                      width: 1,
                    ),
                  )
                : null,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? _navSelectionAccent
                          : themeColors.text.withOpacity(0.85),
                    ),
                  ),
                ),
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Icon(
                      Icons.circle,
                      size: 7,
                      color: _navSelectionAccent,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBookmarkTile({
    required String pageLabel,
    required String chapterTitle,
    required ReaderThemeColors themeColors,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.bookmark,
                    color: themeColors.text.withOpacity(0.9), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pageLabel,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: themeColors.text.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chapterTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: themeColors.text.withOpacity(0.62),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEndDrawer(ReaderThemeColors themeColors) {
    final topInset = MediaQuery.of(context).padding.top;

    return Drawer(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          bottomLeft: Radius.circular(20),
        ),
      ),
      backgroundColor: themeColors.background,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(20, topInset + 18, 20, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D1B2A),
                  Color(0xFF1A237E),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Reader Settings",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Personalize your reading experience",
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Colors.white.withOpacity(0.68),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: themeColors.text.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: themeColors.text.withOpacity(0.2)),
                    ),
                    child: ListTile(
                      title: Text(
                        "Font",
                        style: TextStyle(color: themeColors.text),
                      ),
                      trailing: DropdownButton<String>(
                        value: _fontFamily,
                        dropdownColor: themeColors.background,
                        style: TextStyle(color: themeColors.text, fontSize: 16),
                        underline: Container(
                          height: 1,
                          color: themeColors.text.withOpacity(0.5),
                        ),
                        iconEnabledColor: themeColors.text,
                        items: [
                          'System Default',
                          'Times New Roman',
                          'Comic Sans MS',
                          'Bebas Neue',
                          'Special Elite',
                        ]
                            .map(
                              (String font) => DropdownMenuItem<String>(
                                value: font,
                                child: Text(
                                  font,
                                  style: TextStyle(
                                    fontFamily:
                                        font == 'System Default' ? null : font,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            _changeFontFamily(newValue);
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: themeColors.text.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: themeColors.text.withOpacity(0.2)),
                    ),
                    child: ListTile(
                      title: Text(
                        "Text Size",
                        style: TextStyle(color: themeColors.text),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, color: themeColors.text),
                            onPressed: () {
                              if (_fontSize > 10.0) {
                                _changeFontSize(_fontSize - 2.0);
                              }
                            },
                          ),
                          Text(
                            "${_fontSize.toInt()}",
                            style: TextStyle(
                              color: themeColors.text,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add, color: themeColors.text),
                            onPressed: () {
                              if (_fontSize < 40.0) {
                                _changeFontSize(_fontSize + 2.0);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                    decoration: BoxDecoration(
                      color: themeColors.text.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: themeColors.text.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Theme",
                          style: TextStyle(
                            color: themeColors.text,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _themeButton(
                              ReaderTheme.light,
                              Colors.white,
                              Colors.black,
                              themeColors.text,
                            ),
                            _themeButton(
                              ReaderTheme.dark,
                              Colors.black,
                              Colors.white,
                              themeColors.text,
                            ),
                            _themeButton(
                              ReaderTheme.sepia,
                              const Color(0xFFF4ECD8),
                              const Color(0xFF5B4636),
                              themeColors.text,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _themeButton(
      ReaderTheme theme, Color bg, Color text, Color selectedColor) {
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
            color: isSelected ? selectedColor : selectedColor.withOpacity(0.45),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                      color: selectedColor.withOpacity(0.3),
                      blurRadius: 4,
                      spreadRadius: 2)
                ]
              : null,
        ),
        child: Center(
          child: Text(
            "A",
            style: TextStyle(
                color: text, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ),
      ),
    );
  }
}
