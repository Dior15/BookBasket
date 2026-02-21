class EpubSection {
  final String title;
  final String html;
  final int depth;
  EpubSection({required this.title, required this.html, required this.depth});
}

class EpubPage {
  final String html;
  final int sectionIndex;
  EpubPage({required this.html, required this.sectionIndex});
}

class SplitResult {
  final String fits;
  final String remains;
  SplitResult({required this.fits, required this.remains});
}