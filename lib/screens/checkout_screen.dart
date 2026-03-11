import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/pantry_item.dart';
import '../theme/app_theme.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.cartItems});
  final List<CartItem> cartItems;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late List<CartItem> _items;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.cartItems);
  }

  /// Group items by pickup address for the route list.
  List<PickupStop> get _stops {
    final Map<String, PickupStop> grouped = {};
    for (final ci in _items) {
      final key = ci.pantryItem.pickupAddress;
      if (grouped.containsKey(key)) {
        grouped[key]!.items.add(ci);
      } else {
        grouped[key] = PickupStop(
          address: ci.pantryItem.pickupAddress,
          alias: ci.pantryItem.contributorAlias,
          instructions: ci.pantryItem.pickupInstructions,
          items: [ci],
        );
      }
    }
    return grouped.values.toList();
  }

  void _removeItem(CartItem ci) {
    setState(() => _items.remove(ci));
    if (_items.isEmpty) Navigator.pop(context);
  }

  void _confirm() {
    setState(() => _confirmed = true);
  }

  @override
  Widget build(BuildContext context) {
    final stops = _stops;

    return Scaffold(
      backgroundColor: AppTheme.cloudWhite,
      appBar: AppBar(
        title: Text(_confirmed ? 'Pickup route' : 'Your pantry'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _confirmed ? _confirmedView(stops) : _reviewView(stops),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Review view — before confirmation
  // ─────────────────────────────────────────────────────────────────
  Widget _reviewView(List<PickupStop> stops) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              // Summary header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.terracotta.withOpacity(0.08),
                      AppTheme.warmCream,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.terracotta.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.shopping_basket_rounded,
                          color: AppTheme.terracotta, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_items.length} item${_items.length == 1 ? '' : 's'}',
                            style:
                                Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            '${stops.length} pickup stop${stops.length == 1 ? '' : 's'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      AppTheme.deepBrown.withOpacity(0.6),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
                  .animate()
                  .fadeIn(duration: 400.ms),

              const SizedBox(height: 20),

              // Item list with swipe to remove
              ...List.generate(_items.length, (i) {
                final ci = _items[i];
                return Dismissible(
                  key: ValueKey(ci.pantryItem.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) => _removeItem(ci),
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        color: Colors.red.shade400),
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppTheme.paleOlive,
                              borderRadius: BorderRadius.circular(12),
                              image: ci.pantryItem.photoPath != null &&
                                      File(ci.pantryItem.photoPath!).existsSync()
                                  ? DecorationImage(
                                      image: FileImage(
                                          File(ci.pantryItem.photoPath!)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            alignment: Alignment.center,
                            child: ci.pantryItem.photoPath == null ||
                                    !File(ci.pantryItem.photoPath!).existsSync()
                                ? Text(ci.pantryItem.category.emoji,
                                    style: const TextStyle(fontSize: 22))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(ci.pantryItem.name,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                Text(
                                  '${ci.pantryItem.quantity} ${ci.pantryItem.unit}  ·  ${ci.pantryItem.contributorAlias}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppTheme.deepBrown
                                            .withOpacity(0.5),
                                      ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_left_rounded,
                              color:
                                  AppTheme.deepBrown.withOpacity(0.2)),
                          Text('swipe',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall),
                        ],
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: (i * 60).ms, duration: 300.ms),
                );
              }),
            ],
          ),
        ),

        // Checkout button
        Container(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
          ),
          decoration: BoxDecoration(
            color: AppTheme.cloudWhite,
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepBrown.withOpacity(0.06),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _confirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.terracotta,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
              ),
              child: const Text('Show pickup route',
                  style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Confirmed view — pickup route with addresses
  // ─────────────────────────────────────────────────────────────────
  Widget _confirmedView(List<PickupStop> stops) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      children: [
        // Success banner
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.seedGreen.withOpacity(0.12),
                AppTheme.paleOlive,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: AppTheme.seedGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                'Your pickup route is ready!',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${stops.length} stop${stops.length == 1 ? '' : 's'} · ${_items.length} item${_items.length == 1 ? '' : 's'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.deepBrown.withOpacity(0.6),
                    ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

        const SizedBox(height: 28),

        // Privacy reminder
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.honeyGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppTheme.honeyGold.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.shield_outlined,
                  size: 18, color: AppTheme.honeyGold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Addresses are only shown after you claim items. '
                  'Please be respectful of contributors\' privacy.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.deepBrown.withOpacity(0.7),
                        fontSize: 13,
                      ),
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 400.ms),

        const SizedBox(height: 24),

        // Pickup stops
        ...List.generate(stops.length, (i) {
          final stop = stops[i];
          return _PickupStopCard(
            stopNumber: i + 1,
            stop: stop,
            isLast: i == stops.length - 1,
          )
              .animate()
              .fadeIn(delay: (300 + i * 120).ms, duration: 400.ms)
              .slideY(begin: 0.08, end: 0);
        }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Pickup stop card with timeline connector
// ─────────────────────────────────────────────────────────────────────
class _PickupStopCard extends StatelessWidget {
  const _PickupStopCard({
    required this.stopNumber,
    required this.stop,
    required this.isLast,
  });

  final int stopNumber;
  final PickupStop stop;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppTheme.terracotta,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '$stopNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppTheme.terracotta.withOpacity(0.2),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.warmCream,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppTheme.softSage.withOpacity(0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address
                  Row(
                    children: [
                      const Icon(Icons.place_outlined,
                          size: 18, color: AppTheme.terracotta),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          stop.address,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: AppTheme.terracotta,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                    ],
                  ),

                  // Alias
                  Padding(
                    padding: const EdgeInsets.only(left: 26, top: 2),
                    child: Text(
                      'From ${stop.alias}',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.deepBrown.withOpacity(0.5),
                              ),
                    ),
                  ),

                  // Instructions
                  if (stop.instructions.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.cloudWhite,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16,
                              color:
                                  AppTheme.deepBrown.withOpacity(0.4)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              stop.instructions,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.deepBrown
                                        .withOpacity(0.6),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Items at this stop
                  const SizedBox(height: 12),
                  ...stop.items.map((ci) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Text(ci.pantryItem.category.emoji,
                                style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                '${ci.pantryItem.name} · ${ci.pantryItem.quantity} ${ci.pantryItem.unit}',
                                style:
                                    Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
