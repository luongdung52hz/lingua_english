import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;

class ExpandableCard extends StatefulWidget {
  final String title;
  final String content;
  final List<String>? examples;
  final bool isCompleted;
  final VoidCallback? onMarkComplete;
  final int index;
  final Widget? expandedChild;
  final VoidCallback? onHeaderTap;

  const ExpandableCard({
    super.key,
    required this.title,
    required this.content,
    this.examples,
    this.isCompleted = false,
    this.onMarkComplete,
    this.index = 0,
    this.expandedChild,
    this.onHeaderTap,
  });

  @override
  State<ExpandableCard> createState() => _ExpandableCardState();
}

class _ExpandableCardState extends State<ExpandableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.fastOutSlowIn,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _controller.forward() : _controller.reverse();
    widget.onHeaderTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      color: Colors.white,
      elevation: _isExpanded ? 4 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          _buildExpandableBody(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: _toggleExpand,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Row(
          children: [
            _buildNumberCircle(),
            const SizedBox(width: 8),
            Expanded(child: _buildTitle()),
            const SizedBox(width: 4),
            _buildExpandIcon(),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberCircle() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: widget.isCompleted ? Colors.green[100] : Colors.grey[300],
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${widget.index + 1}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: widget.isCompleted ? Colors.green[800] : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final isEmpty = widget.title.isEmpty;
    return Text(
      isEmpty ? 'Tiêu đề chưa có nội dung' : widget.title,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15.5,
        color: isEmpty ? Colors.grey[600] : Colors.black87,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildExpandIcon() {
    return AnimatedRotation(
      turns: _isExpanded ? 0.5 : 0.0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.fastOutSlowIn,
      child: const Icon(Icons.expand_more, size: 24),
    );
  }

  Widget _buildExpandableBody() {
    return ClipRect(
      child: SizeTransition(
        sizeFactor: _animation,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(color: Colors.grey[300], height: 1),
              const SizedBox(height: 8),
              _buildMarkdownContent(),
              if (widget.examples?.isNotEmpty ?? false) ...[
                const SizedBox(height: 10),
                _buildExamplesSection(),
              ],
              if (widget.expandedChild != null) ...[
                const SizedBox(height: 10),
                widget.expandedChild!,
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkdownContent() {
    final hasComplexSyntax = _hasComplexCustomSyntax(widget.content);

    if (hasComplexSyntax) {
      // Dùng custom parser cho nested/complex formatting
      return _CustomMarkdownWidget(
        content: widget.content,
        baseStyle: const TextStyle(height: 1.6, fontSize: 15.5, letterSpacing: 0.2),
      );
    } else {
      // Dùng MarkdownBody cho performance tốt hơn với standard markdown
      return MarkdownBody(
        data: widget.content,
        selectable: true,
        styleSheet: _buildMarkdownStyle(),
        extensionSet: _buildExtensionSet(),
        builders: _buildCustomBuilders(),
      );
    }
  }

  // Phát hiện xem có cần custom parser không - MỞ RỘNG ĐỂ DETECT BAO QUANH
  bool _hasComplexCustomSyntax(String content) {
    // Các pattern cũ (nested bên trong)
    final complexPatterns = [
      r'\^\^.*[\*_~{].*\^\^',  // Center với nested formatting: ^^**bold**^^
      r'~~.*[\*_{].*~~',        // Underline với nested: ~~**bold**~~
      r'<color:[^>]+>.*[\*_~].*</color>',  // Color với nested bên trong
      r'\{[^}]*[\*_].*\}\[',   // Color bracket với nested bên trong
    ];

    // Thêm pattern mới: Custom syntax bị bao quanh bởi * / ** / _ (italic/bold/list)
    final surroundingPatterns = [
      r'\* *<color:',  // *<color (như bullet hoặc italic mở)
      r'</color> *\*',  // </color>* (italic đóng)
      r'\*\* *\{',      // **{ (bold quanh bracket)
      r'\} *\*\*',      // }** (bold đóng)
      r'_ *<color:',    // _<color (underline italic?)
      r'</color> *_',   // </color>_
      r'\* *\{',        // *{ (italic quanh bracket)
      r'\} *\*',        // }*
    ];

    final allPatterns = [...complexPatterns, ...surroundingPatterns];
    return allPatterns.any((pattern) => RegExp(pattern, dotAll: true).hasMatch(content));
  }

  MarkdownStyleSheet _buildMarkdownStyle() {
    return MarkdownStyleSheet(
      p: const TextStyle(height: 1.6, fontSize: 15.5, letterSpacing: 0.2),
      strong: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5, color: Colors.black87),
      em: const TextStyle(fontStyle: FontStyle.italic, fontSize: 15.5, color: Colors.black87),
      h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.6),
      h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
      h3: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[800], height: 1.4),
      h4: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.blue[700], height: 1.3),
      listBullet: const TextStyle(fontSize: 0, height: 0),
      listIndent: 16,
      code: TextStyle(backgroundColor: Colors.grey[100], fontFamily: 'monospace', fontSize: 14),
      codeblockDecoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(6)),
      blockquote: TextStyle(fontStyle: FontStyle.italic, fontSize: 16, color: Colors.grey[700], height: 1.4),
      blockquoteDecoration: BoxDecoration(color: Colors.grey[50]),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      tableHead: TextStyle(fontWeight: FontWeight.bold, backgroundColor: Colors.blue[50], fontSize: 14.5),
      tableBody: const TextStyle(fontSize: 14, height: 1.4),
      tableBorder: TableBorder.all(color: Colors.grey[300]!, width: 1),
      tableCellsPadding: const EdgeInsets.all(6),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[300]!, width: 2)),
      ),
    );
  }

  md.ExtensionSet _buildExtensionSet() {
    final gfmInlineSyntaxes = md.ExtensionSet.gitHubFlavored.inlineSyntaxes.toList();
    gfmInlineSyntaxes.insert(0, UnderlineTextSyntax());

    return md.ExtensionSet(
      md.ExtensionSet.gitHubFlavored.blockSyntaxes,
      [
        ...gfmInlineSyntaxes,
        ColoredTextXmlSyntax(),
        ColoredTextBracketSyntax(),
        CenterTextSyntax(),
      ],
    );
  }

  Map<String, MarkdownElementBuilder> _buildCustomBuilders() {
    return {
      'colored': ColoredTextBuilder(),
      'underline': UnderlineTextBuilder(),
      'center': CenterTextBuilder(),
    };
  }

  Widget _buildExamplesSection() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: 6),
              Text(
                'Ví dụ:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15.5,
                  color: Colors.blue[900],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.examples!.map((ex) => _buildExampleItem(ex)),
        ],
      ),
    );
  }

  Widget _buildExampleItem(String example) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.blue[600],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              example,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomMarkdownWidget extends StatelessWidget {
  final String content;
  final TextStyle baseStyle;

  const _CustomMarkdownWidget({
    required this.content,
    required this.baseStyle,
  });

  static final Map<String, Color> _colorMap = {
    'yellow': Colors.amber.shade700,
    'vàng': Colors.amber.shade700,
    'blue': Colors.blue.shade700,
    'xanh': Colors.blue.shade700,
    'red': Colors.red.shade700,
    'đỏ': Colors.red.shade700,
    'green': Colors.green.shade700,
    'xanh lá': Colors.green.shade700,
    'orange': Colors.orange.shade700,
    'cam': Colors.orange.shade700,
    'purple': Colors.purple.shade700,
    'tím': Colors.purple.shade700,
  };

  @override
  Widget build(BuildContext context) {
    return SelectableText.rich(
      TextSpan(children: _parseContent(content, baseStyle)),
      style: baseStyle,
    );
  }

  // Helper để kiểm tra nếu spans có chứa bold (đệ quy cho nested)
  bool _hasBoldInSpans(List<InlineSpan> spans) {
    for (final span in spans) {
      if (span is TextSpan) {
        if (span.style?.fontWeight == FontWeight.bold ||
            (span.children != null && _hasBoldInSpans(span.children!))) {
          return true;
        }
      }
    }
    return false;
  }

  List<InlineSpan> _parseContent(String text, TextStyle baseStyle) {
    final spans = <InlineSpan>[];
    int lastIndex = 0;

    // Pattern với thứ tự ưu tiên: center > underline > color > bold/italic
    final pattern = RegExp(
      r'\^\^(.+?)\^\^|'  // 1. Center
      r'~~(.+?)~~|'      // 2. Underline
      r'<color:([^>]+)>(.+?)</color>|'  // 3. Color XML
      r'\{([^}]+)\}\[([^\]]+)\]|'  // 4. Color bracket
      r'\*\*(.+?)\*\*|'  // 5. Bold
      r'_([^_]+)_|'      // 6. Italic (underscore)
      r'\*([^\*]+)\*',   // 7. Italic (asterisk)
      dotAll: true,
    );

    for (final match in pattern.allMatches(text)) {
      // Text trước match
      if (match.start > lastIndex) {
        spans.add(TextSpan(text: text.substring(lastIndex, match.start)));
      }

      // Xử lý từng loại match
      if (match.group(1) != null) {
        // ^^center^^ - Đệ quy parse nội dung bên trong
        final innerSpans = _parseContent(match.group(1)!, baseStyle);
        spans.add(WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Container(
            alignment: Alignment.center,
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text.rich(
              TextSpan(children: innerSpans),
              textAlign: TextAlign.center,
              style: baseStyle.copyWith(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ));
      } else if (match.group(2) != null) {
        // ~~underline~~ - Đệ quy cho nested
        final innerSpans = _parseContent(match.group(2)!, baseStyle);
        spans.add(TextSpan(
          children: innerSpans,
          style: TextStyle(
            decoration: TextDecoration.underline,
            decorationColor: Colors.black,
            decorationThickness: 1,
          ),
        ));
      } else if (match.group(3) != null && match.group(4) != null) {
        // <color:red>text</color> - Đệ quy, chỉ bold nếu inner có bold
        final colorName = match.group(3)!.toLowerCase();
        final color = _colorMap[colorName] ?? Colors.black87;
        final innerSpans = _parseContent(match.group(4)!, baseStyle);
        final isBold = _hasBoldInSpans(innerSpans);
        spans.add(TextSpan(
          children: innerSpans,
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ));
      } else if (match.group(5) != null && match.group(6) != null) {
        // {text}[color] - Đệ quy, chỉ bold nếu inner có bold
        final colorName = match.group(6)!.toLowerCase();
        final color = _colorMap[colorName] ?? Colors.black87;
        final innerSpans = _parseContent(match.group(5)!, baseStyle);
        final isBold = _hasBoldInSpans(innerSpans);
        spans.add(TextSpan(
          children: innerSpans,
          style: TextStyle(
            color: color,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ));
      } else if (match.group(7) != null) {
        // **bold** - Đệ quy
        final innerSpans = _parseContent(match.group(7)!, baseStyle);
        spans.add(TextSpan(
          children: innerSpans,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ));
      } else if (match.group(8) != null) {
        // _italic_ - Đệ quy
        final innerSpans = _parseContent(match.group(8)!, baseStyle);
        spans.add(TextSpan(
          children: innerSpans,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      } else if (match.group(9) != null) {
        // *italic* - Đệ quy
        final innerSpans = _parseContent(match.group(9)!, baseStyle);
        spans.add(TextSpan(
          children: innerSpans,
          style: const TextStyle(fontStyle: FontStyle.italic),
        ));
      }

      lastIndex = match.end;
    }

    // Text còn lại
    if (lastIndex < text.length) {
      spans.add(TextSpan(text: text.substring(lastIndex)));
    }

    return spans.isEmpty ? [const TextSpan(text: '')] : spans;
  }
}

class _ColorUtils {
  static final Map<String, Color> colorMap = {
    'yellow': Colors.amber.shade700,
    'vàng': Colors.amber.shade700,
    'blue': Colors.blue.shade700,
    'xanh': Colors.blue.shade700,
    'red': Colors.red.shade700,
    'đỏ': Colors.red.shade700,
    'green': Colors.green.shade700,
    'xanh lá': Colors.green.shade700,
    'orange': Colors.orange.shade700,
    'cam': Colors.orange.shade700,
    'purple': Colors.purple.shade700,
    'tím': Colors.purple.shade700,
  };

  static Color getColor(String name) {
    return colorMap[name.toLowerCase()] ?? Colors.black87;
  }
}

class UnderlineTextSyntax extends md.InlineSyntax {
  UnderlineTextSyntax() : super(r'~~(?!~)([^~\n]+?)~~');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('underline', match.group(1)!));
    return true;
  }
}

class CenterTextSyntax extends md.InlineSyntax {
  CenterTextSyntax() : super(r'\^\^(.+?)\^\^');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('center', match.group(1)!));
    return true;
  }
}

class ColoredTextXmlSyntax extends md.InlineSyntax {
  ColoredTextXmlSyntax() : super(r'<color:([^>]+)>(.+?)</color>');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final element = md.Element.text('colored', match.group(2)!)
      ..attributes['color'] = match.group(1)!;
    parser.addNode(element);
    return true;
  }
}

class ColoredTextBracketSyntax extends md.InlineSyntax {
  ColoredTextBracketSyntax() : super(r'\{([^}]+)\}\[([^\]]+)\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final element = md.Element.text('colored', match.group(1)!)
      ..attributes['color'] = match.group(2)!;
    parser.addNode(element);
    return true;
  }
}

class UnderlineTextBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Text(
      element.textContent,
      style: preferredStyle?.copyWith(
        decoration: TextDecoration.underline,
        decorationColor: Colors.blue[700],
        decorationThickness: 2,
        fontSize: 15.5,
      ),
    );
  }
}

class CenterTextBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Text(
          element.textContent,
          textAlign: TextAlign.center,
          style: preferredStyle?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class ColoredTextBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final colorName = element.attributes['color'] ?? 'black';
    final color = _ColorUtils.getColor(colorName);
    final text = element.textContent;

    // Kiểm tra nếu text có pattern bold
    final hasBoldPattern = RegExp(r'\*\*.*?\*\*').hasMatch(text);

    return Text(
      text,
      style: preferredStyle?.copyWith(
        color: color,
        fontWeight: hasBoldPattern ? FontWeight.bold : FontWeight.normal,  // Chỉ bold nếu có **
        fontSize: 15.5,
      ),
    );
  }
}