// widgets/expandable_card.dart - Tối ưu animation và clean code
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
              if (widget.onMarkComplete != null) ...[
                const SizedBox(height: 10),
              //  _buildCompleteButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarkdownContent() {
    return MarkdownBody(
      data: widget.content,
      selectable: true,
      styleSheet: _buildMarkdownStyle(),
      extensionSet: _buildExtensionSet(),
      builders: _buildCustomBuilders(),
    );
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
    return md.ExtensionSet(
      md.ExtensionSet.gitHubFlavored.blockSyntaxes,
      [
        ...md.ExtensionSet.gitHubFlavored.inlineSyntaxes,
        ColoredTextSyntax(),
        UnderlineTextSyntax(),
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

  // Widget _buildCompleteButton() {
  //   return SizedBox(
  //     width: double.infinity,
  //     // child: ElevatedButton.icon(
  //     //   onPressed: widget.onMarkComplete,
  //     //   icon: Icon(
  //     //     widget.isCompleted ? Icons.check_circle : Icons.circle_outlined,
  //     //     size: 20,
  //     //   ),
  //     //   // label: Text(
  //     //   //   widget.isCompleted ? 'Đã hoàn thành' : 'Đánh dấu hoàn thành',
  //     //   //   style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
  //     //   // ),
  //     //   style: ElevatedButton.styleFrom(
  //     //     padding: const EdgeInsets.symmetric(vertical: 10),
  //     //     backgroundColor: widget.isCompleted ? Colors.green[100] : Colors.blue[100],
  //     //     foregroundColor: widget.isCompleted ? Colors.green[800] : Colors.blue[800],
  //     //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  //     //   ),
  //     // ),
  //   );
  // }
}

// ==================== Custom Markdown Syntax ====================

class ColoredTextSyntax extends md.InlineSyntax {
  ColoredTextSyntax() : super(r'\{([^}]+)\}\[([^\]]+)\]');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final element = md.Element.text('colored', match.group(1)!)
      ..attributes['color'] = match.group(2)!;
    parser.addNode(element);
    return true;
  }
}

class UnderlineTextSyntax extends md.InlineSyntax {
  UnderlineTextSyntax() : super(r'__([^_]+)__');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('underline', match.group(1)!));
    return true;
  }
}

class CenterTextSyntax extends md.InlineSyntax {
  CenterTextSyntax() : super(r'\^\^([^\^]+)\^\^');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    parser.addNode(md.Element.text('center', match.group(1)!));
    return true;
  }
}

// ==================== Custom Builders ====================

class ColoredTextBuilder extends MarkdownElementBuilder {
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
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final colorName = element.attributes['color']?.toLowerCase() ?? 'black';
    final color = _colorMap[colorName] ?? Colors.black87;

    return Text(
      element.textContent,
      style: preferredStyle?.copyWith(
        color: color,
        fontWeight: FontWeight.bold,
        fontSize: 15.5,
      ),
    );
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