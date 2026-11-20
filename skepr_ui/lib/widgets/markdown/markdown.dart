import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_markdown_plus/flutter_markdown_plus.dart";
import "package:flutter_math_fork/flutter_math.dart";
import "package:markdown/markdown.dart" as md;
import "package:skepr_ui/skepr_ui.dart";
import "package:skepr_ui/widgets/loading.dart";
import "package:skepr_ui/widgets/markdown/chunker.dart";

class SkeprMarkdown extends StatefulWidget {
  const SkeprMarkdown(
    this.content, {
    super.key,
    this.maxWidth = 880,
    this.selectable = true,
    this.mathBgBox = true,
    this.onTapLink,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.centerContent = false,
    this.fontSize,
    this.color,
  });

  final String content;
  final double maxWidth;
  final bool selectable, mathBgBox;
  final void Function(String text, String? href, String title)? onTapLink;
  final EdgeInsetsGeometry padding;
  final bool centerContent;
  final double? fontSize;
  final Color? color;

  static TextDirection getAutoDirection(String text) {
    for (int i = 0; i < text.length; i++) {
      final code = text.codeUnitAt(i);
      if (code <= 0x0040 ||
          (code >= 0x005B && code <= 0x0060) ||
          (code >= 0x007B && code <= 0x007F)) {
        continue;
      }
      final isArabic =
          (code >= 0x0600 && code <= 0x06FF) ||
          (code >= 0x0750 && code <= 0x077F) ||
          (code >= 0x08A0 && code <= 0x08FF) ||
          (code >= 0xFB50 && code <= 0xFDFF) ||
          (code >= 0xFE70 && code <= 0xFEFF);
      return isArabic ? TextDirection.rtl : TextDirection.ltr;
    }
    return TextDirection.ltr;
  }

  static String normalizeNewlines(String text) {
    if (!text.contains(r'\n')) return text;

    final real = '\n'.allMatches(text).length;
    final literal = r'\n'.allMatches(text).length;
    if (literal < real * 1.5) return text;

    final protected = <String>[];
    var work = text;

    work = work.replaceAllMapped(RegExp(r'```[\s\S]*?```'), (m) {
      protected.add(m.group(0)!);
      return '\x00CB${protected.length - 1}\x00';
    });

    work = work.replaceAllMapped(RegExp(r'`[^`\n]+`'), (m) {
      protected.add(m.group(0)!);
      return '\x00IC${protected.length - 1}\x00';
    });

    work = work
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t');

    work = work.replaceAllMapped(
      RegExp(r'\x00(CB|IC)(\d+)\x00'),
      (m) => protected[int.parse(m.group(2)!)],
    );

    return work;
  }

  static final List<md.BlockSyntax> _blockSyntaxes = <md.BlockSyntax>[
    _FastBlockMathSyntax(),
  ];

  static final List<md.InlineSyntax> _inlineSyntaxes = <md.InlineSyntax>[
    _FastInlineMathSyntax(),
    _FastInlineMathParenSyntax(),
  ];

  @override
  State<SkeprMarkdown> createState() => _SkeprMarkdownState();
}

class _SkeprMarkdownState extends State<SkeprMarkdown> {
  static const _lazyThreshold = 4000;
  static const _mdCacheLimit = 400;

  late String _content;
  late TextDirection _direction;
  ThemeData? _theme;
  MarkdownStyleSheet? _sheet;
  Map<String, MarkdownElementBuilder>? _builders;

  List<MarkdownSection> _sections = [];
  final Set<int> _expandedH1 = {0};
  final Set<String> _expandedH2 = {};
  bool _isProcessing = false;

  final Map<String, Widget> _mdCache = {};

  @override
  void initState() {
    super.initState();
    _content = SkeprMarkdown.normalizeNewlines(widget.content);
    _direction = SkeprMarkdown.getAutoDirection(_content);
    _processContent();
  }

  @override
  void didUpdateWidget(SkeprMarkdown old) {
    super.didUpdateWidget(old);
    if (old.content != widget.content) {
      _content = SkeprMarkdown.normalizeNewlines(widget.content);
      _direction = SkeprMarkdown.getAutoDirection(_content);
      _mdCache.clear();
      _processContent();
    }
    if (old.fontSize != widget.fontSize ||
        old.color != widget.color ||
        old.mathBgBox != widget.mathBgBox ||
        old.onTapLink != widget.onTapLink) {
      _sheet = null;
      _builders = null;
      _mdCache.clear();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    if (!identical(theme, _theme)) {
      _theme = theme;
      _sheet = null;
      _builders = null;
      _mdCache.clear();
    }
  }

  Future<void> _processContent() async {
    final text = _content;

    if (text.length < _lazyThreshold) {
      final res = processChunks(ChunkRequest(text: text));
      setState(() {
        _sections = res.sections;
        _isProcessing = false;
        _initExpandedStates();
      });
      return;
    }

    setState(() => _isProcessing = true);

    final response = await compute(processChunks, ChunkRequest(text: text));

    if (!mounted) return;

    setState(() {
      _sections = response.sections;
      _isProcessing = false;
      _initExpandedStates();
    });
  }

  void _initExpandedStates() {
    _expandedH1
      ..clear()
      ..add(0);
    _expandedH2.clear();

    for (int i = 0; i < _sections.length; i++) {
      final subCount = _sections[i].subSections.length;
      if (subCount == 0) continue;

      if (subCount <= 2) {
        for (int j = 0; j < subCount; j++) {
          _expandedH2.add("$i-$j");
        }
      } else {
        _expandedH2.add("$i-0");
      }
    }
  }

  void _buildStyle() {
    final theme = _theme!;
    final isDark = theme.brightness == Brightness.dark;

    final border = isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);
    final text =
        widget.color ??
        (isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F2328));
    final codeBg = isDark ? const Color(0xFF161B22) : const Color(0xFFF6F8FA);
    final link = isDark ? const Color(0xFF2F81F7) : const Color(0xFF0969DA);
    final base = widget.fontSize ?? 15.0;

    final mathBg = isDark
        ? Colors.white.withOpacity(0.07)
        : Colors.black.withOpacity(0.04);
    final mathBorder = isDark
        ? Colors.white.withOpacity(0.14)
        : Colors.black.withOpacity(0.08);

    TextStyle ts(double size, [FontWeight? w, FontStyle? s]) => TextStyle(
      fontSize: size,
      fontWeight: w,
      fontStyle: s,
      fontFamily: kMainFont,
      color: text,
    );

    _builders = {
      "display-latex": _BlockMathBuilder(
        bg: mathBg,
        bgBox: widget.mathBgBox,
        border: mathBorder,
        color: text,
        fontSize: base + 2,
      ),
      "inline-latex": _InlineMathBuilder(
        bg: mathBg,
        bgBox: widget.mathBgBox,
        border: mathBorder,
        color: text,
        fontSize: base,
      ),
    };

    _sheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      listIndent: 14,
      orderedListAlign: WrapAlignment.start,
      tableColumnWidth: const FlexColumnWidth(),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      tableBorder: TableBorder.all(color: border, width: 1),
      tableHead: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: base - 1,
        color: text,
      ),
      tableBody: TextStyle(fontSize: base - 1, color: text),
      p: ts(base).copyWith(height: 1.6),
      strong: ts(base, FontWeight.w600),
      em: ts(base, null, FontStyle.italic),
      del: ts(base).copyWith(decoration: TextDecoration.lineThrough),
      blockquote: ts(base).copyWith(color: text.withOpacity(0.8)),
      blockquoteDecoration: BoxDecoration(
        border: Border(left: BorderSide(color: border, width: 4)),
      ),
      h1: ts(base + 9, FontWeight.w700),
      h2: ts(base + 5, FontWeight.w600),
      h3: ts(base + 2, FontWeight.w600),
      h4: ts(base, FontWeight.w600),
      h5: ts(base - 1, FontWeight.w600),
      h6: ts(base - 2, FontWeight.w600),
      code: TextStyle(
        fontSize: base,
        fontFamily: "serif",
        fontStyle: FontStyle.italic,
        color: text,
        backgroundColor: widget.mathBgBox ? mathBg : Colors.transparent,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      a: TextStyle(color: link, fontSize: base),
      listBullet: TextStyle(color: text, fontSize: base),
    );
  }

  Widget _md(String data) {
    final cached = _mdCache[data];
    if (cached != null) return cached;

    if (_mdCache.length >= _mdCacheLimit) {
      _mdCache.remove(_mdCache.keys.first);
    }

    final w = MarkdownBody(
      data: data,
      selectable: false,
      onTapLink: widget.onTapLink,
      blockSyntaxes: SkeprMarkdown._blockSyntaxes,
      inlineSyntaxes: SkeprMarkdown._inlineSyntaxes,
      builders: _builders!,
      styleSheet: _sheet,
    );
    _mdCache[data] = w;
    return w;
  }

  Widget _buildSubSection(int h1Index, int h2Index, SubSection sub) {
    final key = "$h1Index-$h2Index";
    final isExpanded = _expandedH2.contains(key);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        widget.color ?? (isDark ? Colors.white60 : Colors.black54);

    return Padding(
      padding: const EdgeInsets.only(left: 12.0, right: 12.0, top: 4.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedH2.remove(key);
                } else {
                  _expandedH2.add(key);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Expanded(child: IgnorePointer(child: _md(sub.header))),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0.0,
                    duration: const Duration(milliseconds: 180),
                    child: Icon(
                      _direction == TextDirection.rtl
                          ? Icons.arrow_left_rounded
                          : Icons.arrow_right_rounded,
                      size: (widget.fontSize ?? 15.0) * 1.4,
                      color: iconColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded && sub.body.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
              child: _md(sub.body),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(int index, MarkdownSection section) {
    final isExpanded = _expandedH1.contains(index);

    if (section.header.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (section.body.isNotEmpty) _md(section.body),
            for (int j = 0; j < section.subSections.length; j++)
              _buildSubSection(index, j, section.subSections[j]),
          ],
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        widget.color ?? (isDark ? Colors.white60 : Colors.black54);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedH1.remove(index);
              } else {
                _expandedH1.add(index);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: IgnorePointer(child: _md(section.header))),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: isExpanded ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    _direction == TextDirection.rtl
                        ? Icons.arrow_left_rounded
                        : Icons.arrow_right_rounded,
                    size: (widget.fontSize ?? 15.0) * 1.6,
                    color: iconColor,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (isExpanded) ...[
          if (section.body.isNotEmpty) _md(section.body),
          for (int j = 0; j < section.subSections.length; j++)
            _buildSubSection(index, j, section.subSections[j]),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sheet == null) _buildStyle();

    Widget body;

    if (_sections.isEmpty && _isProcessing) {
      body = const Padding(
        padding: EdgeInsets.all(32.0),
        child: Center(child: Loading()),
      );
    } else if (_sections.isEmpty) {
      body = const SizedBox.shrink();
    } else {
      body = LayoutBuilder(
        builder: (context, constraints) {
          final isBounded = constraints.maxHeight.isFinite;

          if (isBounded) {
            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: widget.padding,
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      return RepaintBoundary(
                        key: ValueKey("sec_$index"),
                        child: Directionality(
                          textDirection: _direction,
                          child: _buildSection(index, _sections[index]),
                        ),
                      );
                    }, childCount: _sections.length),
                  ),
                ),
              ],
            );
          } else {
            return Padding(
              padding: widget.padding,
              child: Directionality(
                textDirection: _direction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (int i = 0; i < _sections.length; i++)
                      RepaintBoundary(
                        key: ValueKey("sec_$i"),
                        child: _buildSection(i, _sections[i]),
                      ),
                  ],
                ),
              ),
            );
          }
        },
      );
    }

    Widget result = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: body,
    );
    if (widget.centerContent) result = Center(child: result);
    if (widget.selectable) result = SelectionArea(child: result);

    return result;
  }
}

// ==========================================
// Inline Syntaxes
// ==========================================

class _FastInlineMathSyntax extends md.InlineSyntax {
  _FastInlineMathSyntax()
    : super(
        r'\$(?!\$)(.+?)(?<!\\)\$(?!\$)',
        startCharacter: 36, // $
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(1)?.trim() ?? '';
    if (content.isEmpty) return false;
    parser.addNode(md.Element.text('inline-latex', content));
    return true;
  }
}

class _FastInlineMathParenSyntax extends md.InlineSyntax {
  _FastInlineMathParenSyntax()
    : super(
        r'\\\((.+?)\\\)',
        startCharacter: 92, // \
      );

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final content = match.group(1)?.trim() ?? '';
    if (content.isEmpty) return false;
    parser.addNode(md.Element.text('inline-latex', content));
    return true;
  }
}

// ==========================================
// Block Syntax
// ==========================================

class _FastBlockMathSyntax extends md.BlockSyntax {
  @override
  RegExp get pattern => RegExp(r'^\s*(?:\$\$|\\\[)');

  @override
  md.Node? parse(md.BlockParser parser) {
    final line = parser.current.content;
    final trimmed = line.trimLeft();
    final isDollar = trimmed.startsWith(r'$$');
    final isBracket = trimmed.startsWith(r'\[');
    if (!isDollar && !isBracket) return null;

    final closer = isDollar ? r'$$' : r'\]';
    final buffer = StringBuffer();

    // لو المعادلة في سطر واحد (مثال: $$ x = 2 $$)
    if (trimmed.length > 2) {
      final endIdx = trimmed.indexOf(closer, 2);
      if (endIdx != -1) {
        final content = trimmed.substring(2, endIdx).trim();
        parser.advance();
        return md.Element.text('display-latex', content);
      }
    }

    // لو المعادلة متعددة الأسطر
    buffer.write(trimmed.substring(2));
    parser.advance();

    while (!parser.isDone) {
      final current = parser.current.content;
      final endIdx = current.indexOf(closer);
      if (endIdx != -1) {
        buffer.write('\n');
        buffer.write(current.substring(0, endIdx));
        parser.advance();
        break;
      }
      buffer.write('\n');
      buffer.write(current);
      parser.advance();
    }

    final content = buffer.toString().trim();
    return md.Element.text('display-latex', content);
  }
}

// ==========================================
// Math Builders (Arabic-aware)
// ==========================================

final RegExp _arabicChar = RegExp(
  r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
);

// تتابع حروف عربية (مع مسافات وعلامات ترقيم عربية بينها)
final RegExp _arabicRun = RegExp(
  r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]+'
  r'(?:[ \u00A0\u060C\u061B\u061F]+[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]+)*',
);

// \text{عربي} -> عربي (عشان يتعرض كنص عادي)
final RegExp _textWrapped = RegExp(
  r'\\(?:text|mbox|textbf|textit|mathrm)\{([^{}]*[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF][^{}]*)\}',
);

// أجزاء اللاتكس الحقيقية بس: \frac{a}{b} , \pi , x^2 , a_{n}
final RegExp _mathAtom = RegExp(
  r'(?:\\[a-zA-Z]+(?:\{[^{}]*\})*|[A-Za-z0-9]+[\^_](?:\{[^{}]*\}|[A-Za-z0-9]))'
  r'(?:[\^_](?:\{[^{}]*\}|[A-Za-z0-9]))*',
);

class _TexPart {
  const _TexPart(this.text, this.isMath);
  final String text;
  final bool isMath;
}

/// بيقسم النص لنص عادي + أجزاء ماث. النص العادي (عربي + + = ( ) " ...)
/// بيفضل في نفس الـ Text عشان ترتيب الـ RTL يطلع صح.
List<_TexPart> _splitTex(String input) {
  final tex = input.replaceAllMapped(_textWrapped, (m) => m.group(1)!);
  final parts = <_TexPart>[];
  var last = 0;

  for (final m in _mathAtom.allMatches(tex)) {
    if (m.start > last) {
      parts.add(_TexPart(tex.substring(last, m.start), false));
    }
    // أي عربي جوه الأقواس بيتلف بـ \text{}
    final atom = m
        .group(0)!
        .replaceAllMapped(_arabicRun, (a) => '\\text{${a.group(0)}}');
    parts.add(_TexPart(atom, true));
    last = m.end;
  }
  if (last < tex.length) parts.add(_TexPart(tex.substring(last), false));
  return parts;
}

Widget _buildMixedMath({
  required String tex,
  required bool display,
  required Color color,
  required double fontSize,
  required bool bgBox,
  required Color bg,
  required Color border,
}) {
  final textStyle = TextStyle(fontSize: fontSize, color: color);

  Widget mathWidget(String t) => Directionality(
    textDirection: TextDirection.ltr,
    child: Math.tex(
      t,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: textStyle,
      settings: TexParserSettings(strict: Strict.ignore),
      onErrorFallback: (_) =>
          Text(t, style: const TextStyle(color: Colors.red)),
    ),
  );

  Widget content;

  if (!_arabicChar.hasMatch(tex)) {
    // ماث عادي من غير عربي
    final math = mathWidget(tex);
    content = display
        ? SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: math,
          )
        : FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: math,
          );
  } else {
    final parts = _splitTex(tex);
    content = Text.rich(
      TextSpan(
        style: textStyle,
        children: [
          for (final p in parts)
            if (p.isMath)
              WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: mathWidget(p.text),
              )
            else
              TextSpan(text: p.text),
        ],
      ),
      textDirection: SkeprMarkdown.getAutoDirection(tex),
      textAlign: display ? TextAlign.center : TextAlign.start,
    );
  }

  if (bgBox) {
    content = DecoratedBox(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(display ? 8 : 6),
        border: Border.all(color: border, width: 0.8),
      ),
      child: Padding(
        padding: display
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        child: content,
      ),
    );
  }
  return content;
}

class _InlineMathBuilder extends MarkdownElementBuilder {
  _InlineMathBuilder({
    required this.bg,
    required this.bgBox,
    required this.border,
    required this.color,
    required this.fontSize,
  });

  final bool bgBox;
  final Color bg, border, color;
  final double fontSize;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final inline = _buildMixedMath(
      tex: element.textContent,
      display: false,
      color: color,
      fontSize: fontSize,
      bgBox: bgBox,
      bg: bg,
      border: border,
    );

    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: inline,
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockMathBuilder extends MarkdownElementBuilder {
  _BlockMathBuilder({
    required this.bg,
    required this.bgBox,
    required this.border,
    required this.color,
    required this.fontSize,
  });

  final bool bgBox;
  final Color bg, border, color;
  final double fontSize;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final content = _buildMixedMath(
      tex: element.textContent,
      display: true,
      color: color,
      fontSize: fontSize,
      bgBox: bgBox,
      bg: bg,
      border: border,
    );

    return RepaintBoundary(
      child: SizedBox(
        width: double.infinity,
        child: Align(alignment: Alignment.center, child: content),
      ),
    );
  }
}
