class SubSection {
  const SubSection({required this.header, required this.body});

  final String header; // H2
  final String body; // المحتوى التابع لـ H2
}

class MarkdownSection {
  const MarkdownSection({
    required this.header,
    required this.body,
    this.subSections = const [],
  });

  final String header; // H1
  final String body; // محتوى مباشر تحت H1 قبل أول H2
  final List<SubSection> subSections; // كل الـ H2 التابعة لـ H1
}

class ChunkRequest {
  const ChunkRequest({required this.text});
  final String text;
}

class ChunkResponse {
  const ChunkResponse({required this.sections});
  final List<MarkdownSection> sections;
}

ChunkResponse processChunks(ChunkRequest req) {
  final text = req.text;
  final len = text.length;
  final sections = <MarkdownSection>[];

  var pos = 0;
  var inFence = false;
  var inMath = false;
  var fenceMark = 0;

  String currentH1 = "";
  final currentH1Body = StringBuffer();

  String currentH2 = "";
  final currentH2Body = StringBuffer();
  final currentSubSections = <SubSection>[];

  void flushH2() {
    if (currentH2.isNotEmpty || currentH2Body.isNotEmpty) {
      currentSubSections.add(
        SubSection(header: currentH2, body: currentH2Body.toString().trim()),
      );
      currentH2 = "";
      currentH2Body.clear();
    }
  }

  void flushH1() {
    flushH2();
    if (currentH1.isNotEmpty ||
        currentH1Body.isNotEmpty ||
        currentSubSections.isNotEmpty) {
      sections.add(
        MarkdownSection(
          header: currentH1,
          body: currentH1Body.toString().trim(),
          subSections: List.unmodifiable(currentSubSections),
        ),
      );
      currentH1 = "";
      currentH1Body.clear();
      currentSubSections.clear();
    }
  }

  while (pos < len) {
    final nl = text.indexOf("\n", pos);
    final lineEnd = nl == -1 ? len : nl;
    final line = text.substring(pos, lineEnd);
    final trimmed = line.trim();
    pos = nl == -1 ? len : nl + 1;

    // حماية الأكواد والمعادلات
    if (inMath) {
      if (trimmed.contains(r"$$")) inMath = false;
      if (currentH2.isNotEmpty) {
        currentH2Body.writeln(line);
      } else {
        currentH1Body.writeln(line);
      }
      continue;
    } else if (inFence) {
      if ((fenceMark == 1 && trimmed.startsWith("```")) ||
          (fenceMark == 2 && trimmed.startsWith("~~~"))) {
        inFence = false;
      }
      if (currentH2.isNotEmpty) {
        currentH2Body.writeln(line);
      } else {
        currentH1Body.writeln(line);
      }
      continue;
    } else if (trimmed.startsWith("```")) {
      inFence = true;
      fenceMark = 1;
      if (currentH2.isNotEmpty) {
        currentH2Body.writeln(line);
      } else {
        currentH1Body.writeln(line);
      }
      continue;
    } else if (trimmed.startsWith("~~~")) {
      inFence = true;
      fenceMark = 2;
      if (currentH2.isNotEmpty) {
        currentH2Body.writeln(line);
      } else {
        currentH1Body.writeln(line);
      }
      continue;
    } else if (trimmed.startsWith(r"$$")) {
      final single = trimmed.length > 4 && trimmed.endsWith(r"$$");
      if (!single) inMath = true;
      if (currentH2.isNotEmpty) {
        currentH2Body.writeln(line);
      } else {
        currentH1Body.writeln(line);
      }
      continue;
    }

    if (_isH1(line)) {
      flushH1();
      currentH1 = trimmed;
    } else if (_isH2(line)) {
      flushH2();
      currentH2 = trimmed;
    } else {
      if (currentH2.isNotEmpty) {
        currentH2Body.writeln(line);
      } else {
        currentH1Body.writeln(line);
      }
    }
  }

  flushH1();

  if (sections.isEmpty) {
    sections.add(MarkdownSection(header: "", body: text.trim()));
  }

  return ChunkResponse(sections: sections);
}

bool _isH1(String line) {
  final t = line.trimLeft();
  return t.startsWith("# ") || t == "#";
}

bool _isH2(String line) {
  final t = line.trimLeft();
  return t.startsWith("## ") || t == "##";
}
