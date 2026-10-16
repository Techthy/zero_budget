import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../data/database.dart';
import '../data/database_provider.dart';
import '../welcome/welcome_providers.dart';

part 'spending_providers.g.dart';

/// The buffer to keep in the bank account on top of the plan.
@riverpod
Stream<int> bufferCents(Ref ref) =>
    ref.watch(appDatabaseProvider).watchBufferCents();

@riverpod
Stream<List<Expense>> currentExpenses(Ref ref) async* {
  final db = ref.watch(appDatabaseProvider);
  final monthId = await ref.watch(currentMonthIdProvider.future);
  yield* db.watchExpenses(monthId);
}
