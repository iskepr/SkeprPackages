class AppValidators {
  static String? required(String? value) {
    if (value == null || value.trim().isEmpty) return "يجب ملء هذا الحقل";
    return null;
  }

  static String? fullName(String? value) {
    if (required(value) != null) return required(value);
    final String val = value!.trim();

    if (val.contains("دكتور")) return "اكتب اسمك بس من غير ألقاب يا دكتور";
    if (!RegExp(r"^[ \u0621-\u064A]+$").hasMatch(val)) {
      return "الاسم لازم يبقى حروف عربي بس (ممنوع رموز أو أرقام)";
    }

    final List<String> words = val.split(RegExp(r"\s+"));
    if (words.length < 3) return "الاسم لازم يبقى ثلاثي على الاقل";
    if (words.length > 4) return "مش لازم كل ده رباعي كفاية اوي";
    for (String word in words) {
      if (word.length < 2) return "اكتب اسم صحيح";
    }

    return null;
  }

  static String? email(String? value) {
    if (required(value) != null) return required(value);

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$" // إنجليزي
      r"|^[\u0600-\u06FFa-zA-Z0-9._%+\-]+@[\u0600-\u06FFa-zA-Z0-9.\-]+\.[\u0600-\u06FFa-zA-Z]{2,}$", // عربي + Unicode
      unicode: true,
    );

    if (!emailRegex.hasMatch(value!.trim())) {
      return "البريد الالكتروني غير صحيح";
    }
    return null;
  }

  static String? password(String? value, {bool isLogin = false}) {
    if (required(value) != null) return required(value);
    final val = value!;

    if (!isLogin) {
      if (!RegExp(r"[\u0600-\u06FF]").hasMatch(val)) {
        return "لازم تحتوي على حرف عربي واحد على الأقل";
      }
      if (!RegExp(r"[0-9\u0660-\u0669]").hasMatch(val)) {
        return "اكتب رقم واحد على الأقل";
      }
    }
    if (val.length < 8) {
      return "لازم تكون 8 حروف على الأقل";
    }

    return null;
  }
}
