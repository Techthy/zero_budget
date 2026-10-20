import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../data/database.dart';
import '../data/month_math.dart';
import '../money.dart';
import '../theme/budget_theme.dart';

// Mark colors from a colorblind-validated data-viz palette. Text never wears
// these; labels use the theme's text colors.
const _flexibleLight = Color(0xFFEB6834);
const _flexibleDark = Color(0xFFD95926);
const _sinkingFundLight = Color(0xFF1BAF7A);
const _sinkingFundDark = Color(0xFF199E70);
const _unassignedColor = Color(0xFF898781);
const _shortfallColor = Color(0xFFD03B3B);

const _shortfallIcon = Icons.warning_amber_rounded;

enum _Kind { source, fixed, flexible, sinkingFund, unassigned, shortfall }

/// What was spent from a budget, against what it has available.
typedef _Spending = ({int spentCents, int availableCents});

class _Node {
  const _Node(this.label, this.cents, this.kind, {this.spending});

  final String label;
  final int cents;
  final _Kind kind;

  /// Set for budgets when spending is shown.
  final _Spending? spending;

  bool get isOverspent => switch (spending) {
    (:final spentCents, :final availableCents) => spentCents > availableCents,
    null => false,
  };

  /// How much of the node is spent, from 0 to 1, or null when spending isn't
  /// shown.
  double? get spentFraction => switch (spending) {
    (:final spentCents, :final availableCents) when availableCents <= 0 =>
      spentCents > 0 ? 1.0 : 0.0,
    (:final spentCents, :final availableCents) =>
      (spentCents / availableCents).clamp(0.0, 1.0),
    null => null,
  };

  /// The amount shown beside the node: what's left of a budget while
  /// tracking, otherwise the node's amount.
  String get valueText => switch (spending) {
    (:final spentCents, :final availableCents) => formatLeftCents(
      availableCents - spentCents,
    ),
    null => formatCents(cents),
  };
}

/// A node picked by tapping, on the source (left) or target (right) side.
typedef _Focus = ({bool isSource, int index});

/// A sankey diagram of where the month's money comes from (incomes and
/// carryover) and which budgets it flows into, with a legend underneath.
///
/// With [spentByBudget], each budget fills up with what was spent from it.
/// Tapping a flow highlights it and shows its full name and numbers below.
class BudgetSankey extends StatefulWidget {
  const BudgetSankey({
    super.key,
    required this.incomes,
    required this.carryOverCents,
    required this.budgets,
    this.spentByBudget,
  });

  final List<Income> incomes;
  final int carryOverCents;
  final List<Budget> budgets;

  /// Cents spent per budget id, to track spending against the plan.
  final Map<int, int>? spentByBudget;

  @override
  State<BudgetSankey> createState() => _BudgetSankeyState();
}

class _BudgetSankeyState extends State<BudgetSankey> {
  _Focus? _focus;

  @override
  void didUpdateWidget(BudgetSankey oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Node indexes shift when the plan changes.
    _focus = null;
  }

  /// Both sides always add up to the same total: money that isn't covered
  /// shows up as a source, money that isn't assigned as a target.
  ({List<_Node> sources, List<_Node> targets}) _nodes() {
    final assignedCents = totalAssignedCents(widget.budgets);
    final incomeCents = widget.incomes.fold(0, (sum, i) => sum + i.amountCents);
    final leftCents = incomeCents + widget.carryOverCents - assignedCents;

    _Node budgetNode(Budget budget, _Kind kind) => _Node(
      budget.name,
      budget.amountCents,
      kind,
      spending: switch (widget.spentByBudget) {
        final spent? => (
          spentCents: spent[budget.id] ?? 0,
          availableCents: availableCents(budget),
        ),
        null => null,
      },
    );

    return (
      sources: [
        for (final income in widget.incomes)
          if (income.amountCents > 0)
            _Node(income.name, income.amountCents, _Kind.source),
        if (widget.carryOverCents > 0)
          _Node('Carried over', widget.carryOverCents, _Kind.source),
        if (leftCents < 0) _Node('Not covered', -leftCents, _Kind.shortfall),
      ],
      targets: [
        for (final budget in widget.budgets)
          if (budget.isFixed && budget.amountCents > 0)
            budgetNode(budget, _Kind.fixed),
        for (final budget in widget.budgets)
          if (!budget.isFixed &&
              !budget.isSinkingFund &&
              budget.amountCents > 0)
            budgetNode(budget, _Kind.flexible),
        for (final budget in widget.budgets)
          if (budget.isSinkingFund && budget.amountCents > 0)
            budgetNode(budget, _Kind.sinkingFund),
        if (leftCents > 0) _Node('Unassigned', leftCents, _Kind.unassigned),
        if (widget.carryOverCents < 0)
          _Node(
            'Overspent last month',
            -widget.carryOverCents,
            _Kind.shortfall,
          ),
      ],
    );
  }

  /// The node picked by tapping, if any.
  _Node? _focused(List<_Node> sources, List<_Node> targets) {
    final focus = _focus;
    if (focus == null) return null;
    final nodes = focus.isSource ? sources : targets;
    return focus.index < nodes.length ? nodes[focus.index] : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (:sources, :targets) = _nodes();
    if (sources.isEmpty || targets.isEmpty) return const SizedBox.shrink();

    final dark = theme.brightness == Brightness.dark;
    Color colorOf(_Kind kind) => switch (kind) {
      _Kind.source => theme.colorScheme.onSurfaceVariant,
      _Kind.fixed => theme.colorScheme.tertiary,
      _Kind.flexible => dark ? _flexibleDark : _flexibleLight,
      _Kind.sinkingFund => dark ? _sinkingFundDark : _sinkingFundLight,
      _Kind.unassigned => _unassignedColor,
      _Kind.shortfall => _shortfallColor,
    };
    final styles = (
      name: theme.textTheme.bodySmall!.copyWith(
        color: theme.colorScheme.onSurface,
      ),
      value: theme.textTheme.bodySmall!.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final kinds = {...sources, ...targets}.map((node) => node.kind).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final layout = _Layout(
              sources,
              targets,
              width: constraints.maxWidth,
              labelWidth: (node) => _Label(node, styles).measure(),
            );
            return Semantics(
              label: _describe(sources, targets),
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapUp: (details) {
                  final hit = layout.hitTest(details.localPosition);
                  setState(() => _focus = hit == _focus ? null : hit);
                },
                child: CustomPaint(
                  size: Size(constraints.maxWidth, layout.height),
                  painter: _SankeyPainter(
                    layout: layout,
                    focus: _focus,
                    colorOf: colorOf,
                    styles: styles,
                    headingStyle: theme.textTheme.bodySmall!.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        switch (_focused(sources, targets)) {
          final node? => _NodeDetails(
            node: node,
            color: colorOf(node.kind),
            totalCents: sources.fold(0, (sum, n) => sum + n.cents),
          ),
          null => Text(
            'Tap a flow to see its full name and numbers.',
            style: theme.textTheme.bodySmall!.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        },
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            if (kinds.contains(_Kind.fixed))
              _LegendEntry(color: colorOf(_Kind.fixed), label: 'Fixed'),
            if (kinds.contains(_Kind.flexible))
              _LegendEntry(color: colorOf(_Kind.flexible), label: 'Flexible'),
            if (kinds.contains(_Kind.sinkingFund))
              _LegendEntry(
                color: colorOf(_Kind.sinkingFund),
                label: 'Sinking fund',
              ),
            if (kinds.contains(_Kind.unassigned))
              _LegendEntry(
                color: colorOf(_Kind.unassigned),
                label: 'Unassigned',
              ),
            if (kinds.contains(_Kind.shortfall) ||
                targets.any((node) => node.isOverspent))
              const _LegendEntry(
                color: _shortfallColor,
                label: 'Shortfall',
                icon: _shortfallIcon,
              ),
            if (widget.spentByBudget != null) ...[
              _LegendEntry(
                color: theme.colorScheme.onSurfaceVariant,
                label: 'Spent',
              ),
              _LegendEntry(
                color: theme.colorScheme.onSurfaceVariant.withValues(
                  alpha: _SankeyPainter.unspentNodeAlpha,
                ),
                label: 'Left',
              ),
            ],
          ],
        ),
      ],
    );
  }
}

String _describe(List<_Node> sources, List<_Node> targets) {
  String list(List<_Node> nodes) => nodes
      .map(
        (node) =>
            '${node.label} ${node.valueText}'
            '${switch (node.kind) {
              _Kind.fixed => ' (fixed)',
              _Kind.sinkingFund => ' (sinking fund)',
              _ => '',
            }}',
      )
      .join(', ');
  return 'Where the money goes: from ${list(sources)}, '
      'to ${list(targets)}.';
}

/// The full name and numbers of a node picked by tapping, which the diagram
/// may have had to shorten.
class _NodeDetails extends StatelessWidget {
  const _NodeDetails({
    required this.node,
    required this.color,
    required this.totalCents,
  });

  final _Node node;
  final Color color;

  /// All the money flowing through the diagram.
  final int totalCents;

  @override
  Widget build(BuildContext context) {
    final c = context.budgetColors;
    final textTheme = Theme.of(context).textTheme;
    final kind = switch (node.kind) {
      _Kind.source => 'Money in',
      _Kind.fixed => 'Fixed budget',
      _Kind.flexible => 'Flexible budget',
      _Kind.sinkingFund => 'Sinking fund',
      _Kind.unassigned => 'Not assigned to a budget yet',
      _Kind.shortfall => 'Shortfall',
    };
    final share = totalCents > 0 ? (node.cents * 100 / totalCents).round() : 0;
    final muted = textTheme.bodySmall?.copyWith(color: c.inkMuted);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BudgetRadius.md,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(node.label, style: textTheme.titleMedium),
                  Text(
                    '$kind · ${formatCents(node.cents)} · $share% of the '
                    "month's money",
                    style: muted,
                  ),
                  if (node.spending case (:final spentCents, availableCents: _))
                    Text(
                      '${formatCents(spentCents)} spent · ${node.valueText}',
                      style: node.isOverspent
                          ? muted?.copyWith(color: c.danger)
                          : muted,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendEntry extends StatelessWidget {
  const _LegendEntry({required this.color, required this.label, this.icon});

  final Color color;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon case final icon?)
          Icon(icon, size: 16, color: color)
        else
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

typedef _LabelStyles = ({TextStyle name, TextStyle value});

/// The text beside a node: a warning icon for shortfalls, the name and the
/// amount. The name is shortened to fit, never the amount.
class _Label {
  _Label(_Node node, _LabelStyles styles)
    : _value = TextPainter(
        text: TextSpan(text: node.valueText, style: styles.value),
        textDirection: TextDirection.ltr,
      )..layout(),
      _name = TextPainter(
        text: TextSpan(text: node.label, style: styles.name),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      ),
      _icon = node.kind == _Kind.shortfall || node.isOverspent
          ? (TextPainter(
              text: TextSpan(
                text: String.fromCharCode(_shortfallIcon.codePoint),
                style: TextStyle(
                  fontFamily: _shortfallIcon.fontFamily,
                  package: _shortfallIcon.fontPackage,
                  fontSize: 14,
                  color: _shortfallColor,
                ),
              ),
              textDirection: TextDirection.ltr,
            )..layout())
          : null;

  static const _spacing = 4.0;

  final TextPainter _value;
  final TextPainter _name;
  final TextPainter? _icon;

  double get _iconWidth => _icon == null ? 0 : _icon.width + _spacing;

  /// The width needed to show the whole label, then disposes it.
  double measure() {
    _name.layout();
    final width = _iconWidth + _name.width + _spacing + _value.width;
    dispose();
    return width;
  }

  /// Paints the label vertically centered on [centerY], starting at [x] or,
  /// with [alignEnd], ending there. Disposes the label afterwards.
  void paint(
    Canvas canvas, {
    required double x,
    required double centerY,
    required double maxWidth,
    required bool alignEnd,
  }) {
    _name.layout(
      maxWidth: math.max(0, maxWidth - _iconWidth - _spacing - _value.width),
    );
    final width = _iconWidth + _name.width + _spacing + _value.width;
    var left = alignEnd ? x - width : x;
    if (_icon case final icon?) {
      icon.paint(canvas, Offset(left, centerY - icon.height / 2));
      left += _iconWidth;
    }
    _name.paint(canvas, Offset(left, centerY - _name.height / 2));
    left += _name.width + _spacing;
    _value.paint(canvas, Offset(left, centerY - _value.height / 2));
    dispose();
  }

  void dispose() {
    _value.dispose();
    _name.dispose();
    _icon?.dispose();
  }
}

/// Node and flow geometry, shared by painting and tap handling.
///
/// Three columns: sources on the left flow into one node holding the total in
/// the middle, which flows out to the targets on the right. Labels sit beside
/// their nodes, facing the middle.
class _Layout {
  _Layout(
    this.sources,
    this.targets, {
    required this.width,
    required double Function(_Node) labelWidth,
  }) {
    final rows = math.max(sources.length, targets.length);
    // Flows are proportional to their amounts, except that every node stays
    // tall enough for its label.
    flowHeight = math.max(180, targets.length * minNodeHeight);
    plotHeight = flowHeight + (rows - 1) * gap;
    height = top + plotHeight;

    // Put the middle node where both sides' labels fit, sharing any spare
    // room; if they can't both fit, split the width in proportion.
    double needed(List<_Node> nodes) =>
        nodeWidth +
        2 * labelPadding +
        nodes.map(labelWidth).fold(0.0, math.max);
    final leftNeeded = needed(sources);
    final rightNeeded = needed(targets);
    final spare = width - nodeWidth - leftNeeded - rightNeeded;
    final middleLeft = spare >= 0
        ? leftNeeded + spare / 2
        : (width - nodeWidth) * leftNeeded / (leftNeeded + rightNeeded);

    middle = Rect.fromLTWH(
      middleLeft,
      top + (plotHeight - flowHeight) / 2,
      nodeWidth,
      flowHeight,
    );
    sourceRects = _stack(sources, 0);
    targetRects = _stack(targets, width - nodeWidth);
    sourceBands = _bands(sourceRects);
    targetBands = _bands(targetRects);
  }

  static const nodeWidth = 8.0;
  static const minNodeHeight = 20.0;
  static const gap = 8.0;
  static const labelPadding = 6.0;

  /// Room above the plot for the column headings.
  static const top = 24.0;

  final List<_Node> sources;
  final List<_Node> targets;
  final double width;

  late final double flowHeight;
  late final double plotHeight;
  late final double height;
  late final Rect middle;
  late final List<Rect> sourceRects;
  late final List<Rect> targetRects;

  /// The vertical slice of the middle node each source flows into.
  late final List<(double, double)> sourceBands;

  /// The vertical slice of the middle node each target flows out of.
  late final List<(double, double)> targetBands;

  List<Rect> _stack(List<_Node> nodes, double x) {
    final heights = _fit([for (final node in nodes) node.cents], flowHeight);
    var y = top + (plotHeight - flowHeight - (nodes.length - 1) * gap) / 2;
    final rects = <Rect>[];
    for (final height in heights) {
      rects.add(Rect.fromLTWH(x, y, nodeWidth, height));
      y += height + gap;
    }
    return rects;
  }

  List<(double, double)> _bands(List<Rect> rects) {
    var y = middle.top;
    return [for (final rect in rects) (y, y += rect.height)];
  }

  /// Splits [total] proportionally to [values], giving each at least
  /// [minNodeHeight]. Assumes `values.length * minNodeHeight <= total`.
  static List<double> _fit(List<int> values, double total) {
    final heights = List<double?>.filled(values.length, null);
    while (true) {
      final free = [
        for (var i = 0; i < values.length; i++)
          if (heights[i] == null) i,
      ];
      final freeValue = free.fold(0, (sum, i) => sum + values[i]);
      final freeSpace =
          total - heights.whereType<double>().fold(0.0, (a, b) => a + b);
      final scale = freeSpace / freeValue;
      final tooSmall = free
          .where((i) => values[i] * scale < minNodeHeight)
          .toList();
      if (tooSmall.isEmpty) {
        for (final i in free) {
          heights[i] = values[i] * scale;
        }
        return heights.cast<double>();
      }
      for (final i in tooSmall) {
        heights[i] = minNodeHeight;
      }
    }
  }

  /// The node whose row contains [position], if any.
  _Focus? hitTest(Offset position) {
    final isSource = position.dx < middle.center.dx;
    final rects = isSource ? sourceRects : targetRects;
    for (var i = 0; i < rects.length; i++) {
      final rect = rects[i];
      if (position.dy >= rect.top - gap / 2 &&
          position.dy <= rect.bottom + gap / 2) {
        return (isSource: isSource, index: i);
      }
    }
    return null;
  }
}

class _SankeyPainter extends CustomPainter {
  _SankeyPainter({
    required this.layout,
    required this.focus,
    required this.colorOf,
    required this.styles,
    required this.headingStyle,
  });

  final _Layout layout;
  final _Focus? focus;
  final Color Function(_Kind) colorOf;
  final _LabelStyles styles;
  final TextStyle headingStyle;

  /// Half of the 2px surface gap between neighboring flows.
  static const _halfGap = 1.0;

  bool _isActive(bool isSource, int index) =>
      focus == null || focus == (isSource: isSource, index: index);

  @override
  void paint(Canvas canvas, Size size) {
    final l = layout;
    final middle = l.middle;

    for (var i = 0; i < l.sources.length; i++) {
      final rect = l.sourceRects[i];
      final (top, bottom) = l.sourceBands[i];
      final kind = l.sources[i].kind;
      _paintFlow(
        canvas,
        from: (rect.right, rect.top, rect.bottom),
        to: (middle.left, top, bottom),
        color: colorOf(kind),
        // Neutral income flows stay a light wash so the budgets lead.
        alpha: kind == _Kind.source ? 0.12 : 0.28,
        active: _isActive(true, i),
      );
    }
    for (var i = 0; i < l.targets.length; i++) {
      final rect = l.targetRects[i];
      final (top, bottom) = l.targetBands[i];
      final color = colorOf(l.targets[i].kind);
      final spent = l.targets[i].spentFraction;
      final active = _isActive(false, i);
      final from = (middle.right, top, bottom);
      final to = (rect.left, rect.top, rect.bottom);
      // While tracking, the whole budget is a pale wash with the spent part
      // laid over it.
      _paintFlow(
        canvas,
        from: from,
        to: to,
        color: color,
        alpha: spent == null ? 0.28 : 0.12,
        active: active,
      );
      if (spent != null && spent > 0) {
        _paintFlow(
          canvas,
          from: from,
          to: to,
          fraction: spent,
          color: color,
          alpha: 0.28,
          active: active,
        );
      }
      // The middle node is split into one segment per target.
      _paintNode(
        canvas,
        Rect.fromLTRB(middle.left, top, middle.right, bottom),
        color,
        spent: spent,
        active: active,
      );
    }

    for (var i = 0; i < l.sources.length; i++) {
      final rect = l.sourceRects[i];
      _paintNode(
        canvas,
        rect,
        colorOf(l.sources[i].kind),
        active: _isActive(true, i),
      );
      _Label(l.sources[i], styles).paint(
        canvas,
        x: rect.right + _Layout.labelPadding,
        centerY: rect.center.dy,
        maxWidth: middle.left - rect.right - 2 * _Layout.labelPadding,
        alignEnd: false,
      );
    }
    for (var i = 0; i < l.targets.length; i++) {
      final rect = l.targetRects[i];
      _paintNode(
        canvas,
        rect,
        colorOf(l.targets[i].kind),
        spent: l.targets[i].spentFraction,
        active: _isActive(false, i),
      );
      _Label(l.targets[i], styles).paint(
        canvas,
        x: rect.left - _Layout.labelPadding,
        centerY: rect.center.dy,
        maxWidth: rect.left - middle.right - 2 * _Layout.labelPadding,
        alignEnd: true,
      );
    }

    // Each heading sits over its column of nodes, on the outer edge.
    for (final (text, alignEnd) in [('Money in', false), ('Budgets', true)]) {
      final heading = TextPainter(
        text: TextSpan(text: text, style: headingStyle),
        textDirection: TextDirection.ltr,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: size.width / 2);
      heading.paint(
        canvas,
        Offset(
          alignEnd ? size.width - heading.width : 0,
          (_Layout.top - heading.height) / 2 - 2,
        ),
      );
      heading.dispose();
    }
  }

  /// Paints the flow between two node edges, given as x, top and bottom.
  ///
  /// With [fraction], only that top part of the flow is painted.
  void _paintFlow(
    Canvas canvas, {
    required (double, double, double) from,
    required (double, double, double) to,
    double fraction = 1,
    required Color color,
    required double alpha,
    required bool active,
  }) {
    final (x0, top0, bottom0) = _inset(from, fraction);
    final (x1, top1, bottom1) = _inset(to, fraction);
    final midX = (x0 + x1) / 2;
    final path = Path()
      ..moveTo(x0, top0)
      ..cubicTo(midX, top0, midX, top1, x1, top1)
      ..lineTo(x1, bottom1)
      ..cubicTo(midX, bottom1, midX, bottom0, x0, bottom0)
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = color.withValues(alpha: active ? alpha : alpha / 3),
    );
  }

  /// Leaves a gap to the neighboring flows, then keeps the top [fraction].
  static (double, double, double) _inset(
    (double, double, double) edge,
    double fraction,
  ) {
    final (x, top, bottom) = edge;
    final insetTop = top + _halfGap;
    final insetBottom = bottom - _halfGap;
    return (x, insetTop, insetTop + (insetBottom - insetTop) * fraction);
  }

  /// Opacity of the part of a node that isn't spent yet.
  static const unspentNodeAlpha = 0.3;

  /// Paints a node, filled from the top by the [spent] fraction when given.
  void _paintNode(
    Canvas canvas,
    Rect rect,
    Color color, {
    double? spent,
    required bool active,
  }) {
    void fill(double fraction, double alpha) {
      final (_, top, bottom) = _inset((0, rect.top, rect.bottom), fraction);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(rect.left, top, rect.right, bottom),
          const Radius.circular(2),
        ),
        Paint()..color = color.withValues(alpha: active ? alpha : alpha / 3),
      );
    }

    if (spent == null) {
      fill(1, 1);
      return;
    }
    fill(1, unspentNodeAlpha);
    if (spent > 0) fill(spent, 1);
  }

  @override
  bool shouldRepaint(_SankeyPainter oldDelegate) => true;
}
