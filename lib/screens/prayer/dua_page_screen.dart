import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/dua_service.dart';

/// Full-page dua screen shown after Fajr or Isha prayer.
/// Displays curated duas that user can mark complete for extra Sawab points.
class DuaPageScreen extends StatefulWidget {
  final String prayerName; // 'Fajr' or 'Isha'
  final VoidCallback? onPointsEarned;

  const DuaPageScreen({
    super.key,
    required this.prayerName,
    this.onPointsEarned,
  });

  @override
  State<DuaPageScreen> createState() => _DuaPageScreenState();
}

class _DuaPageScreenState extends State<DuaPageScreen> {
  late List<Dua> _duas;
  late Set<int> _completedIndices;
  int _pointsEarned = 0;

  @override
  void initState() {
    super.initState();
    _completedIndices = {};
    _duas = widget.prayerName.toLowerCase() == 'fajr'
        ? DuaService.fajrDuas
        : DuaService.ishaDuas;
  }

  void _toggleDua(int index) {
    setState(() {
      if (_completedIndices.contains(index)) {
        _completedIndices.remove(index);
        _pointsEarned -= 2;
      } else {
        _completedIndices.add(index);
        _pointsEarned += 2;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isFajr = widget.prayerName.toLowerCase() == 'fajr';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ─── App bar with gradient ──────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                isFajr ? 'Morning Duas' : 'Evening Duas',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isFajr
                        ? [AppColors.secondary, AppColors.lightBackground]
                        : [AppColors.darkText, AppColors.muted],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Icon(
                      isFajr ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                      color: Colors.white.withValues(alpha: 0.3),
                      size: 80,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Instructions ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AppColors.accent, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Read each dua and tap to mark as recited.\nEarn +2 Sawab for each dua!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ─── Dua list ───────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final dua = _duas[index];
                  final isCompleted = _completedIndices.contains(index);
                  return _buildDuaCard(
                      context, dua, index, isCompleted, isDark);
                },
                childCount: _duas.length,
              ),
            ),
          ),
        ],
      ),

      // ─── Bottom bar with points ─────────────────────────
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Points earned display
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.diamond, color: AppColors.accent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '+$_pointsEarned Sawab',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Done button
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  if (_pointsEarned > 0) {
                    widget.onPointsEarned?.call();
                  }
                  Navigator.pop(context, _pointsEarned);
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _completedIndices.length == _duas.length
                      ? 'All Done! ✨'
                      : 'Done (${_completedIndices.length}/${_duas.length})',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDuaCard(BuildContext context, Dua dua, int index,
      bool isCompleted, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => _toggleDua(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isCompleted
                ? AppColors.accent.withValues(alpha: 0.08)
                : isDark
                    ? AppColors.darkCard
                    : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? AppColors.accent.withValues(alpha: 0.5)
                  : isDark
                      ? Colors.white10
                      : AppColors.secondary.withValues(alpha: 0.3),
              width: isCompleted ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? AppColors.accent
                          : AppColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isCompleted ? Icons.check : Icons.circle_outlined,
                      color: isCompleted ? Colors.black : AppColors.muted,
                      size: 16,
                    ),
                  ),
                  const Spacer(),
                  if (isCompleted)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '+2 Sawab ✨',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Text(
                    '  ${dua.reference}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Arabic text
              Text(
                dua.arabic,
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontFamily: 'serif',
                      fontSize: 19,
                      height: 2.0,
                    ),
              ),
              const SizedBox(height: 14),

              // Divider
              Divider(
                color: isDark
                    ? Colors.white10
                    : AppColors.secondary.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 8),

              // Translation
              Text(
                dua.translation,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
