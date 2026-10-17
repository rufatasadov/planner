import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../theme.dart';

class NoteMarkdown extends StatelessWidget {
  const NoteMarkdown(this.data, {super.key});

  final String data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.textTheme.bodyMedium?.color;
    final base = MarkdownStyleSheet.fromTheme(theme);
    return MarkdownBody(
      data: data,
      selectable: true,
      shrinkWrap: true,
      styleSheet: base.copyWith(
        p: TextStyle(fontSize: 15, height: 1.35, color: color),
        h1: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color),
        h2: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color),
        h3: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
        listBullet: TextStyle(fontSize: 15, height: 1.35, color: color),
        code: TextStyle(
          fontSize: 13,
          color: color,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
        ),
        blockquote: TextStyle(
          fontSize: 15,
          height: 1.35,
          color: mutedColor(context),
        ),
      ),
      onTapLink: (text, href, title) {},
      sizedImageBuilder: (config) => const SizedBox.shrink(),
    );
  }
}
