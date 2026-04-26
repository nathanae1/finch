import 'package:flutter/material.dart';

import '../theme/finch_theme.dart';

class FinchInput extends StatelessWidget {
  const FinchInput({
    super.key,
    this.controller,
    this.placeholder,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
    this.autofocus = false,
    this.textInputAction,
    this.style,
    this.padding,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool autofocus;
  final TextInputAction? textInputAction;
  final TextStyle? style;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    final textStyle = style ?? finch.typography.body;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: textInputAction,
      cursorColor: finch.colors.sage,
      style: textStyle,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: finch.colors.paper,
        hintText: placeholder,
        hintStyle: textStyle.copyWith(color: finch.colors.stone),
        contentPadding: padding ??
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: finch.colors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: finch.colors.sage, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: finch.colors.hairline),
        ),
      ),
    );
  }
}

class FinchTextarea extends StatelessWidget {
  const FinchTextarea({
    super.key,
    this.controller,
    this.placeholder,
    this.onChanged,
    this.minLines = 4,
    this.maxLines = 8,
  });

  final TextEditingController? controller;
  final String? placeholder;
  final ValueChanged<String>? onChanged;
  final int minLines;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      minLines: minLines,
      maxLines: maxLines,
      cursorColor: finch.colors.sage,
      style: finch.typography.body,
      decoration: InputDecoration(
        isDense: true,
        filled: true,
        fillColor: finch.colors.paper,
        hintText: placeholder,
        hintStyle: finch.typography.body.copyWith(color: finch.colors.stone),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: finch.colors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: finch.colors.sage, width: 2),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: finch.colors.hairline),
        ),
      ),
    );
  }
}

class FinchFieldLabel extends StatelessWidget {
  const FinchFieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final finch = FinchTheme.of(context);
    return Text(text, style: finch.typography.label);
  }
}
