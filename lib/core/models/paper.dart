enum PaperLanguage {
  bangla('bn-BD', 'বাংলা'),
  english('en-US', 'English');

  const PaperLanguage(this.ttsLocale, this.label);

  final String ttsLocale;
  final String label;
}

/// CSS selectors that locate the article in a paper's "text view".
/// Leave a field null to fall back to the generic heuristic in
/// assets/js/extract_article.js.
class PaperSelectors {
  const PaperSelectors({
    this.articleUrlPattern,
    this.container,
    this.title,
    this.byline,
  });

  /// Regex the page URL must match before extraction is attempted.
  final String? articleUrlPattern;
  final String? container;
  final String? title;
  final String? byline;

  Map<String, String?> toJson() => {
        'articleUrlPattern': articleUrlPattern,
        'container': container,
        'title': title,
        'byline': byline,
      };
}

/// An ePaper the user can open: one of the built-ins, or one added by link.
class Paper {
  const Paper({
    required this.id,
    required this.name,
    required this.url,
    required this.language,
    this.selectors = const PaperSelectors(),
    this.builtIn = false,
    this.colorValue,
  });

  final String id;
  final String name;
  final String url;
  final PaperLanguage language;
  final PaperSelectors selectors;

  /// Built-in papers can't be edited or deleted.
  final bool builtIn;

  /// Card colour; null lets the home screen pick one from its palette.
  final int? colorValue;

  Paper copyWith({String? name, String? url, PaperLanguage? language}) => Paper(
        id: id,
        name: name ?? this.name,
        url: url ?? this.url,
        language: language ?? this.language,
        selectors: selectors,
        builtIn: builtIn,
        colorValue: colorValue,
      );

  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'url': url,
        'language': language.name,
      };

  factory Paper.fromMap(Map<String, Object?> map) => Paper(
        id: map['id'] as String,
        name: map['name'] as String,
        url: map['url'] as String,
        language: PaperLanguage.values.byName(map['language'] as String),
      );
}

/// Both built-in papers run on the same ePaper platform. Its text view puts
/// the article in #body and, when the story jumps to another page, the rest
/// of it in #divlinkedstorybody.
const _epaperPlatformSelectors = PaperSelectors(
  container: '#textView #body, #textView #divlinkedstorybody',
  title: '#divheading .head_line',
  byline: '#textView #byline',
);

const prothomAlo = Paper(
  id: 'prothomAlo',
  name: 'Prothom Alo',
  url: 'https://epaper.prothomalo.com/',
  language: PaperLanguage.bangla,
  selectors: _epaperPlatformSelectors,
  builtIn: true,
  colorValue: 0xFF13233A,
);

/// Redirects to profile.thedailystar.net for login first; see
/// android/app/src/main/res/xml/network_security_config.xml.
const dailyStar = Paper(
  id: 'dailyStar',
  name: 'The Daily Star',
  url: 'https://epaper.thedailystar.net/',
  language: PaperLanguage.english,
  selectors: _epaperPlatformSelectors,
  builtIn: true,
  colorValue: 0xFF0F766E,
);

const builtInPapers = [prothomAlo, dailyStar];
