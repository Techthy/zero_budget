import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../money.dart';

class AmountField extends StatelessWidget {
  const AmountField({
    super.key,
    required this.controller,
    this.autofocus = false,
    this.style,
    this.onSubmitted,
    this.onChanged,
    this.labelText = 'Amount',
    this.helperText,
    this.isRequired = true,
    this.textInputAction,
  });

  final TextEditingController controller;
  final bool autofocus;
  final TextStyle? style;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final String labelText;
  final String? helperText;

  /// Whether the field can't be left empty.
  final bool isRequired;

  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      style: style,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: '0.00',
        helperText: helperText,
        helperMaxLines: 2,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: textInputAction,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      validator: (value) {
        final text = value?.trim() ?? '';
        if (!isRequired && text.isEmpty) return null;
        return parseAmountToCents(text) == null
            ? 'Enter an amount like 1250.00'
            : null;
      },
      onChanged: onChanged,
      onFieldSubmitted: onSubmitted,
    );
  }
}
