import "package:flutter/material.dart";
import "package:flutter_markdown_plus/flutter_markdown_plus.dart";
import "package:markdown/markdown.dart" as md;
import "package:skepr_ui/skepr_ui.dart";

class SkeprMarkdown extends StatelessWidget {
  const SkeprMarkdown({
    super.key,
    required this.content,
    this.maxWidth = 880,
    this.selectable = true,
    this.onTapLink,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  });

  final String content;
  final double maxWidth;
  final bool selectable;
  final void Function(String text, String? href, String title)? onTapLink;
  final EdgeInsetsGeometry padding;

  /// دالة تفحص أول حرف وتحدد هل هو عربي (RTL) أم إنجليزي (LTR)
  static TextDirection getAutoDirection(String text) {
    // تنظيف النص من رموز الماركداون والمسافات للحصول على أول حرف حقيقي
    final cleanText = text.replaceAll(RegExp(r"^[#*\->`_~0-9.\s]+"), "");
    if (cleanText.isEmpty) return TextDirection.ltr;

    final firstChar = cleanText.codeUnitAt(0);
    final isRtl =
        (firstChar >= 0x0600 && firstChar <= 0x06FF) ||
        (firstChar >= 0x0750 && firstChar <= 0x077F) ||
        (firstChar >= 0x08A0 && firstChar <= 0x08FF) ||
        (firstChar >= 0xFB50 && firstChar <= 0xFDFF) ||
        (firstChar >= 0xFE70 && firstChar <= 0xFEFF);

    return isRtl ? TextDirection.rtl : TextDirection.ltr;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ألوان GitHub
    final ghBorder = isDark ? const Color(0xFF30363D) : const Color(0xFFD0D7DE);
    final ghText = isDark ? const Color(0xFFE6EDF3) : const Color(0xFF1F2328);
    final ghCodeBg = isDark ? const Color(0xFF161B22) : const Color(0xFFF6F8FA);
    final ghLink = isDark ? const Color(0xFF2F81F7) : const Color(0xFF0969DA);

    final autoDirectionBuilder = _AutoDirectionBuilder();

    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        padding: padding,
        child: MarkdownBody(
          data: content,
          selectable: selectable,
          onTapLink: onTapLink,
          builders: {
            "p": autoDirectionBuilder,
            "h1": autoDirectionBuilder,
            "h2": autoDirectionBuilder,
            "h3": autoDirectionBuilder,
            "h4": autoDirectionBuilder,
            "li": autoDirectionBuilder,
            "blockquote": autoDirectionBuilder,
          },
          styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
            // النصوص العادية
            p: TextStyle(
              fontSize: 15,
              height: 1.6,
              fontFamily: kMainFont,
              color: ghText,
            ),

            // H1
            h1: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              fontFamily: kMainFont,
              color: ghText,
              decoration: TextDecoration.none,
            ),
            h1Padding: const EdgeInsets.only(top: 24, bottom: 8),

            // H2
            h2: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              fontFamily: kMainFont,
              color: ghText,
              decoration: TextDecoration.none,
            ),
            h2Padding: const EdgeInsets.only(top: 20, bottom: 6),

            // H3
            h3: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              fontFamily: kMainFont,
              color: ghText,
              decoration: TextDecoration.none,
            ),
            h3Padding: const EdgeInsets.only(top: 16, bottom: 4),

            // H4
            h4: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: kMainFont,
              color: ghText,
              decoration: TextDecoration.none,
            ),

            // الخطوط الفاصلة (---)
            horizontalRuleDecoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: ghBorder, width: 1)),
            ),

            // الاقتباسات (Blockquotes)
            blockquoteDecoration: BoxDecoration(
              color: ghCodeBg.withOpacity(0.5),
              borderRadius: BorderRadius.circular(4),
              border: Border(left: BorderSide(color: ghBorder, width: 4)),
            ),
            blockquotePadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),

            // الأكواد المضمنة والكتل
            code: TextStyle(
              fontSize: 13,
              fontFamily: "monospace",
              backgroundColor: ghCodeBg,
              color: ghText,
            ),
            codeblockDecoration: BoxDecoration(
              color: ghCodeBg,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: ghBorder),
            ),

            // الجداول
            tableBorder: TableBorder.all(color: ghBorder, width: 1),
            tableHead: TextStyle(
              fontWeight: FontWeight.bold,
              fontFamily: kMainFont,
              color: ghText,
            ),
            tableBody: TextStyle(fontFamily: kMainFont, color: ghText),
            tableCellsPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),

            // القوائم والروابط
            a: TextStyle(color: ghLink, decoration: TextDecoration.none),
            listBullet: TextStyle(color: ghText, fontSize: 15),
          ),
        ),
      ),
    );
  }
}

/// Builder مخصص لتطبيق الاتجاه المناسب لكل عنصر
class _AutoDirectionBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final text = element.textContent;
    final direction = SkeprMarkdown.getAutoDirection(text);

    return Directionality(
      textDirection: direction,
      child: Container(
        width: double.infinity,
        alignment: direction == TextDirection.rtl
            ? Alignment.centerRight
            : Alignment.centerLeft,
        child: Text.rich(
          element.attributes["textSpan"] as InlineSpan? ??
              TextSpan(text: text, style: preferredStyle),
          textDirection: direction,
        ),
      ),
    );
  }
}
