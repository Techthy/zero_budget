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
  });

  final TextEditingController controller;
  final bool autofocus;
  final TextStyle? style;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autofocus: autofocus,
      style: style,
      decoration: const InputDecoration(labelText: 'Amount', hintText: '0.00'),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      validator: (value) => parseAmountToCents(value ?? '') == null
          ? 'Enter an amount like 1250.00'
          : null,
      onFieldSubmitted: onSubmitted,
    );
  }
}
