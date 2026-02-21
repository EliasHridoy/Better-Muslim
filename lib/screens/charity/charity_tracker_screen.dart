import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';
import '../../models/charity_entry_model.dart';
import 'log_sadaka_screen.dart';

class CharityTrackerScreen extends StatefulWidget {
  const CharityTrackerScreen({super.key});

  @override
  State<CharityTrackerScreen> createState() => _CharityTrackerScreenState();
}

class _CharityTrackerScreenState extends State<CharityTrackerScreen> {
  bool _isMonthly = true;

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final entries = taskProvider.allCharityEntries;

    // Calculate totals
    double totalDonated = 0;
    final now = DateTime.now();

    if (_isMonthly) {
      for (var e in entries) {
        if (e.date.year == now.year && e.date.month == now.month) {
          totalDonated += e.amount;
        }
      }
    } else {
      for (var e in entries) {
        if (e.date.year == now.year) {
          totalDonated += e.amount;
        }
      }
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                  color: isDark ? Colors.white24 : Colors.black12, width: 1),
            ),
            child: const Icon(Icons.arrow_back_ios_new, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sadaka History',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isDark ? Colors.white24 : Colors.black12, width: 1),
              ),
              child: const Icon(Icons.add, size: 20),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LogSadakaScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // ─── Monthly/Yearly Toggle ────────────────
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isMonthly = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _isMonthly
                              ? AppColors.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Monthly',
                          style: TextStyle(
                            color: _isMonthly
                                ? Colors.white
                                : (isDark ? Colors.white54 : Colors.black54),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isMonthly = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: !_isMonthly
                              ? AppColors.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Yearly',
                          style: TextStyle(
                            color: !_isMonthly
                                ? Colors.white
                                : (isDark ? Colors.white54 : Colors.black54),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Total Donated Card w/ Bar Chart ──────
            _buildChartCard(context, totalDonated, entries, isDark),

            const SizedBox(height: 32),

            // ─── Recent Activities Header ─────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECENT ACTIVITIES',
                  style: theme.textTheme.labelMedium?.copyWith(
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white54 : AppColors.muted,
                  ),
                ),
                Text(
                  _isMonthly ? 'This Month' : 'This Year',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ─── Recent Activities List ───────────────
            if (entries.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Center(
                  child: Text(
                    'No sadaka logged yet',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ),
              )
            else
              ...entries.where((e) {
                if (_isMonthly) {
                  return e.date.year == now.year && e.date.month == now.month;
                }
                return e.date.year == now.year;
              }).map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildActivityTile(entry, isDark),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard(BuildContext context, double total,
      List<CharityEntry> entries, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TOTAL DONATED',
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 11,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat('#,##0').format(total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text(
                  'TAKA',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Miniature Custom Bar Chart representation
          SizedBox(
            height: 80,
            child: CustomPaint(
              painter: _BarChartPainter(
                entries: entries,
                isMonthly: _isMonthly,
                accentColor: AppColors.accent,
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _isMonthly ? 'W1' : 'JAN',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _isMonthly ? 'W2' : 'JUL',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _isMonthly ? 'W4' : 'DEC',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(CharityEntry entry, bool isDark) {
    IconData iconData;
    Color iconColor;

    // Assign icons based on predefined purposes
    switch (entry.purpose) {
      case 'Masjid Fund':
        iconData = Icons.mosque_rounded;
        iconColor = AppColors.accent;
        break;
      case 'Madarsha Support':
        iconData = Icons.school_rounded;
        iconColor = AppColors.accent;
        break;
      case 'Medical Aid':
        iconData = Icons.medical_services_rounded;
        iconColor = AppColors.accent;
        break;
      case 'Iftar Program':
        iconData = Icons.restaurant_rounded;
        iconColor = AppColors.accent;
        break;
      default:
        iconData = Icons.volunteer_activism_rounded;
        iconColor = AppColors.accent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(iconData, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.purpose ?? 'Donation',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('MMMM dd, yyyy').format(entry.date),
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                NumberFormat('#,##0.00').format(entry.amount),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'TAKA',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<CharityEntry> entries;
  final bool isMonthly;
  final Color accentColor;

  _BarChartPainter({
    required this.entries,
    required this.isMonthly,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime.now();

    // Group data
    final int numBars = isMonthly ? 4 : 12; // 4 weeks or 12 months
    final List<double> values = List.filled(numBars, 0.0);

    for (var e in entries) {
      if (isMonthly) {
        if (e.date.year == now.year && e.date.month == now.month) {
          int week = ((e.date.day - 1) / 7).floor();
          if (week > 3) week = 3;
          values[week] += e.amount;
        }
      } else {
        if (e.date.year == now.year) {
          values[e.date.month - 1] += e.amount;
        }
      }
    }

    double maxVal = 0;
    for (var v in values) {
      if (v > maxVal) maxVal = v;
    }
    if (maxVal == 0) maxVal = 1;

    final double barWidth = (size.width / numBars) * 0.6;
    final double spacing = (size.width - (barWidth * numBars)) / (numBars - 1);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < numBars; i++) {
      final double x = i * (barWidth + spacing);
      final double normalizedHeight = (values[i] / maxVal) * size.height;

      // If no data, show a tiny bar
      final double height = normalizedHeight < 4 ? 4 : normalizedHeight;

      // Color current month/week brighter
      bool isCurrent = false;
      if (isMonthly) {
        final currentWeek = ((now.day - 1) / 7).floor();
        isCurrent = i == (currentWeek > 3 ? 3 : currentWeek);
      } else {
        isCurrent = i == (now.month - 1);
      }

      paint.color = isCurrent
          ? accentColor
          : accentColor.withValues(alpha: 0.3);

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, size.height - height, barWidth, height),
        const Radius.circular(4),
      );

      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.isMonthly != isMonthly || oldDelegate.entries != entries;
}
