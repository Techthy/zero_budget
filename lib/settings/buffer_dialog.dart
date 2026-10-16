import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database_provider.dart';
import '../money.dart';
import '../widgets/amount_field.dart';

/// Asks for a new buffer to keep in the bank account, starting from
/// [bufferCents], and saves it.
Future<void> editBuffer(
  BuildContext context,
  WidgetRef ref,
  int bufferCents,
) async {
  final edited = await showDialog<int>(
    context: context,
    builder: (_) => _BufferDialog(bufferCents: bufferCents),
  );
  if (edited != null) {
    await ref.read(appDatabaseProvider).setBufferCents(edited);
  }
}

/// Changes the buffer kept in the bank account, returning it in cents.
class _BufferDialog extends StatefulWidget {
  const _BufferDialog({required this.bufferCents});

  final int bufferCents;

  @override
  State<_BufferDialog> createState() => _BufferDialogState();
}

class _BufferDialogState extends State<_BufferDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: formatAmount(widget.bufferCents),
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(parseAmountToCents(_amount.text)!);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Buffer'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Money you always keep in your bank account on top of your '
              'plan, as a safety net.',
            ),
            AmountField(
              controller: _amount,
              autofocus: true,
              onSubmitted: (_) => _submit(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
