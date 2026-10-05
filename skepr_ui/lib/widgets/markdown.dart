import "dart:collection";

import "package:flutter/material.dart";
import "package:flutter_markdown_plus/flutter_markdown_plus.dart";
import "package:flutter_math_fork/flutter_math.dart";
import "package:markdown/markdown.dart" as md;
import "package:skepr_ui/skepr_ui.dart";

class SkeprMarkdown extends StatefulWidget {
  const SkeprMarkdown({
    super.key,
    required this.content,
    this.maxWidth = 880,
    this.selectable = true,
    this.onTapLink,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    this.centerContent = false,
    this.fontSize,
  });

  final String content;
  final double maxWidth;
  final bool selectable;
  final void Function(String text, String? href, String title)? onTapLink;
  final EdgeInsetsGeometry padding;
  final bool centerContent;
  final double? fontSize;

  /// فحص اتجاه النص: بيقف عند أول حرف "قوي" ومبيعدّيش على النص كله
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

  // instances مشتركة (stateless) بدل ما تتعمل في كل build
  static const List<md.BlockSyntax> _blockSyntaxes = [_FastBlockMathSyntax()];
  static final List<md.InlineSyntax> _inlineSyntaxes = [
    _FastInlineMathSyntax(),
  ];

  @override
  State<SkeprMarkdown> createState() => _SkeprMarkdownState();
}

class _SkeprMarkdownState extends State<SkeprMarkdown> {
  late TextDirection _direction;
  ThemeData? _theme;
  MarkdownStyleSheet? _sheet;
  Map<String, MarkdownElementBuilder>? _builders;

  @override
  void initState() {
    super.initState();
    _direction = SkeprMarkdown.getAutoDirection(widget.content);
  }

  @override
  void didUpdateWidget(SkeprMarkdown old) {
    super.didUpdateWidget(old);
    if (old.content != widget.content) {
      _direction = SkeprMarkdown.getAutoDirection(widget.content);
    }
    if (old.fontSize != widget.fontSize) _sheet = null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    if (!identical(theme, _theme)) {
      _theme = theme;
      _sheet = null;
    }
  }

  void _buildStyle() {
    final theme = _theme!;
    final isDark = theme.brightness == Brightness.dark;

    final border = isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);
    final text = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F2328);
    final codeBg = isDark ? const Color(0xFF161B22) : const Color(0xFFF6F8FA);
    final link = isDark ? const Color(0xFF2F81F7) : const Color(0xFF0969DA);
    final base = widget.fontSize ?? 15.0;

    final mathBg = isDark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.black.withValues(alpha: 0.04);
    final mathBorder = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.08);

    TextStyle ts(double size, [FontWeight? w]) => TextStyle(
      fontSize: size,
      fontWeight: w,
      fontFamily: kMainFont,
      color: text,
    );

    _builders = {
      "display-latex": _MathBuilder(
        display: true,
        bg: mathBg,
        border: mathBorder,
        color: text,
        fontSize: base + 2,
      ),
      "inline-latex": _MathBuilder(
        display: false,
        bg: mathBg,
        border: mathBorder,
        color: text,
        fontSize: base,
      ),
    };

    _sheet = MarkdownStyleSheet.fromTheme(theme).copyWith(
      listIndent: 18,
      orderedListAlign: WrapAlignment.start,
      p: ts(base).copyWith(height: 1.6),
      h1: ts(base + 11, FontWeight.w700),
      h2: ts(base + 5, FontWeight.w600),
      h3: ts(base + 2, FontWeight.w600),
      code: TextStyle(
        fontSize: (base - 2).clamp(10.0, 30.0),
        fontFamily: "monospace",
        backgroundColor: codeBg,
        color: text,
      ),
      codeblockDecoration: BoxDecoration(
        color: codeBg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: border),
      ),
      tableBorder: TableBorder.all(color: border, width: 1),
      tableHead: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: base,
        color: text,
      ),
      tableBody: TextStyle(fontSize: base, color: text),
      a: TextStyle(color: link, fontSize: base),
      listBullet: TextStyle(color: text, fontSize: base),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sheet == null) _buildStyle();

    // selectable: false + SelectionArea واحد = أخف بكتير من SelectableText لكل فقرة
    Widget body = MarkdownBody(
      data: widget.content,
      selectable: false,
      onTapLink: widget.onTapLink,
      blockSyntaxes: SkeprMarkdown._blockSyntaxes,
      inlineSyntaxes: SkeprMarkdown._inlineSyntaxes,
      builders: _builders!,
      styleSheet: _sheet,
    );

    if (widget.selectable) body = SelectionArea(child: body);

    final content = ConstrainedBox(
      constraints: BoxConstraints(maxWidth: widget.maxWidth),
      child: Padding(
        padding: widget.padding,
        child: Directionality(textDirection: _direction, child: body),
      ),
    );

    return widget.centerContent ? Center(child: content) : content;
  }
}

/// LRU cache لـ Math widget بس (جواه الـ parse بتاع LaTeX).
/// مفيش scroll ولا decoration هنا، فمفيش state بيتشارك.
class _MathCache {
  static const _max = 128;
  static final LinkedHashMap<String, Widget> _map = LinkedHashMap();

  static Widget get(String key, Widget Function() build) {
    final hit = _map.remove(key);
    if (hit != null) {
      _map[key] = hit;
      return hit;
    }
    final w = build();
    _map[key] = w;
    if (_map.length > _max) _map.remove(_map.keys.first);
    return w;
  }
}

class _MathBuilder extends MarkdownElementBuilder {
  _MathBuilder({
    required this.display,
    required this.bg,
    required this.border,
    required this.color,
    required this.fontSize,
  });

  final bool display;
  final Color bg;
  final Color border;
  final Color color;
  final double fontSize;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final tex = element.textContent;

    final math = Math.tex(
      tex,
      mathStyle: display ? MathStyle.display : MathStyle.text,
      textStyle: TextStyle(fontSize: fontSize, color: color),
      onErrorFallback: (_) =>
          Text(tex, style: const TextStyle(color: Colors.red)),
    );

    return _wrap(math);
  }

  Widget _wrap(Widget math) {
    if (display) {
      final scroll = Directionality(
        textDirection: TextDirection.ltr,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: math,
        ),
      );

      final box = DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: scroll,
        ),
      );

      return RepaintBoundary(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: SizedBox(
            width: double.infinity,
            child: Align(alignment: Alignment.center, child: box),
          ),
        ),
      );
    }

    // بالنسبة للـ Inline: إزالة السكرول لتفادي مشاكل الحجم 0 داخل السطر العادي
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: border, width: 0.8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          child: Directionality(textDirection: TextDirection.ltr, child: math),
        ),
      ),
    );
  }
}

class _FastBlockMathSyntax extends md.BlockSyntax {
  const _FastBlockMathSyntax();

  static final RegExp _start = RegExp(r"^\$\$");

  @override
  RegExp get pattern => _start;

  @override
  bool canParse(md.BlockParser parser) =>
      parser.current.content.startsWith(r"$$");

  @override
  md.Node? parse(md.BlockParser parser) {
    final first = parser.current.content.trim();

    if (first.length > 4 && first.endsWith(r"$$")) {
      parser.advance();
      return md.Element.text(
        "display-latex",
        first.substring(2, first.length - 2).trim(),
      );
    }

    final buf = StringBuffer();
    parser.advance();
    while (!parser.isDone) {
      final current = parser.current.content;
      if (current.contains(r"$$")) {
        buf.write(current.replaceAll(r"$$", ""));
        parser.advance();
        break;
      }
      buf
        ..write(current)
        ..write("\n");
      parser.advance();
    }

    return md.Element.text("display-latex", buf.toString().trim());
  }
}

/// $..$ — بيتجاهل "$5 و $10" (لازم مفيش مسافة بعد الفتح ولا قبل القفل)
class _FastInlineMathSyntax extends md.InlineSyntax {
  _FastInlineMathSyntax() : super(r"\$(?!\s)([^\$\n]+?)(?<!\s)\$");

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final text = match.group(1) ?? "";
    if (text.isEmpty) return false;
    parser.addNode(md.Element.text("inline-latex", text));
    return true;
  }
}
