import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../models/pantry_item.dart';
import '../services/local_data_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import 'checkout_screen.dart';

class WantNotScreen extends StatefulWidget {
  const WantNotScreen({super.key});

  @override
  State<WantNotScreen> createState() => _WantNotScreenState();
}

class _WantNotScreenState extends State<WantNotScreen> {
  List<PantryItem> _available = [];
  final List<CartItem> _cart = [];
  bool _loading = true;
  String _neighbourhood = '';
  FoodCategory? _filterCategory;
  double _maxDistance = 5.0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final pos = await LocationService.getCurrentPosition();

      // Seed sample data on first run
      await LocalDataService.seedSampleData(pos.latitude, pos.longitude);

      final name = await LocationService.getNeighbourhoodName(
          pos.latitude, pos.longitude);

      final items = await LocalDataService.getSharedPantry(
        userLat: pos.latitude,
        userLng: pos.longitude,
        maxDistanceKm: _maxDistance,
      );

      if (mounted) {
        setState(() {
          _available = items;
          _neighbourhood = name;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  List<PantryItem> get _filtered {
    if (_filterCategory == null) return _available;
    return _available
        .where((i) => i.category == _filterCategory)
        .toList();
  }

  bool _isInCart(PantryItem item) =>
      _cart.any((c) => c.pantryItem.id == item.id);

  void _toggleCart(PantryItem item) {
    setState(() {
      if (_isInCart(item)) {
        _cart.removeWhere((c) => c.pantryItem.id == item.id);
      } else {
        _cart.add(CartItem(pantryItem: item));
      }
    });
  }

  void _goToCheckout() {
    if (_cart.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => CheckoutScreen(cartItems: List.from(_cart))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = _cart.length;

    return Scaffold(
      backgroundColor: AppTheme.cloudWhite,
      appBar: AppBar(
        title: const Text('Want Not'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (cartCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _goToCheckout,
                icon: Badge(
                  label: Text('$cartCount'),
                  backgroundColor: AppTheme.terracotta,
                  child: const Icon(Icons.shopping_basket_rounded),
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Location + distance header ──────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          size: 18, color: AppTheme.seedGreen),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _neighbourhood.isNotEmpty
                              ? _neighbourhood
                              : 'Your area',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppTheme.seedGreen),
                        ),
                      ),
                      // Distance filter chip
                      ActionChip(
                        avatar: const Icon(Icons.tune_rounded, size: 16),
                        label: Text('${_maxDistance.toStringAsFixed(0)} km'),
                        onPressed: _showDistanceSheet,
                      ),
                    ],
                  ),
                ),

                // ── Category filter ─────────────────────────────
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _filterChip(null, 'All'),
                      ...FoodCategory.values
                          .map((c) => _filterChip(c, c.emoji)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // ── Items list ──────────────────────────────────
                Expanded(
                  child: _filtered.isEmpty
                      ? _emptyState()
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) {
                            final item = _filtered[i];
                            return _ItemCard(
                              item: item,
                              inCart: _isInCart(item),
                              onToggle: () => _toggleCart(item),
                            )
                                .animate()
                                .fadeIn(
                                    delay: (i * 50).ms, duration: 300.ms)
                                .slideY(begin: 0.05, end: 0);
                          },
                        ),
                ),
              ],
            ),

      // ── Floating checkout bar ─────────────────────────────────
      bottomNavigationBar: cartCount > 0
          ? _CheckoutBar(
              count: cartCount,
              onCheckout: _goToCheckout,
            ).animate().slideY(begin: 1, end: 0, duration: 300.ms)
          : null,
    );
  }

  Widget _filterChip(FoodCategory? cat, String label) {
    final selected = _filterCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _filterCategory = cat),
        selectedColor: AppTheme.seedGreen,
        labelStyle: TextStyle(
          color: selected ? Colors.white : AppTheme.deepBrown,
          fontSize: cat == null ? 13 : 18,
        ),
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: AppTheme.softSage),
            const SizedBox(height: 16),
            Text('No items nearby',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Try increasing your search distance\nor check back later.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.deepBrown.withOpacity(0.5),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDistanceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        double temp = _maxDistance;
        return StatefulBuilder(
          builder: (ctx, setInner) => Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Search radius',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 16),
                Text('${temp.toStringAsFixed(1)} km',
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(color: AppTheme.seedGreen)),
                Slider(
                  value: temp,
                  min: 0.5,
                  max: 15,
                  divisions: 29,
                  activeColor: AppTheme.seedGreen,
                  onChanged: (v) => setInner(() => temp = v),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() => _maxDistance = temp);
                      _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.seedGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Item card
// ─────────────────────────────────────────────────────────────────────
class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.inCart,
    required this.onToggle,
  });

  final PantryItem item;
  final bool inCart;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: inCart ? AppTheme.paleOlive : AppTheme.warmCream,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onToggle,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Photo or emoji badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: inCart
                      ? AppTheme.seedGreen.withOpacity(0.15)
                      : AppTheme.cloudWhite,
                  borderRadius: BorderRadius.circular(14),
                  image: item.photoPath != null && File(item.photoPath!).existsSync()
                      ? DecorationImage(
                          image: FileImage(File(item.photoPath!)),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: item.photoPath == null || !File(item.photoPath!).existsSync()
                    ? Text(item.category.emoji,
                        style: const TextStyle(fontSize: 26))
                    : null,
              ),
              const SizedBox(width: 14),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 2),
                    Text(
                      '${item.quantity} ${item.unit}  ·  from ${item.contributorAlias}',
                      style:
                          Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.deepBrown.withOpacity(0.6),
                              ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (item.distanceLabel != null) ...[
                          Icon(Icons.near_me_outlined,
                              size: 13,
                              color: AppTheme.deepBrown.withOpacity(0.4)),
                          const SizedBox(width: 4),
                          Text(
                            item.distanceLabel!,
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color:
                                        AppTheme.deepBrown.withOpacity(0.5)),
                          ),
                        ],
                        if (item.expiresBy != null) ...[
                          const SizedBox(width: 10),
                          Icon(Icons.schedule_rounded,
                              size: 13, color: AppTheme.terracotta),
                          const SizedBox(width: 4),
                          Text(
                            'Exp ${DateFormat.MMMd().format(item.expiresBy!)}',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(color: AppTheme.terracotta),
                          ),
                        ],
                      ],
                    ),
                    if (item.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        item.notes,
                        style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: AppTheme.deepBrown.withOpacity(0.5),
                                ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Add/remove icon
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: inCart ? AppTheme.seedGreen : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: inCart
                        ? AppTheme.seedGreen
                        : AppTheme.deepBrown.withOpacity(0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  inCart ? Icons.check_rounded : Icons.add_rounded,
                  color: inCart
                      ? Colors.white
                      : AppTheme.deepBrown.withOpacity(0.4),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Checkout bar
// ─────────────────────────────────────────────────────────────────────
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({required this.count, required this.onCheckout});
  final int count;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            color: AppTheme.deepBrown.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onCheckout,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.terracotta,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 18),
          ),
          child: Text(
            'View my pantry · $count item${count == 1 ? '' : 's'}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
