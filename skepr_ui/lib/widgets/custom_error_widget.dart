import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:skepr_ui/skepr_ui.dart";

class CustomErrorWidget extends StatelessWidget {
  const CustomErrorWidget({super.key, required this.error});

  final FlutterErrorDetails error;

  @override
  Widget build(BuildContext context) {
    final errorText =
        "${error.exceptionAsString()}\n\n${error.stack?.toString() ?? ""}";

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Material(
        borderRadius: BorderRadius.circular(kMediumBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(kDefaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.circleAlert, color: context.error, size: 50),
              const SizedBox(height: kLargePadding),
              const Text(
                "معلش، حصلت مشكلة في الشاشة دي!",
                style: TextStyle(
                  fontSize: kMediumFont,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              Text(
                "تواصل مع المُطور عشان يحل المشكلة.\n(اضغط على الكود تحت عشان تنسخه)",
                style: TextStyle(
                  fontSize: kSmallFont,
                  color: context.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: kMediumPadding),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: errorText));
                  showMessage("تم نسخ الخطأ بنجاح", isError: false);
                },
                child: SizedBox(
                  height: 150,
                  child: SingleChildScrollView(
                    child: Text(
                      errorText,
                      style: const TextStyle(
                        fontSize: kSoSmallFont,
                        color: Colors.grey,
                      ),
                      textDirection: TextDirection.ltr,
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
