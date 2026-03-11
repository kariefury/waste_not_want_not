import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_theme.dart';
import 'waste_not_screen.dart';
import 'want_not_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Background texture ──────────────────────────────────
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.cloudWhite, AppTheme.paleOlive],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── App title ─────────────────────────────────────
                Text(
                  'Waste Not\nWant Not',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .displayLarge
                      ?.copyWith(height: 1.1),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .slideY(begin: -0.2, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Share your pantry with neighbours',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.deepBrown.withOpacity(0.6),
                      ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms),

                const SizedBox(height: 12),

                // ── Privacy badge ─────────────────────────────────
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.seedGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.seedGreen.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 14, color: AppTheme.seedGreen),
                      const SizedBox(width: 6),
                      Text(
                        'Privacy-first · Local only',
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.seedGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 600.ms),

                const SizedBox(height: 48),

                // ── Split choice cards ────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // WASTE NOT card
                        Expanded(
                          child: _ChoiceCard(
                            title: 'Waste Not',
                            subtitle: 'Share extras from your pantry',
                            icon: Icons.volunteer_activism_rounded,
                            color: AppTheme.wasteNotColor,
                            secondaryColor: AppTheme.softSage,
                            onTap: () => Navigator.push(
                              context,
                              _pageRoute(const WasteNotScreen()),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 600.ms, duration: 500.ms)
                              .slideX(begin: -0.15, end: 0),
                        ),

                        const SizedBox(height: 16),

                        // WANT NOT card
                        Expanded(
                          child: _ChoiceCard(
                            title: 'Want Not',
                            subtitle: 'Browse what neighbours are sharing',
                            icon: Icons.shopping_basket_rounded,
                            color: AppTheme.wantNotColor,
                            secondaryColor: AppTheme.dustyRose,
                            onTap: () => Navigator.push(
                              context,
                              _pageRoute(const WantNotScreen()),
                            ),
                          )
                              .animate()
                              .fadeIn(delay: 750.ms, duration: 500.ms)
                              .slideX(begin: 0.15, end: 0),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PageRouteBuilder _pageRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (_, __, ___) => page,
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Choice card widget
// ─────────────────────────────────────────────────────────────────────
class _ChoiceCard extends StatefulWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.secondaryColor,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Color secondaryColor;
  final VoidCallback onTap;

  @override
  State<_ChoiceCard> createState() => _ChoiceCardState();
}

class _ChoiceCardState extends State<_ChoiceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.color,
                widget.color.withOpacity(0.85),
              ],
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative circle
              Positioned(
                right: -30,
                bottom: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Positioned(
                right: 20,
                top: 20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.06),
                  ),
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(widget.icon,
                          size: 32, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.title,
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle,
                      style:
                          Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withOpacity(0.85),
                              ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Get started',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 18, color: Colors.white),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
