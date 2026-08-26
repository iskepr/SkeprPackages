import "package:flutter/material.dart";
import "package:skepr_ui/skepr_ui.dart";

class CustomListTile extends StatelessWidget {
  const CustomListTile({
    super.key,
    this.onTap,
    this.onLongPress,
    this.leading,
    required this.title,
    this.subtitle,
    this.trailing,
    this.color,
    this.size = 1,
  }) : assert(
         title is String || title is Widget,
         "title must be a String or a Widget",
       ),
       assert(
         leading == null || leading is String || leading is Widget,
         "leading must be a String or a Widget",
       ),
       assert(
         subtitle == null || subtitle is String || subtitle is Widget,
         "subtitle must be a String or a Widget",
       ),
       assert(
         trailing == null || trailing is String || trailing is Widget,
         "trailing must be a String or a Widget",
       );

  final Function()? onTap;
  final Function()? onLongPress;
  final dynamic leading;
  final dynamic title;
  final dynamic subtitle;
  final dynamic trailing;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    Widget? buildWidget(dynamic value, TextStyle defaultStyle) {
      if (value == null) return null;
      if (value is String) {
        return Text(value, style: defaultStyle);
      }
      return value as Widget;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(kSmallBorderRadius),
        child: Container(
          width: double.infinity,
          padding: EdgeInsetsDirectional.only(
            top: kSmallPadding * 1.5,
            bottom: kSmallPadding * 1.5,
            start: leading != null ? 0 : kDefaultPadding,
            end: kDefaultPadding,
          ),
          child: Stack(
            alignment: SkeprMaterial.isRTL
                ? Alignment.centerRight
                : Alignment.centerLeft,
            children: [
              if (leading != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: kLargePadding * 0.9,
                  ),
                  child: buildWidget(
                    leading,
                    TextStyle(fontSize: kMediumFont * size, color: color),
                  ),
                ),

              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: leading != null ? kDefaultPadding * 2.5 : 0,
                ),
                child: Column(
                  spacing: kSmallPadding * size,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: trailing != null ? kDefaultPadding * 2 : 0,
                      ),
                      child: buildWidget(
                        title,
                        context.textTheme.titleMedium!.copyWith(
                          fontSize: size != 1 ? (kMediumFont * size) : null,
                          fontWeight: FontWeight.w400,
                          color: color,
                        ),
                      )!,
                    ),
                    if (subtitle != null && subtitle != "")
                      RepaintBoundary(
                        child: DefaultTextStyle(
                          style: TextStyle(
                            color: color ?? context.text.withValues(alpha: 0.7),
                            fontSize: kSmallFont * size,
                            fontFamily: kMainFont,
                            fontWeight: FontWeight.normal,
                          ),
                          child: IconTheme(
                            data: IconThemeData(
                              color:
                                  color ?? context.text.withValues(alpha: 0.7),
                            ),
                            child: buildWidget(
                              subtitle,
                              TextStyle(
                                color:
                                    color ??
                                    context.text.withValues(alpha: 0.7),
                                fontSize: kSmallFont * size,
                              ),
                            )!,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              if (trailing != null)
                Positioned.fill(
                  child: Align(
                    alignment: SkeprMaterial.isRTL
                        ? const Alignment(-1.0, -0.3)
                        : const Alignment(1.0, -0.3),
                    child: buildWidget(
                      trailing,
                      TextStyle(
                        color: color ?? context.text.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w100,
                        fontSize: (kSoSmallFont * 0.9) * size,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
