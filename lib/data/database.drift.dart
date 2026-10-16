// dart format width=80
// ignore_for_file: type=lint
part of 'database.dart';

class $MonthsTable extends Months with TableInfo<$MonthsTable, Month> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _monthMeta = const VerificationMeta('month');
  @override
  late final GeneratedColumn<int> month = GeneratedColumn<int>(
    'month',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _incomeCentsMeta = const VerificationMeta(
    'incomeCents',
  );
  @override
  late final GeneratedColumn<int> incomeCents = GeneratedColumn<int>(
    'income_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lockedAtMeta = const VerificationMeta(
    'lockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> lockedAt = GeneratedColumn<DateTime>(
    'locked_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carryOverCentsMeta = const VerificationMeta(
    'carryOverCents',
  );
  @override
  late final GeneratedColumn<int> carryOverCents = GeneratedColumn<int>(
    'carry_over_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _carryOverAdjustmentCentsMeta =
      const VerificationMeta('carryOverAdjustmentCents');
  @override
  late final GeneratedColumn<int> carryOverAdjustmentCents =
      GeneratedColumn<int>(
        'carry_over_adjustment_cents',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(0),
      );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    year,
    month,
    incomeCents,
    lockedAt,
    carryOverCents,
    carryOverAdjustmentCents,
    notes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'months';
  @override
  VerificationContext validateIntegrity(
    Insertable<Month> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMeta);
    }
    if (data.containsKey('month')) {
      context.handle(
        _monthMeta,
        month.isAcceptableOrUnknown(data['month']!, _monthMeta),
      );
    } else if (isInserting) {
      context.missing(_monthMeta);
    }
    if (data.containsKey('income_cents')) {
      context.handle(
        _incomeCentsMeta,
        incomeCents.isAcceptableOrUnknown(
          data['income_cents']!,
          _incomeCentsMeta,
        ),
      );
    }
    if (data.containsKey('locked_at')) {
      context.handle(
        _lockedAtMeta,
        lockedAt.isAcceptableOrUnknown(data['locked_at']!, _lockedAtMeta),
      );
    }
    if (data.containsKey('carry_over_cents')) {
      context.handle(
        _carryOverCentsMeta,
        carryOverCents.isAcceptableOrUnknown(
          data['carry_over_cents']!,
          _carryOverCentsMeta,
        ),
      );
    }
    if (data.containsKey('carry_over_adjustment_cents')) {
      context.handle(
        _carryOverAdjustmentCentsMeta,
        carryOverAdjustmentCents.isAcceptableOrUnknown(
          data['carry_over_adjustment_cents']!,
          _carryOverAdjustmentCentsMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {year, month},
  ];
  @override
  Month map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Month(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      )!,
      month: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month'],
      )!,
      incomeCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}income_cents'],
      )!,
      lockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}locked_at'],
      ),
      carryOverCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carry_over_cents'],
      )!,
      carryOverAdjustmentCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}carry_over_adjustment_cents'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
    );
  }

  @override
  $MonthsTable createAlias(String alias) {
    return $MonthsTable(attachedDatabase, alias);
  }
}

class Month extends DataClass implements Insertable<Month> {
  final int id;
  final int year;
  final int month;

  /// Total of the month's incomes, kept in sync whenever one changes.
  final int incomeCents;

  /// When the plan was locked in to track spending; null while planning.
  final DateTime? lockedAt;

  /// Balance left from the month before (negative if it was overspent), which
  /// is available to assign on top of the income.
  ///
  /// Kept in sync with the month before whenever anything changes, plus
  /// [carryOverAdjustmentCents].
  final int carryOverCents;

  /// Added to what the month before left: manual corrections, and savings
  /// released from sinking funds.
  final int carryOverAdjustmentCents;

  /// Free-form notes about the month's plan, like goals or things to take
  /// care of; null when there are none.
  final String? notes;
  const Month({
    required this.id,
    required this.year,
    required this.month,
    required this.incomeCents,
    this.lockedAt,
    required this.carryOverCents,
    required this.carryOverAdjustmentCents,
    this.notes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['year'] = Variable<int>(year);
    map['month'] = Variable<int>(month);
    map['income_cents'] = Variable<int>(incomeCents);
    if (!nullToAbsent || lockedAt != null) {
      map['locked_at'] = Variable<DateTime>(lockedAt);
    }
    map['carry_over_cents'] = Variable<int>(carryOverCents);
    map['carry_over_adjustment_cents'] = Variable<int>(
      carryOverAdjustmentCents,
    );
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    return map;
  }

  MonthsCompanion toCompanion(bool nullToAbsent) {
    return MonthsCompanion(
      id: Value(id),
      year: Value(year),
      month: Value(month),
      incomeCents: Value(incomeCents),
      lockedAt: lockedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lockedAt),
      carryOverCents: Value(carryOverCents),
      carryOverAdjustmentCents: Value(carryOverAdjustmentCents),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
    );
  }

  factory Month.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Month(
      id: serializer.fromJson<int>(json['id']),
      year: serializer.fromJson<int>(json['year']),
      month: serializer.fromJson<int>(json['month']),
      incomeCents: serializer.fromJson<int>(json['incomeCents']),
      lockedAt: serializer.fromJson<DateTime?>(json['lockedAt']),
      carryOverCents: serializer.fromJson<int>(json['carryOverCents']),
      carryOverAdjustmentCents: serializer.fromJson<int>(
        json['carryOverAdjustmentCents'],
      ),
      notes: serializer.fromJson<String?>(json['notes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'year': serializer.toJson<int>(year),
      'month': serializer.toJson<int>(month),
      'incomeCents': serializer.toJson<int>(incomeCents),
      'lockedAt': serializer.toJson<DateTime?>(lockedAt),
      'carryOverCents': serializer.toJson<int>(carryOverCents),
      'carryOverAdjustmentCents': serializer.toJson<int>(
        carryOverAdjustmentCents,
      ),
      'notes': serializer.toJson<String?>(notes),
    };
  }

  Month copyWith({
    int? id,
    int? year,
    int? month,
    int? incomeCents,
    Value<DateTime?> lockedAt = const Value.absent(),
    int? carryOverCents,
    int? carryOverAdjustmentCents,
    Value<String?> notes = const Value.absent(),
  }) => Month(
    id: id ?? this.id,
    year: year ?? this.year,
    month: month ?? this.month,
    incomeCents: incomeCents ?? this.incomeCents,
    lockedAt: lockedAt.present ? lockedAt.value : this.lockedAt,
    carryOverCents: carryOverCents ?? this.carryOverCents,
    carryOverAdjustmentCents:
        carryOverAdjustmentCents ?? this.carryOverAdjustmentCents,
    notes: notes.present ? notes.value : this.notes,
  );
  Month copyWithCompanion(MonthsCompanion data) {
    return Month(
      id: data.id.present ? data.id.value : this.id,
      year: data.year.present ? data.year.value : this.year,
      month: data.month.present ? data.month.value : this.month,
      incomeCents: data.incomeCents.present
          ? data.incomeCents.value
          : this.incomeCents,
      lockedAt: data.lockedAt.present ? data.lockedAt.value : this.lockedAt,
      carryOverCents: data.carryOverCents.present
          ? data.carryOverCents.value
          : this.carryOverCents,
      carryOverAdjustmentCents: data.carryOverAdjustmentCents.present
          ? data.carryOverAdjustmentCents.value
          : this.carryOverAdjustmentCents,
      notes: data.notes.present ? data.notes.value : this.notes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Month(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('incomeCents: $incomeCents, ')
          ..write('lockedAt: $lockedAt, ')
          ..write('carryOverCents: $carryOverCents, ')
          ..write('carryOverAdjustmentCents: $carryOverAdjustmentCents, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    year,
    month,
    incomeCents,
    lockedAt,
    carryOverCents,
    carryOverAdjustmentCents,
    notes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Month &&
          other.id == this.id &&
          other.year == this.year &&
          other.month == this.month &&
          other.incomeCents == this.incomeCents &&
          other.lockedAt == this.lockedAt &&
          other.carryOverCents == this.carryOverCents &&
          other.carryOverAdjustmentCents == this.carryOverAdjustmentCents &&
          other.notes == this.notes);
}

class MonthsCompanion extends UpdateCompanion<Month> {
  final Value<int> id;
  final Value<int> year;
  final Value<int> month;
  final Value<int> incomeCents;
  final Value<DateTime?> lockedAt;
  final Value<int> carryOverCents;
  final Value<int> carryOverAdjustmentCents;
  final Value<String?> notes;
  const MonthsCompanion({
    this.id = const Value.absent(),
    this.year = const Value.absent(),
    this.month = const Value.absent(),
    this.incomeCents = const Value.absent(),
    this.lockedAt = const Value.absent(),
    this.carryOverCents = const Value.absent(),
    this.carryOverAdjustmentCents = const Value.absent(),
    this.notes = const Value.absent(),
  });
  MonthsCompanion.insert({
    this.id = const Value.absent(),
    required int year,
    required int month,
    this.incomeCents = const Value.absent(),
    this.lockedAt = const Value.absent(),
    this.carryOverCents = const Value.absent(),
    this.carryOverAdjustmentCents = const Value.absent(),
    this.notes = const Value.absent(),
  }) : year = Value(year),
       month = Value(month);
  static Insertable<Month> custom({
    Expression<int>? id,
    Expression<int>? year,
    Expression<int>? month,
    Expression<int>? incomeCents,
    Expression<DateTime>? lockedAt,
    Expression<int>? carryOverCents,
    Expression<int>? carryOverAdjustmentCents,
    Expression<String>? notes,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (year != null) 'year': year,
      if (month != null) 'month': month,
      if (incomeCents != null) 'income_cents': incomeCents,
      if (lockedAt != null) 'locked_at': lockedAt,
      if (carryOverCents != null) 'carry_over_cents': carryOverCents,
      if (carryOverAdjustmentCents != null)
        'carry_over_adjustment_cents': carryOverAdjustmentCents,
      if (notes != null) 'notes': notes,
    });
  }

  MonthsCompanion copyWith({
    Value<int>? id,
    Value<int>? year,
    Value<int>? month,
    Value<int>? incomeCents,
    Value<DateTime?>? lockedAt,
    Value<int>? carryOverCents,
    Value<int>? carryOverAdjustmentCents,
    Value<String?>? notes,
  }) {
    return MonthsCompanion(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      incomeCents: incomeCents ?? this.incomeCents,
      lockedAt: lockedAt ?? this.lockedAt,
      carryOverCents: carryOverCents ?? this.carryOverCents,
      carryOverAdjustmentCents:
          carryOverAdjustmentCents ?? this.carryOverAdjustmentCents,
      notes: notes ?? this.notes,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (month.present) {
      map['month'] = Variable<int>(month.value);
    }
    if (incomeCents.present) {
      map['income_cents'] = Variable<int>(incomeCents.value);
    }
    if (lockedAt.present) {
      map['locked_at'] = Variable<DateTime>(lockedAt.value);
    }
    if (carryOverCents.present) {
      map['carry_over_cents'] = Variable<int>(carryOverCents.value);
    }
    if (carryOverAdjustmentCents.present) {
      map['carry_over_adjustment_cents'] = Variable<int>(
        carryOverAdjustmentCents.value,
      );
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthsCompanion(')
          ..write('id: $id, ')
          ..write('year: $year, ')
          ..write('month: $month, ')
          ..write('incomeCents: $incomeCents, ')
          ..write('lockedAt: $lockedAt, ')
          ..write('carryOverCents: $carryOverCents, ')
          ..write('carryOverAdjustmentCents: $carryOverAdjustmentCents, ')
          ..write('notes: $notes')
          ..write(')'))
        .toString();
  }
}

class $IncomesTable extends Incomes with TableInfo<$IncomesTable, Income> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $IncomesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _monthIdMeta = const VerificationMeta(
    'monthId',
  );
  @override
  late final GeneratedColumn<int> monthId = GeneratedColumn<int>(
    'month_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES months (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, monthId, name, amountCents];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'incomes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Income> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month_id')) {
      context.handle(
        _monthIdMeta,
        monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta),
      );
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Income map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Income(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      monthId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
    );
  }

  @override
  $IncomesTable createAlias(String alias) {
    return $IncomesTable(attachedDatabase, alias);
  }
}

class Income extends DataClass implements Insertable<Income> {
  final int id;
  final int monthId;
  final String name;
  final int amountCents;
  const Income({
    required this.id,
    required this.monthId,
    required this.name,
    required this.amountCents,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month_id'] = Variable<int>(monthId);
    map['name'] = Variable<String>(name);
    map['amount_cents'] = Variable<int>(amountCents);
    return map;
  }

  IncomesCompanion toCompanion(bool nullToAbsent) {
    return IncomesCompanion(
      id: Value(id),
      monthId: Value(monthId),
      name: Value(name),
      amountCents: Value(amountCents),
    );
  }

  factory Income.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Income(
      id: serializer.fromJson<int>(json['id']),
      monthId: serializer.fromJson<int>(json['monthId']),
      name: serializer.fromJson<String>(json['name']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monthId': serializer.toJson<int>(monthId),
      'name': serializer.toJson<String>(name),
      'amountCents': serializer.toJson<int>(amountCents),
    };
  }

  Income copyWith({int? id, int? monthId, String? name, int? amountCents}) =>
      Income(
        id: id ?? this.id,
        monthId: monthId ?? this.monthId,
        name: name ?? this.name,
        amountCents: amountCents ?? this.amountCents,
      );
  Income copyWithCompanion(IncomesCompanion data) {
    return Income(
      id: data.id.present ? data.id.value : this.id,
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      name: data.name.present ? data.name.value : this.name,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Income(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('name: $name, ')
          ..write('amountCents: $amountCents')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, monthId, name, amountCents);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Income &&
          other.id == this.id &&
          other.monthId == this.monthId &&
          other.name == this.name &&
          other.amountCents == this.amountCents);
}

class IncomesCompanion extends UpdateCompanion<Income> {
  final Value<int> id;
  final Value<int> monthId;
  final Value<String> name;
  final Value<int> amountCents;
  const IncomesCompanion({
    this.id = const Value.absent(),
    this.monthId = const Value.absent(),
    this.name = const Value.absent(),
    this.amountCents = const Value.absent(),
  });
  IncomesCompanion.insert({
    this.id = const Value.absent(),
    required int monthId,
    required String name,
    required int amountCents,
  }) : monthId = Value(monthId),
       name = Value(name),
       amountCents = Value(amountCents);
  static Insertable<Income> custom({
    Expression<int>? id,
    Expression<int>? monthId,
    Expression<String>? name,
    Expression<int>? amountCents,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monthId != null) 'month_id': monthId,
      if (name != null) 'name': name,
      if (amountCents != null) 'amount_cents': amountCents,
    });
  }

  IncomesCompanion copyWith({
    Value<int>? id,
    Value<int>? monthId,
    Value<String>? name,
    Value<int>? amountCents,
  }) {
    return IncomesCompanion(
      id: id ?? this.id,
      monthId: monthId ?? this.monthId,
      name: name ?? this.name,
      amountCents: amountCents ?? this.amountCents,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monthId.present) {
      map['month_id'] = Variable<int>(monthId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('IncomesCompanion(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('name: $name, ')
          ..write('amountCents: $amountCents')
          ..write(')'))
        .toString();
  }
}

class $BudgetsTable extends Budgets with TableInfo<$BudgetsTable, Budget> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BudgetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _monthIdMeta = const VerificationMeta(
    'monthId',
  );
  @override
  late final GeneratedColumn<int> monthId = GeneratedColumn<int>(
    'month_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES months (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isFixedMeta = const VerificationMeta(
    'isFixed',
  );
  @override
  late final GeneratedColumn<bool> isFixed = GeneratedColumn<bool>(
    'is_fixed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_fixed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isSinkingFundMeta = const VerificationMeta(
    'isSinkingFund',
  );
  @override
  late final GeneratedColumn<bool> isSinkingFund = GeneratedColumn<bool>(
    'is_sinking_fund',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_sinking_fund" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _savedCentsMeta = const VerificationMeta(
    'savedCents',
  );
  @override
  late final GeneratedColumn<int> savedCents = GeneratedColumn<int>(
    'saved_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _isSavingsMeta = const VerificationMeta(
    'isSavings',
  );
  @override
  late final GeneratedColumn<bool> isSavings = GeneratedColumn<bool>(
    'is_savings',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_savings" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    monthId,
    name,
    amountCents,
    isFixed,
    isSinkingFund,
    savedCents,
    isSavings,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'budgets';
  @override
  VerificationContext validateIntegrity(
    Insertable<Budget> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month_id')) {
      context.handle(
        _monthIdMeta,
        monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta),
      );
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('is_fixed')) {
      context.handle(
        _isFixedMeta,
        isFixed.isAcceptableOrUnknown(data['is_fixed']!, _isFixedMeta),
      );
    }
    if (data.containsKey('is_sinking_fund')) {
      context.handle(
        _isSinkingFundMeta,
        isSinkingFund.isAcceptableOrUnknown(
          data['is_sinking_fund']!,
          _isSinkingFundMeta,
        ),
      );
    }
    if (data.containsKey('saved_cents')) {
      context.handle(
        _savedCentsMeta,
        savedCents.isAcceptableOrUnknown(data['saved_cents']!, _savedCentsMeta),
      );
    }
    if (data.containsKey('is_savings')) {
      context.handle(
        _isSavingsMeta,
        isSavings.isAcceptableOrUnknown(data['is_savings']!, _isSavingsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Budget map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Budget(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      monthId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      isFixed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_fixed'],
      )!,
      isSinkingFund: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_sinking_fund'],
      )!,
      savedCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}saved_cents'],
      )!,
      isSavings: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_savings'],
      )!,
    );
  }

  @override
  $BudgetsTable createAlias(String alias) {
    return $BudgetsTable(attachedDatabase, alias);
  }
}

class Budget extends DataClass implements Insertable<Budget> {
  final int id;
  final int monthId;
  final String name;
  final int amountCents;

  /// Fixed budgets, like rent, are always spent in full.
  final bool isFixed;

  /// Sinking funds save up for costs that don't come every month, like a
  /// yearly insurance fee. The amount is paid into the fund in full, and
  /// whatever isn't spent carries over to the fund next month.
  final bool isSinkingFund;

  /// What a sinking fund had saved before this month; always 0 for other
  /// budgets.
  final int savedCents;

  /// Savings budgets, like a transfer to a savings account, count towards
  /// the savings goal with what's spent from them. They can be fixed, but
  /// never a sinking fund.
  final bool isSavings;
  const Budget({
    required this.id,
    required this.monthId,
    required this.name,
    required this.amountCents,
    required this.isFixed,
    required this.isSinkingFund,
    required this.savedCents,
    required this.isSavings,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month_id'] = Variable<int>(monthId);
    map['name'] = Variable<String>(name);
    map['amount_cents'] = Variable<int>(amountCents);
    map['is_fixed'] = Variable<bool>(isFixed);
    map['is_sinking_fund'] = Variable<bool>(isSinkingFund);
    map['saved_cents'] = Variable<int>(savedCents);
    map['is_savings'] = Variable<bool>(isSavings);
    return map;
  }

  BudgetsCompanion toCompanion(bool nullToAbsent) {
    return BudgetsCompanion(
      id: Value(id),
      monthId: Value(monthId),
      name: Value(name),
      amountCents: Value(amountCents),
      isFixed: Value(isFixed),
      isSinkingFund: Value(isSinkingFund),
      savedCents: Value(savedCents),
      isSavings: Value(isSavings),
    );
  }

  factory Budget.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Budget(
      id: serializer.fromJson<int>(json['id']),
      monthId: serializer.fromJson<int>(json['monthId']),
      name: serializer.fromJson<String>(json['name']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      isFixed: serializer.fromJson<bool>(json['isFixed']),
      isSinkingFund: serializer.fromJson<bool>(json['isSinkingFund']),
      savedCents: serializer.fromJson<int>(json['savedCents']),
      isSavings: serializer.fromJson<bool>(json['isSavings']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monthId': serializer.toJson<int>(monthId),
      'name': serializer.toJson<String>(name),
      'amountCents': serializer.toJson<int>(amountCents),
      'isFixed': serializer.toJson<bool>(isFixed),
      'isSinkingFund': serializer.toJson<bool>(isSinkingFund),
      'savedCents': serializer.toJson<int>(savedCents),
      'isSavings': serializer.toJson<bool>(isSavings),
    };
  }

  Budget copyWith({
    int? id,
    int? monthId,
    String? name,
    int? amountCents,
    bool? isFixed,
    bool? isSinkingFund,
    int? savedCents,
    bool? isSavings,
  }) => Budget(
    id: id ?? this.id,
    monthId: monthId ?? this.monthId,
    name: name ?? this.name,
    amountCents: amountCents ?? this.amountCents,
    isFixed: isFixed ?? this.isFixed,
    isSinkingFund: isSinkingFund ?? this.isSinkingFund,
    savedCents: savedCents ?? this.savedCents,
    isSavings: isSavings ?? this.isSavings,
  );
  Budget copyWithCompanion(BudgetsCompanion data) {
    return Budget(
      id: data.id.present ? data.id.value : this.id,
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      name: data.name.present ? data.name.value : this.name,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      isFixed: data.isFixed.present ? data.isFixed.value : this.isFixed,
      isSinkingFund: data.isSinkingFund.present
          ? data.isSinkingFund.value
          : this.isSinkingFund,
      savedCents: data.savedCents.present
          ? data.savedCents.value
          : this.savedCents,
      isSavings: data.isSavings.present ? data.isSavings.value : this.isSavings,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Budget(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('name: $name, ')
          ..write('amountCents: $amountCents, ')
          ..write('isFixed: $isFixed, ')
          ..write('isSinkingFund: $isSinkingFund, ')
          ..write('savedCents: $savedCents, ')
          ..write('isSavings: $isSavings')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    monthId,
    name,
    amountCents,
    isFixed,
    isSinkingFund,
    savedCents,
    isSavings,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Budget &&
          other.id == this.id &&
          other.monthId == this.monthId &&
          other.name == this.name &&
          other.amountCents == this.amountCents &&
          other.isFixed == this.isFixed &&
          other.isSinkingFund == this.isSinkingFund &&
          other.savedCents == this.savedCents &&
          other.isSavings == this.isSavings);
}

class BudgetsCompanion extends UpdateCompanion<Budget> {
  final Value<int> id;
  final Value<int> monthId;
  final Value<String> name;
  final Value<int> amountCents;
  final Value<bool> isFixed;
  final Value<bool> isSinkingFund;
  final Value<int> savedCents;
  final Value<bool> isSavings;
  const BudgetsCompanion({
    this.id = const Value.absent(),
    this.monthId = const Value.absent(),
    this.name = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.isFixed = const Value.absent(),
    this.isSinkingFund = const Value.absent(),
    this.savedCents = const Value.absent(),
    this.isSavings = const Value.absent(),
  });
  BudgetsCompanion.insert({
    this.id = const Value.absent(),
    required int monthId,
    required String name,
    required int amountCents,
    this.isFixed = const Value.absent(),
    this.isSinkingFund = const Value.absent(),
    this.savedCents = const Value.absent(),
    this.isSavings = const Value.absent(),
  }) : monthId = Value(monthId),
       name = Value(name),
       amountCents = Value(amountCents);
  static Insertable<Budget> custom({
    Expression<int>? id,
    Expression<int>? monthId,
    Expression<String>? name,
    Expression<int>? amountCents,
    Expression<bool>? isFixed,
    Expression<bool>? isSinkingFund,
    Expression<int>? savedCents,
    Expression<bool>? isSavings,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monthId != null) 'month_id': monthId,
      if (name != null) 'name': name,
      if (amountCents != null) 'amount_cents': amountCents,
      if (isFixed != null) 'is_fixed': isFixed,
      if (isSinkingFund != null) 'is_sinking_fund': isSinkingFund,
      if (savedCents != null) 'saved_cents': savedCents,
      if (isSavings != null) 'is_savings': isSavings,
    });
  }

  BudgetsCompanion copyWith({
    Value<int>? id,
    Value<int>? monthId,
    Value<String>? name,
    Value<int>? amountCents,
    Value<bool>? isFixed,
    Value<bool>? isSinkingFund,
    Value<int>? savedCents,
    Value<bool>? isSavings,
  }) {
    return BudgetsCompanion(
      id: id ?? this.id,
      monthId: monthId ?? this.monthId,
      name: name ?? this.name,
      amountCents: amountCents ?? this.amountCents,
      isFixed: isFixed ?? this.isFixed,
      isSinkingFund: isSinkingFund ?? this.isSinkingFund,
      savedCents: savedCents ?? this.savedCents,
      isSavings: isSavings ?? this.isSavings,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monthId.present) {
      map['month_id'] = Variable<int>(monthId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (isFixed.present) {
      map['is_fixed'] = Variable<bool>(isFixed.value);
    }
    if (isSinkingFund.present) {
      map['is_sinking_fund'] = Variable<bool>(isSinkingFund.value);
    }
    if (savedCents.present) {
      map['saved_cents'] = Variable<int>(savedCents.value);
    }
    if (isSavings.present) {
      map['is_savings'] = Variable<bool>(isSavings.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BudgetsCompanion(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('name: $name, ')
          ..write('amountCents: $amountCents, ')
          ..write('isFixed: $isFixed, ')
          ..write('isSinkingFund: $isSinkingFund, ')
          ..write('savedCents: $savedCents, ')
          ..write('isSavings: $isSavings')
          ..write(')'))
        .toString();
  }
}

class $ExpensesTable extends Expenses with TableInfo<$ExpensesTable, Expense> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExpensesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _budgetIdMeta = const VerificationMeta(
    'budgetId',
  );
  @override
  late final GeneratedColumn<int> budgetId = GeneratedColumn<int>(
    'budget_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES budgets (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _amountCentsMeta = const VerificationMeta(
    'amountCents',
  );
  @override
  late final GeneratedColumn<int> amountCents = GeneratedColumn<int>(
    'amount_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 100),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _spentAtMeta = const VerificationMeta(
    'spentAt',
  );
  @override
  late final GeneratedColumn<DateTime> spentAt = GeneratedColumn<DateTime>(
    'spent_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _isFixedMeta = const VerificationMeta(
    'isFixed',
  );
  @override
  late final GeneratedColumn<bool> isFixed = GeneratedColumn<bool>(
    'is_fixed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_fixed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    budgetId,
    amountCents,
    title,
    note,
    spentAt,
    isFixed,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'expenses';
  @override
  VerificationContext validateIntegrity(
    Insertable<Expense> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('budget_id')) {
      context.handle(
        _budgetIdMeta,
        budgetId.isAcceptableOrUnknown(data['budget_id']!, _budgetIdMeta),
      );
    } else if (isInserting) {
      context.missing(_budgetIdMeta);
    }
    if (data.containsKey('amount_cents')) {
      context.handle(
        _amountCentsMeta,
        amountCents.isAcceptableOrUnknown(
          data['amount_cents']!,
          _amountCentsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_amountCentsMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('spent_at')) {
      context.handle(
        _spentAtMeta,
        spentAt.isAcceptableOrUnknown(data['spent_at']!, _spentAtMeta),
      );
    }
    if (data.containsKey('is_fixed')) {
      context.handle(
        _isFixedMeta,
        isFixed.isAcceptableOrUnknown(data['is_fixed']!, _isFixedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Expense map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Expense(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      budgetId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}budget_id'],
      )!,
      amountCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount_cents'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      spentAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}spent_at'],
      )!,
      isFixed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_fixed'],
      )!,
    );
  }

  @override
  $ExpensesTable createAlias(String alias) {
    return $ExpensesTable(attachedDatabase, alias);
  }
}

class Expense extends DataClass implements Insertable<Expense> {
  final int id;
  final int budgetId;
  final int amountCents;

  /// What the money was spent on. Required when entering an expense; fixed
  /// expenses go without.
  final String? title;
  final String? note;
  final DateTime spentAt;

  /// Created automatically when the plan is locked in, spending a fixed
  /// budget in full.
  final bool isFixed;
  const Expense({
    required this.id,
    required this.budgetId,
    required this.amountCents,
    this.title,
    this.note,
    required this.spentAt,
    required this.isFixed,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['budget_id'] = Variable<int>(budgetId);
    map['amount_cents'] = Variable<int>(amountCents);
    if (!nullToAbsent || title != null) {
      map['title'] = Variable<String>(title);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['spent_at'] = Variable<DateTime>(spentAt);
    map['is_fixed'] = Variable<bool>(isFixed);
    return map;
  }

  ExpensesCompanion toCompanion(bool nullToAbsent) {
    return ExpensesCompanion(
      id: Value(id),
      budgetId: Value(budgetId),
      amountCents: Value(amountCents),
      title: title == null && nullToAbsent
          ? const Value.absent()
          : Value(title),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      spentAt: Value(spentAt),
      isFixed: Value(isFixed),
    );
  }

  factory Expense.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Expense(
      id: serializer.fromJson<int>(json['id']),
      budgetId: serializer.fromJson<int>(json['budgetId']),
      amountCents: serializer.fromJson<int>(json['amountCents']),
      title: serializer.fromJson<String?>(json['title']),
      note: serializer.fromJson<String?>(json['note']),
      spentAt: serializer.fromJson<DateTime>(json['spentAt']),
      isFixed: serializer.fromJson<bool>(json['isFixed']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'budgetId': serializer.toJson<int>(budgetId),
      'amountCents': serializer.toJson<int>(amountCents),
      'title': serializer.toJson<String?>(title),
      'note': serializer.toJson<String?>(note),
      'spentAt': serializer.toJson<DateTime>(spentAt),
      'isFixed': serializer.toJson<bool>(isFixed),
    };
  }

  Expense copyWith({
    int? id,
    int? budgetId,
    int? amountCents,
    Value<String?> title = const Value.absent(),
    Value<String?> note = const Value.absent(),
    DateTime? spentAt,
    bool? isFixed,
  }) => Expense(
    id: id ?? this.id,
    budgetId: budgetId ?? this.budgetId,
    amountCents: amountCents ?? this.amountCents,
    title: title.present ? title.value : this.title,
    note: note.present ? note.value : this.note,
    spentAt: spentAt ?? this.spentAt,
    isFixed: isFixed ?? this.isFixed,
  );
  Expense copyWithCompanion(ExpensesCompanion data) {
    return Expense(
      id: data.id.present ? data.id.value : this.id,
      budgetId: data.budgetId.present ? data.budgetId.value : this.budgetId,
      amountCents: data.amountCents.present
          ? data.amountCents.value
          : this.amountCents,
      title: data.title.present ? data.title.value : this.title,
      note: data.note.present ? data.note.value : this.note,
      spentAt: data.spentAt.present ? data.spentAt.value : this.spentAt,
      isFixed: data.isFixed.present ? data.isFixed.value : this.isFixed,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Expense(')
          ..write('id: $id, ')
          ..write('budgetId: $budgetId, ')
          ..write('amountCents: $amountCents, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('spentAt: $spentAt, ')
          ..write('isFixed: $isFixed')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, budgetId, amountCents, title, note, spentAt, isFixed);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Expense &&
          other.id == this.id &&
          other.budgetId == this.budgetId &&
          other.amountCents == this.amountCents &&
          other.title == this.title &&
          other.note == this.note &&
          other.spentAt == this.spentAt &&
          other.isFixed == this.isFixed);
}

class ExpensesCompanion extends UpdateCompanion<Expense> {
  final Value<int> id;
  final Value<int> budgetId;
  final Value<int> amountCents;
  final Value<String?> title;
  final Value<String?> note;
  final Value<DateTime> spentAt;
  final Value<bool> isFixed;
  const ExpensesCompanion({
    this.id = const Value.absent(),
    this.budgetId = const Value.absent(),
    this.amountCents = const Value.absent(),
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.spentAt = const Value.absent(),
    this.isFixed = const Value.absent(),
  });
  ExpensesCompanion.insert({
    this.id = const Value.absent(),
    required int budgetId,
    required int amountCents,
    this.title = const Value.absent(),
    this.note = const Value.absent(),
    this.spentAt = const Value.absent(),
    this.isFixed = const Value.absent(),
  }) : budgetId = Value(budgetId),
       amountCents = Value(amountCents);
  static Insertable<Expense> custom({
    Expression<int>? id,
    Expression<int>? budgetId,
    Expression<int>? amountCents,
    Expression<String>? title,
    Expression<String>? note,
    Expression<DateTime>? spentAt,
    Expression<bool>? isFixed,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (budgetId != null) 'budget_id': budgetId,
      if (amountCents != null) 'amount_cents': amountCents,
      if (title != null) 'title': title,
      if (note != null) 'note': note,
      if (spentAt != null) 'spent_at': spentAt,
      if (isFixed != null) 'is_fixed': isFixed,
    });
  }

  ExpensesCompanion copyWith({
    Value<int>? id,
    Value<int>? budgetId,
    Value<int>? amountCents,
    Value<String?>? title,
    Value<String?>? note,
    Value<DateTime>? spentAt,
    Value<bool>? isFixed,
  }) {
    return ExpensesCompanion(
      id: id ?? this.id,
      budgetId: budgetId ?? this.budgetId,
      amountCents: amountCents ?? this.amountCents,
      title: title ?? this.title,
      note: note ?? this.note,
      spentAt: spentAt ?? this.spentAt,
      isFixed: isFixed ?? this.isFixed,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (budgetId.present) {
      map['budget_id'] = Variable<int>(budgetId.value);
    }
    if (amountCents.present) {
      map['amount_cents'] = Variable<int>(amountCents.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (spentAt.present) {
      map['spent_at'] = Variable<DateTime>(spentAt.value);
    }
    if (isFixed.present) {
      map['is_fixed'] = Variable<bool>(isFixed.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExpensesCompanion(')
          ..write('id: $id, ')
          ..write('budgetId: $budgetId, ')
          ..write('amountCents: $amountCents, ')
          ..write('title: $title, ')
          ..write('note: $note, ')
          ..write('spentAt: $spentAt, ')
          ..write('isFixed: $isFixed')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bufferCentsMeta = const VerificationMeta(
    'bufferCents',
  );
  @override
  late final GeneratedColumn<int> bufferCents = GeneratedColumn<int>(
    'buffer_cents',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(defaultBufferCents),
  );
  static const VerificationMeta _selectedYearMonthMeta = const VerificationMeta(
    'selectedYearMonth',
  );
  @override
  late final GeneratedColumn<int> selectedYearMonth = GeneratedColumn<int>(
    'selected_year_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _offeredYearMonthMeta = const VerificationMeta(
    'offeredYearMonth',
  );
  @override
  late final GeneratedColumn<int> offeredYearMonth = GeneratedColumn<int>(
    'offered_year_month',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _showDebugBarMeta = const VerificationMeta(
    'showDebugBar',
  );
  @override
  late final GeneratedColumn<bool> showDebugBar = GeneratedColumn<bool>(
    'show_debug_bar',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("show_debug_bar" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _savingsGoalCentsMeta = const VerificationMeta(
    'savingsGoalCents',
  );
  @override
  late final GeneratedColumn<int> savingsGoalCents = GeneratedColumn<int>(
    'savings_goal_cents',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SavingsPeriod, String>
  savingsGoalPeriod = GeneratedColumn<String>(
    'savings_goal_period',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: Constant(SavingsPeriod.year.name),
  ).withConverter<SavingsPeriod>($SettingsTable.$convertersavingsGoalPeriod);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    bufferCents,
    selectedYearMonth,
    offeredYearMonth,
    showDebugBar,
    savingsGoalCents,
    savingsGoalPeriod,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('buffer_cents')) {
      context.handle(
        _bufferCentsMeta,
        bufferCents.isAcceptableOrUnknown(
          data['buffer_cents']!,
          _bufferCentsMeta,
        ),
      );
    }
    if (data.containsKey('selected_year_month')) {
      context.handle(
        _selectedYearMonthMeta,
        selectedYearMonth.isAcceptableOrUnknown(
          data['selected_year_month']!,
          _selectedYearMonthMeta,
        ),
      );
    }
    if (data.containsKey('offered_year_month')) {
      context.handle(
        _offeredYearMonthMeta,
        offeredYearMonth.isAcceptableOrUnknown(
          data['offered_year_month']!,
          _offeredYearMonthMeta,
        ),
      );
    }
    if (data.containsKey('show_debug_bar')) {
      context.handle(
        _showDebugBarMeta,
        showDebugBar.isAcceptableOrUnknown(
          data['show_debug_bar']!,
          _showDebugBarMeta,
        ),
      );
    }
    if (data.containsKey('savings_goal_cents')) {
      context.handle(
        _savingsGoalCentsMeta,
        savingsGoalCents.isAcceptableOrUnknown(
          data['savings_goal_cents']!,
          _savingsGoalCentsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      bufferCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}buffer_cents'],
      )!,
      selectedYearMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}selected_year_month'],
      ),
      offeredYearMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}offered_year_month'],
      ),
      showDebugBar: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}show_debug_bar'],
      )!,
      savingsGoalCents: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}savings_goal_cents'],
      ),
      savingsGoalPeriod: $SettingsTable.$convertersavingsGoalPeriod.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}savings_goal_period'],
        )!,
      ),
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SavingsPeriod, String, String>
  $convertersavingsGoalPeriod = const EnumNameConverter<SavingsPeriod>(
    SavingsPeriod.values,
  );
}

class Setting extends DataClass implements Insertable<Setting> {
  /// Always [settingsRowId].
  final int id;

  /// Money always kept in the bank account on top of the plan, as a safety
  /// net.
  final int bufferCents;

  /// The month the user works in, see [encodeYearMonth]; null until the app
  /// first opens.
  final int? selectedYearMonth;

  /// The latest month the user was offered to move on to, or chose to be in,
  /// see [encodeYearMonth]. Each new month is offered only once.
  final int? offeredYearMonth;

  /// Whether debug builds show the bar to move through days and months.
  final bool showDebugBar;

  /// What to save in each [savingsGoalPeriod]; null while there's no goal.
  final int? savingsGoalCents;
  final SavingsPeriod savingsGoalPeriod;
  const Setting({
    required this.id,
    required this.bufferCents,
    this.selectedYearMonth,
    this.offeredYearMonth,
    required this.showDebugBar,
    this.savingsGoalCents,
    required this.savingsGoalPeriod,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['buffer_cents'] = Variable<int>(bufferCents);
    if (!nullToAbsent || selectedYearMonth != null) {
      map['selected_year_month'] = Variable<int>(selectedYearMonth);
    }
    if (!nullToAbsent || offeredYearMonth != null) {
      map['offered_year_month'] = Variable<int>(offeredYearMonth);
    }
    map['show_debug_bar'] = Variable<bool>(showDebugBar);
    if (!nullToAbsent || savingsGoalCents != null) {
      map['savings_goal_cents'] = Variable<int>(savingsGoalCents);
    }
    {
      map['savings_goal_period'] = Variable<String>(
        $SettingsTable.$convertersavingsGoalPeriod.toSql(savingsGoalPeriod),
      );
    }
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      id: Value(id),
      bufferCents: Value(bufferCents),
      selectedYearMonth: selectedYearMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(selectedYearMonth),
      offeredYearMonth: offeredYearMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(offeredYearMonth),
      showDebugBar: Value(showDebugBar),
      savingsGoalCents: savingsGoalCents == null && nullToAbsent
          ? const Value.absent()
          : Value(savingsGoalCents),
      savingsGoalPeriod: Value(savingsGoalPeriod),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      id: serializer.fromJson<int>(json['id']),
      bufferCents: serializer.fromJson<int>(json['bufferCents']),
      selectedYearMonth: serializer.fromJson<int?>(json['selectedYearMonth']),
      offeredYearMonth: serializer.fromJson<int?>(json['offeredYearMonth']),
      showDebugBar: serializer.fromJson<bool>(json['showDebugBar']),
      savingsGoalCents: serializer.fromJson<int?>(json['savingsGoalCents']),
      savingsGoalPeriod: $SettingsTable.$convertersavingsGoalPeriod.fromJson(
        serializer.fromJson<String>(json['savingsGoalPeriod']),
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'bufferCents': serializer.toJson<int>(bufferCents),
      'selectedYearMonth': serializer.toJson<int?>(selectedYearMonth),
      'offeredYearMonth': serializer.toJson<int?>(offeredYearMonth),
      'showDebugBar': serializer.toJson<bool>(showDebugBar),
      'savingsGoalCents': serializer.toJson<int?>(savingsGoalCents),
      'savingsGoalPeriod': serializer.toJson<String>(
        $SettingsTable.$convertersavingsGoalPeriod.toJson(savingsGoalPeriod),
      ),
    };
  }

  Setting copyWith({
    int? id,
    int? bufferCents,
    Value<int?> selectedYearMonth = const Value.absent(),
    Value<int?> offeredYearMonth = const Value.absent(),
    bool? showDebugBar,
    Value<int?> savingsGoalCents = const Value.absent(),
    SavingsPeriod? savingsGoalPeriod,
  }) => Setting(
    id: id ?? this.id,
    bufferCents: bufferCents ?? this.bufferCents,
    selectedYearMonth: selectedYearMonth.present
        ? selectedYearMonth.value
        : this.selectedYearMonth,
    offeredYearMonth: offeredYearMonth.present
        ? offeredYearMonth.value
        : this.offeredYearMonth,
    showDebugBar: showDebugBar ?? this.showDebugBar,
    savingsGoalCents: savingsGoalCents.present
        ? savingsGoalCents.value
        : this.savingsGoalCents,
    savingsGoalPeriod: savingsGoalPeriod ?? this.savingsGoalPeriod,
  );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      id: data.id.present ? data.id.value : this.id,
      bufferCents: data.bufferCents.present
          ? data.bufferCents.value
          : this.bufferCents,
      selectedYearMonth: data.selectedYearMonth.present
          ? data.selectedYearMonth.value
          : this.selectedYearMonth,
      offeredYearMonth: data.offeredYearMonth.present
          ? data.offeredYearMonth.value
          : this.offeredYearMonth,
      showDebugBar: data.showDebugBar.present
          ? data.showDebugBar.value
          : this.showDebugBar,
      savingsGoalCents: data.savingsGoalCents.present
          ? data.savingsGoalCents.value
          : this.savingsGoalCents,
      savingsGoalPeriod: data.savingsGoalPeriod.present
          ? data.savingsGoalPeriod.value
          : this.savingsGoalPeriod,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('id: $id, ')
          ..write('bufferCents: $bufferCents, ')
          ..write('selectedYearMonth: $selectedYearMonth, ')
          ..write('offeredYearMonth: $offeredYearMonth, ')
          ..write('showDebugBar: $showDebugBar, ')
          ..write('savingsGoalCents: $savingsGoalCents, ')
          ..write('savingsGoalPeriod: $savingsGoalPeriod')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    bufferCents,
    selectedYearMonth,
    offeredYearMonth,
    showDebugBar,
    savingsGoalCents,
    savingsGoalPeriod,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.id == this.id &&
          other.bufferCents == this.bufferCents &&
          other.selectedYearMonth == this.selectedYearMonth &&
          other.offeredYearMonth == this.offeredYearMonth &&
          other.showDebugBar == this.showDebugBar &&
          other.savingsGoalCents == this.savingsGoalCents &&
          other.savingsGoalPeriod == this.savingsGoalPeriod);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<int> id;
  final Value<int> bufferCents;
  final Value<int?> selectedYearMonth;
  final Value<int?> offeredYearMonth;
  final Value<bool> showDebugBar;
  final Value<int?> savingsGoalCents;
  final Value<SavingsPeriod> savingsGoalPeriod;
  const SettingsCompanion({
    this.id = const Value.absent(),
    this.bufferCents = const Value.absent(),
    this.selectedYearMonth = const Value.absent(),
    this.offeredYearMonth = const Value.absent(),
    this.showDebugBar = const Value.absent(),
    this.savingsGoalCents = const Value.absent(),
    this.savingsGoalPeriod = const Value.absent(),
  });
  SettingsCompanion.insert({
    this.id = const Value.absent(),
    this.bufferCents = const Value.absent(),
    this.selectedYearMonth = const Value.absent(),
    this.offeredYearMonth = const Value.absent(),
    this.showDebugBar = const Value.absent(),
    this.savingsGoalCents = const Value.absent(),
    this.savingsGoalPeriod = const Value.absent(),
  });
  static Insertable<Setting> custom({
    Expression<int>? id,
    Expression<int>? bufferCents,
    Expression<int>? selectedYearMonth,
    Expression<int>? offeredYearMonth,
    Expression<bool>? showDebugBar,
    Expression<int>? savingsGoalCents,
    Expression<String>? savingsGoalPeriod,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (bufferCents != null) 'buffer_cents': bufferCents,
      if (selectedYearMonth != null) 'selected_year_month': selectedYearMonth,
      if (offeredYearMonth != null) 'offered_year_month': offeredYearMonth,
      if (showDebugBar != null) 'show_debug_bar': showDebugBar,
      if (savingsGoalCents != null) 'savings_goal_cents': savingsGoalCents,
      if (savingsGoalPeriod != null) 'savings_goal_period': savingsGoalPeriod,
    });
  }

  SettingsCompanion copyWith({
    Value<int>? id,
    Value<int>? bufferCents,
    Value<int?>? selectedYearMonth,
    Value<int?>? offeredYearMonth,
    Value<bool>? showDebugBar,
    Value<int?>? savingsGoalCents,
    Value<SavingsPeriod>? savingsGoalPeriod,
  }) {
    return SettingsCompanion(
      id: id ?? this.id,
      bufferCents: bufferCents ?? this.bufferCents,
      selectedYearMonth: selectedYearMonth ?? this.selectedYearMonth,
      offeredYearMonth: offeredYearMonth ?? this.offeredYearMonth,
      showDebugBar: showDebugBar ?? this.showDebugBar,
      savingsGoalCents: savingsGoalCents ?? this.savingsGoalCents,
      savingsGoalPeriod: savingsGoalPeriod ?? this.savingsGoalPeriod,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (bufferCents.present) {
      map['buffer_cents'] = Variable<int>(bufferCents.value);
    }
    if (selectedYearMonth.present) {
      map['selected_year_month'] = Variable<int>(selectedYearMonth.value);
    }
    if (offeredYearMonth.present) {
      map['offered_year_month'] = Variable<int>(offeredYearMonth.value);
    }
    if (showDebugBar.present) {
      map['show_debug_bar'] = Variable<bool>(showDebugBar.value);
    }
    if (savingsGoalCents.present) {
      map['savings_goal_cents'] = Variable<int>(savingsGoalCents.value);
    }
    if (savingsGoalPeriod.present) {
      map['savings_goal_period'] = Variable<String>(
        $SettingsTable.$convertersavingsGoalPeriod.toSql(
          savingsGoalPeriod.value,
        ),
      );
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('id: $id, ')
          ..write('bufferCents: $bufferCents, ')
          ..write('selectedYearMonth: $selectedYearMonth, ')
          ..write('offeredYearMonth: $offeredYearMonth, ')
          ..write('showDebugBar: $showDebugBar, ')
          ..write('savingsGoalCents: $savingsGoalCents, ')
          ..write('savingsGoalPeriod: $savingsGoalPeriod')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MonthsTable months = $MonthsTable(this);
  late final $IncomesTable incomes = $IncomesTable(this);
  late final $BudgetsTable budgets = $BudgetsTable(this);
  late final $ExpensesTable expenses = $ExpensesTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    months,
    incomes,
    budgets,
    expenses,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'months',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('incomes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'months',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('budgets', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'budgets',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('expenses', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$MonthsTableCreateCompanionBuilder = MonthsCompanion Function({
  Value<int> id,
  required int year,
  required int month,
  Value<int> incomeCents,
  Value<DateTime?> lockedAt,
  Value<int> carryOverCents,
  Value<int> carryOverAdjustmentCents,
  Value<String?> notes,
});
typedef $$MonthsTableUpdateCompanionBuilder = MonthsCompanion Function({
  Value<int> id,
  Value<int> year,
  Value<int> month,
  Value<int> incomeCents,
  Value<DateTime?> lockedAt,
  Value<int> carryOverCents,
  Value<int> carryOverAdjustmentCents,
  Value<String?> notes,
});

final class $$MonthsTableReferences
    extends BaseReferences<_$AppDatabase, $MonthsTable, Month> {
  $$MonthsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$IncomesTable, List<Income>> _incomesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.incomes,
    aliasName: 'months__id__incomes__month_id',
  );

  $$IncomesTableProcessedTableManager get incomesRefs {
    final manager = $$IncomesTableTableManager(
      $_db,
      $_db.incomes,
    ).filter((f) => f.monthId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_incomesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$BudgetsTable, List<Budget>> _budgetsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.budgets,
    aliasName: 'months__id__budgets__month_id',
  );

  $$BudgetsTableProcessedTableManager get budgetsRefs {
    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.monthId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_budgetsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MonthsTableFilterComposer
    extends Composer<_$AppDatabase, $MonthsTable> {
  $$MonthsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get incomeCents => $composableBuilder(
    column: $table.incomeCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lockedAt => $composableBuilder(
    column: $table.lockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carryOverCents => $composableBuilder(
    column: $table.carryOverCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get carryOverAdjustmentCents => $composableBuilder(
    column: $table.carryOverAdjustmentCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> incomesRefs(
    Expression<bool> Function($$IncomesTableFilterComposer f) f,
  ) {
    final $$IncomesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incomes,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomesTableFilterComposer(
            $db: $db,
            $table: $db.incomes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> budgetsRefs(
    Expression<bool> Function($$BudgetsTableFilterComposer f) f,
  ) {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MonthsTableOrderingComposer
    extends Composer<_$AppDatabase, $MonthsTable> {
  $$MonthsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get month => $composableBuilder(
    column: $table.month,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get incomeCents => $composableBuilder(
    column: $table.incomeCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lockedAt => $composableBuilder(
    column: $table.lockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carryOverCents => $composableBuilder(
    column: $table.carryOverCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get carryOverAdjustmentCents => $composableBuilder(
    column: $table.carryOverAdjustmentCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MonthsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MonthsTable> {
  $$MonthsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<int> get month =>
      $composableBuilder(column: $table.month, builder: (column) => column);

  GeneratedColumn<int> get incomeCents => $composableBuilder(
    column: $table.incomeCents,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get lockedAt =>
      $composableBuilder(column: $table.lockedAt, builder: (column) => column);

  GeneratedColumn<int> get carryOverCents => $composableBuilder(
    column: $table.carryOverCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get carryOverAdjustmentCents => $composableBuilder(
    column: $table.carryOverAdjustmentCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  Expression<T> incomesRefs<T extends Object>(
    Expression<T> Function($$IncomesTableAnnotationComposer a) f,
  ) {
    final $$IncomesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.incomes,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$IncomesTableAnnotationComposer(
            $db: $db,
            $table: $db.incomes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> budgetsRefs<T extends Object>(
    Expression<T> Function($$BudgetsTableAnnotationComposer a) f,
  ) {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.monthId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MonthsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MonthsTable,
          Month,
          $$MonthsTableFilterComposer,
          $$MonthsTableOrderingComposer,
          $$MonthsTableAnnotationComposer,
          $$MonthsTableCreateCompanionBuilder,
          $$MonthsTableUpdateCompanionBuilder,
          (Month, $$MonthsTableReferences),
          Month,
          PrefetchHooks Function({bool incomesRefs, bool budgetsRefs})
        > {
  $$MonthsTableTableManager(_$AppDatabase db, $MonthsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MonthsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MonthsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MonthsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> year = const Value.absent(),
                Value<int> month = const Value.absent(),
                Value<int> incomeCents = const Value.absent(),
                Value<DateTime?> lockedAt = const Value.absent(),
                Value<int> carryOverCents = const Value.absent(),
                Value<int> carryOverAdjustmentCents = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => MonthsCompanion(
                id: id,
                year: year,
                month: month,
                incomeCents: incomeCents,
                lockedAt: lockedAt,
                carryOverCents: carryOverCents,
                carryOverAdjustmentCents: carryOverAdjustmentCents,
                notes: notes,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int year,
                required int month,
                Value<int> incomeCents = const Value.absent(),
                Value<DateTime?> lockedAt = const Value.absent(),
                Value<int> carryOverCents = const Value.absent(),
                Value<int> carryOverAdjustmentCents = const Value.absent(),
                Value<String?> notes = const Value.absent(),
              }) => MonthsCompanion.insert(
                id: id,
                year: year,
                month: month,
                incomeCents: incomeCents,
                lockedAt: lockedAt,
                carryOverCents: carryOverCents,
                carryOverAdjustmentCents: carryOverAdjustmentCents,
                notes: notes,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MonthsTable, Month>(table),
                  $$MonthsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({incomesRefs = false, budgetsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (incomesRefs) db.incomes,
                if (budgetsRefs) db.budgets,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (incomesRefs)
                    await $_getPrefetchedData<Month, $MonthsTable, Income>(
                      currentTable: table,
                      referencedTable: $$MonthsTableReferences
                          ._incomesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MonthsTableReferences(db, table, p0).incomesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.monthId == item.id),
                      typedResults: items,
                    ),
                  if (budgetsRefs)
                    await $_getPrefetchedData<Month, $MonthsTable, Budget>(
                      currentTable: table,
                      referencedTable: $$MonthsTableReferences
                          ._budgetsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MonthsTableReferences(db, table, p0).budgetsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.monthId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MonthsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MonthsTable,
      Month,
      $$MonthsTableFilterComposer,
      $$MonthsTableOrderingComposer,
      $$MonthsTableAnnotationComposer,
      $$MonthsTableCreateCompanionBuilder,
      $$MonthsTableUpdateCompanionBuilder,
      (Month, $$MonthsTableReferences),
      Month,
      PrefetchHooks Function({bool incomesRefs, bool budgetsRefs})
    >;
typedef $$IncomesTableCreateCompanionBuilder = IncomesCompanion Function({
  Value<int> id,
  required int monthId,
  required String name,
  required int amountCents,
});
typedef $$IncomesTableUpdateCompanionBuilder = IncomesCompanion Function({
  Value<int> id,
  Value<int> monthId,
  Value<String> name,
  Value<int> amountCents,
});

final class $$IncomesTableReferences
    extends BaseReferences<_$AppDatabase, $IncomesTable, Income> {
  $$IncomesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MonthsTable _monthIdTable(_$AppDatabase db) =>
      db.months.createAlias('incomes__month_id__months__id');

  $$MonthsTableProcessedTableManager get monthId {
    final $_column = $_itemColumn<int>('month_id')!;

    final manager = $$MonthsTableTableManager(
      $_db,
      $_db.months,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_monthIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$IncomesTableFilterComposer
    extends Composer<_$AppDatabase, $IncomesTable> {
  $$IncomesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  $$MonthsTableFilterComposer get monthId {
    final $$MonthsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableFilterComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncomesTableOrderingComposer
    extends Composer<_$AppDatabase, $IncomesTable> {
  $$IncomesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  $$MonthsTableOrderingComposer get monthId {
    final $$MonthsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableOrderingComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncomesTableAnnotationComposer
    extends Composer<_$AppDatabase, $IncomesTable> {
  $$IncomesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  $$MonthsTableAnnotationComposer get monthId {
    final $$MonthsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableAnnotationComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$IncomesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $IncomesTable,
          Income,
          $$IncomesTableFilterComposer,
          $$IncomesTableOrderingComposer,
          $$IncomesTableAnnotationComposer,
          $$IncomesTableCreateCompanionBuilder,
          $$IncomesTableUpdateCompanionBuilder,
          (Income, $$IncomesTableReferences),
          Income,
          PrefetchHooks Function({bool monthId})
        > {
  $$IncomesTableTableManager(_$AppDatabase db, $IncomesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$IncomesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$IncomesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$IncomesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> monthId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
              }) => IncomesCompanion(
                id: id,
                monthId: monthId,
                name: name,
                amountCents: amountCents,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int monthId,
                required String name,
                required int amountCents,
              }) => IncomesCompanion.insert(
                id: id,
                monthId: monthId,
                name: name,
                amountCents: amountCents,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$IncomesTable, Income>(table),
                  $$IncomesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({monthId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (monthId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.monthId,
                        referencedTable: $$IncomesTableReferences._monthIdTable(
                          db,
                        ),
                        referencedColumn: $$IncomesTableReferences
                            ._monthIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$IncomesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $IncomesTable,
      Income,
      $$IncomesTableFilterComposer,
      $$IncomesTableOrderingComposer,
      $$IncomesTableAnnotationComposer,
      $$IncomesTableCreateCompanionBuilder,
      $$IncomesTableUpdateCompanionBuilder,
      (Income, $$IncomesTableReferences),
      Income,
      PrefetchHooks Function({bool monthId})
    >;
typedef $$BudgetsTableCreateCompanionBuilder = BudgetsCompanion Function({
  Value<int> id,
  required int monthId,
  required String name,
  required int amountCents,
  Value<bool> isFixed,
  Value<bool> isSinkingFund,
  Value<int> savedCents,
  Value<bool> isSavings,
});
typedef $$BudgetsTableUpdateCompanionBuilder = BudgetsCompanion Function({
  Value<int> id,
  Value<int> monthId,
  Value<String> name,
  Value<int> amountCents,
  Value<bool> isFixed,
  Value<bool> isSinkingFund,
  Value<int> savedCents,
  Value<bool> isSavings,
});

final class $$BudgetsTableReferences
    extends BaseReferences<_$AppDatabase, $BudgetsTable, Budget> {
  $$BudgetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MonthsTable _monthIdTable(_$AppDatabase db) =>
      db.months.createAlias('budgets__month_id__months__id');

  $$MonthsTableProcessedTableManager get monthId {
    final $_column = $_itemColumn<int>('month_id')!;

    final manager = $$MonthsTableTableManager(
      $_db,
      $_db.months,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_monthIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$ExpensesTable, List<Expense>> _expensesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.expenses,
    aliasName: 'budgets__id__expenses__budget_id',
  );

  $$ExpensesTableProcessedTableManager get expensesRefs {
    final manager = $$ExpensesTableTableManager(
      $_db,
      $_db.expenses,
    ).filter((f) => f.budgetId.id.sqlEquals($_itemColumn<int>('id')!));

    final cache = $_typedResult.readTableOrNull(_expensesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BudgetsTableFilterComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFixed => $composableBuilder(
    column: $table.isFixed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSinkingFund => $composableBuilder(
    column: $table.isSinkingFund,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savedCents => $composableBuilder(
    column: $table.savedCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isSavings => $composableBuilder(
    column: $table.isSavings,
    builder: (column) => ColumnFilters(column),
  );

  $$MonthsTableFilterComposer get monthId {
    final $$MonthsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableFilterComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> expensesRefs(
    Expression<bool> Function($$ExpensesTableFilterComposer f) f,
  ) {
    final $$ExpensesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.budgetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableFilterComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BudgetsTableOrderingComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFixed => $composableBuilder(
    column: $table.isFixed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSinkingFund => $composableBuilder(
    column: $table.isSinkingFund,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savedCents => $composableBuilder(
    column: $table.savedCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isSavings => $composableBuilder(
    column: $table.isSavings,
    builder: (column) => ColumnOrderings(column),
  );

  $$MonthsTableOrderingComposer get monthId {
    final $$MonthsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableOrderingComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BudgetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BudgetsTable> {
  $$BudgetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isFixed =>
      $composableBuilder(column: $table.isFixed, builder: (column) => column);

  GeneratedColumn<bool> get isSinkingFund => $composableBuilder(
    column: $table.isSinkingFund,
    builder: (column) => column,
  );

  GeneratedColumn<int> get savedCents => $composableBuilder(
    column: $table.savedCents,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isSavings =>
      $composableBuilder(column: $table.isSavings, builder: (column) => column);

  $$MonthsTableAnnotationComposer get monthId {
    final $$MonthsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.monthId,
      referencedTable: $db.months,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MonthsTableAnnotationComposer(
            $db: $db,
            $table: $db.months,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> expensesRefs<T extends Object>(
    Expression<T> Function($$ExpensesTableAnnotationComposer a) f,
  ) {
    final $$ExpensesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.expenses,
      getReferencedColumn: (t) => t.budgetId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExpensesTableAnnotationComposer(
            $db: $db,
            $table: $db.expenses,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$BudgetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BudgetsTable,
          Budget,
          $$BudgetsTableFilterComposer,
          $$BudgetsTableOrderingComposer,
          $$BudgetsTableAnnotationComposer,
          $$BudgetsTableCreateCompanionBuilder,
          $$BudgetsTableUpdateCompanionBuilder,
          (Budget, $$BudgetsTableReferences),
          Budget,
          PrefetchHooks Function({bool monthId, bool expensesRefs})
        > {
  $$BudgetsTableTableManager(_$AppDatabase db, $BudgetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BudgetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BudgetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BudgetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> monthId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<bool> isFixed = const Value.absent(),
                Value<bool> isSinkingFund = const Value.absent(),
                Value<int> savedCents = const Value.absent(),
                Value<bool> isSavings = const Value.absent(),
              }) => BudgetsCompanion(
                id: id,
                monthId: monthId,
                name: name,
                amountCents: amountCents,
                isFixed: isFixed,
                isSinkingFund: isSinkingFund,
                savedCents: savedCents,
                isSavings: isSavings,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int monthId,
                required String name,
                required int amountCents,
                Value<bool> isFixed = const Value.absent(),
                Value<bool> isSinkingFund = const Value.absent(),
                Value<int> savedCents = const Value.absent(),
                Value<bool> isSavings = const Value.absent(),
              }) => BudgetsCompanion.insert(
                id: id,
                monthId: monthId,
                name: name,
                amountCents: amountCents,
                isFixed: isFixed,
                isSinkingFund: isSinkingFund,
                savedCents: savedCents,
                isSavings: isSavings,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BudgetsTable, Budget>(table),
                  $$BudgetsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({monthId = false, expensesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (expensesRefs) db.expenses],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (monthId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.monthId,
                        referencedTable: $$BudgetsTableReferences._monthIdTable(
                          db,
                        ),
                        referencedColumn: $$BudgetsTableReferences
                            ._monthIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (expensesRefs)
                    await $_getPrefetchedData<Budget, $BudgetsTable, Expense>(
                      currentTable: table,
                      referencedTable: $$BudgetsTableReferences
                          ._expensesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$BudgetsTableReferences(db, table, p0).expensesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.budgetId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$BudgetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BudgetsTable,
      Budget,
      $$BudgetsTableFilterComposer,
      $$BudgetsTableOrderingComposer,
      $$BudgetsTableAnnotationComposer,
      $$BudgetsTableCreateCompanionBuilder,
      $$BudgetsTableUpdateCompanionBuilder,
      (Budget, $$BudgetsTableReferences),
      Budget,
      PrefetchHooks Function({bool monthId, bool expensesRefs})
    >;
typedef $$ExpensesTableCreateCompanionBuilder = ExpensesCompanion Function({
  Value<int> id,
  required int budgetId,
  required int amountCents,
  Value<String?> title,
  Value<String?> note,
  Value<DateTime> spentAt,
  Value<bool> isFixed,
});
typedef $$ExpensesTableUpdateCompanionBuilder = ExpensesCompanion Function({
  Value<int> id,
  Value<int> budgetId,
  Value<int> amountCents,
  Value<String?> title,
  Value<String?> note,
  Value<DateTime> spentAt,
  Value<bool> isFixed,
});

final class $$ExpensesTableReferences
    extends BaseReferences<_$AppDatabase, $ExpensesTable, Expense> {
  $$ExpensesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $BudgetsTable _budgetIdTable(_$AppDatabase db) =>
      db.budgets.createAlias('expenses__budget_id__budgets__id');

  $$BudgetsTableProcessedTableManager get budgetId {
    final $_column = $_itemColumn<int>('budget_id')!;

    final manager = $$BudgetsTableTableManager(
      $_db,
      $_db.budgets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_budgetIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ExpensesTableFilterComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get spentAt => $composableBuilder(
    column: $table.spentAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFixed => $composableBuilder(
    column: $table.isFixed,
    builder: (column) => ColumnFilters(column),
  );

  $$BudgetsTableFilterComposer get budgetId {
    final $$BudgetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetId,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableFilterComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get spentAt => $composableBuilder(
    column: $table.spentAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFixed => $composableBuilder(
    column: $table.isFixed,
    builder: (column) => ColumnOrderings(column),
  );

  $$BudgetsTableOrderingComposer get budgetId {
    final $$BudgetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetId,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableOrderingComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExpensesTable> {
  $$ExpensesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get amountCents => $composableBuilder(
    column: $table.amountCents,
    builder: (column) => column,
  );

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<DateTime> get spentAt =>
      $composableBuilder(column: $table.spentAt, builder: (column) => column);

  GeneratedColumn<bool> get isFixed =>
      $composableBuilder(column: $table.isFixed, builder: (column) => column);

  $$BudgetsTableAnnotationComposer get budgetId {
    final $$BudgetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.budgetId,
      referencedTable: $db.budgets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BudgetsTableAnnotationComposer(
            $db: $db,
            $table: $db.budgets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ExpensesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExpensesTable,
          Expense,
          $$ExpensesTableFilterComposer,
          $$ExpensesTableOrderingComposer,
          $$ExpensesTableAnnotationComposer,
          $$ExpensesTableCreateCompanionBuilder,
          $$ExpensesTableUpdateCompanionBuilder,
          (Expense, $$ExpensesTableReferences),
          Expense,
          PrefetchHooks Function({bool budgetId})
        > {
  $$ExpensesTableTableManager(_$AppDatabase db, $ExpensesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExpensesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExpensesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExpensesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> budgetId = const Value.absent(),
                Value<int> amountCents = const Value.absent(),
                Value<String?> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> spentAt = const Value.absent(),
                Value<bool> isFixed = const Value.absent(),
              }) => ExpensesCompanion(
                id: id,
                budgetId: budgetId,
                amountCents: amountCents,
                title: title,
                note: note,
                spentAt: spentAt,
                isFixed: isFixed,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int budgetId,
                required int amountCents,
                Value<String?> title = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<DateTime> spentAt = const Value.absent(),
                Value<bool> isFixed = const Value.absent(),
              }) => ExpensesCompanion.insert(
                id: id,
                budgetId: budgetId,
                amountCents: amountCents,
                title: title,
                note: note,
                spentAt: spentAt,
                isFixed: isFixed,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExpensesTable, Expense>(table),
                  $$ExpensesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({budgetId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (budgetId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.budgetId,
                        referencedTable: $$ExpensesTableReferences
                            ._budgetIdTable(db),
                        referencedColumn: $$ExpensesTableReferences
                            ._budgetIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ExpensesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExpensesTable,
      Expense,
      $$ExpensesTableFilterComposer,
      $$ExpensesTableOrderingComposer,
      $$ExpensesTableAnnotationComposer,
      $$ExpensesTableCreateCompanionBuilder,
      $$ExpensesTableUpdateCompanionBuilder,
      (Expense, $$ExpensesTableReferences),
      Expense,
      PrefetchHooks Function({bool budgetId})
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<int> bufferCents,
  Value<int?> selectedYearMonth,
  Value<int?> offeredYearMonth,
  Value<bool> showDebugBar,
  Value<int?> savingsGoalCents,
  Value<SavingsPeriod> savingsGoalPeriod,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<int> id,
  Value<int> bufferCents,
  Value<int?> selectedYearMonth,
  Value<int?> offeredYearMonth,
  Value<bool> showDebugBar,
  Value<int?> savingsGoalCents,
  Value<SavingsPeriod> savingsGoalPeriod,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bufferCents => $composableBuilder(
    column: $table.bufferCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get selectedYearMonth => $composableBuilder(
    column: $table.selectedYearMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get offeredYearMonth => $composableBuilder(
    column: $table.offeredYearMonth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get showDebugBar => $composableBuilder(
    column: $table.showDebugBar,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get savingsGoalCents => $composableBuilder(
    column: $table.savingsGoalCents,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SavingsPeriod, SavingsPeriod, String>
  get savingsGoalPeriod => $composableBuilder(
    column: $table.savingsGoalPeriod,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );
}

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bufferCents => $composableBuilder(
    column: $table.bufferCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get selectedYearMonth => $composableBuilder(
    column: $table.selectedYearMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get offeredYearMonth => $composableBuilder(
    column: $table.offeredYearMonth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get showDebugBar => $composableBuilder(
    column: $table.showDebugBar,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get savingsGoalCents => $composableBuilder(
    column: $table.savingsGoalCents,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get savingsGoalPeriod => $composableBuilder(
    column: $table.savingsGoalPeriod,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get bufferCents => $composableBuilder(
    column: $table.bufferCents,
    builder: (column) => column,
  );

  GeneratedColumn<int> get selectedYearMonth => $composableBuilder(
    column: $table.selectedYearMonth,
    builder: (column) => column,
  );

  GeneratedColumn<int> get offeredYearMonth => $composableBuilder(
    column: $table.offeredYearMonth,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get showDebugBar => $composableBuilder(
    column: $table.showDebugBar,
    builder: (column) => column,
  );

  GeneratedColumn<int> get savingsGoalCents => $composableBuilder(
    column: $table.savingsGoalCents,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<SavingsPeriod, String>
  get savingsGoalPeriod => $composableBuilder(
    column: $table.savingsGoalPeriod,
    builder: (column) => column,
  );
}

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bufferCents = const Value.absent(),
                Value<int?> selectedYearMonth = const Value.absent(),
                Value<int?> offeredYearMonth = const Value.absent(),
                Value<bool> showDebugBar = const Value.absent(),
                Value<int?> savingsGoalCents = const Value.absent(),
                Value<SavingsPeriod> savingsGoalPeriod = const Value.absent(),
              }) => SettingsCompanion(
                id: id,
                bufferCents: bufferCents,
                selectedYearMonth: selectedYearMonth,
                offeredYearMonth: offeredYearMonth,
                showDebugBar: showDebugBar,
                savingsGoalCents: savingsGoalCents,
                savingsGoalPeriod: savingsGoalPeriod,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> bufferCents = const Value.absent(),
                Value<int?> selectedYearMonth = const Value.absent(),
                Value<int?> offeredYearMonth = const Value.absent(),
                Value<bool> showDebugBar = const Value.absent(),
                Value<int?> savingsGoalCents = const Value.absent(),
                Value<SavingsPeriod> savingsGoalPeriod = const Value.absent(),
              }) => SettingsCompanion.insert(
                id: id,
                bufferCents: bufferCents,
                selectedYearMonth: selectedYearMonth,
                offeredYearMonth: offeredYearMonth,
                showDebugBar: showDebugBar,
                savingsGoalCents: savingsGoalCents,
                savingsGoalPeriod: savingsGoalPeriod,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MonthsTableTableManager get months =>
      $$MonthsTableTableManager(_db, _db.months);
  $$IncomesTableTableManager get incomes =>
      $$IncomesTableTableManager(_db, _db.incomes);
  $$BudgetsTableTableManager get budgets =>
      $$BudgetsTableTableManager(_db, _db.budgets);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db, _db.expenses);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
}
