import 'dart:async';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';

class DurudhCounterScreen extends StatefulWidget {
  const DurudhCounterScreen({super.key});

  @override
  State<DurudhCounterScreen> createState() => _DurudhCounterScreenState();
}

class _DurudhCounterScreenState extends State<DurudhCounterScreen>
    with SingleTickerProviderStateMixin {
  int _selectedMinutes = 1;
  int _count = 0;
  bool _isRunning = false;
  int _remainingSeconds = 0;
  Timer? _timer;
  late AnimationController _pulseController;

  final _durations = [1, 3, 5];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _start() {
    setState(() {
      _isRunning = true;
      _count = 0;
      _remainingSeconds = _selectedMinutes * 60;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        if (_remainingSeconds <= 0) {
          _stop();
        }
      });
    });
  }

  void _stop() {
    _timer?.cancel();
    setState(() => _isRunning = false);
  }

  void _tap() {
    if (!_isRunning) return;
    setState(() => _count++);
    _pulseController.reverse().then((_) => _pulseController.forward());
    context.read<TaskProvider>().incrementDurudh();
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _count = 0;
      _remainingSeconds = 0;
    });
  }

  String get _formattedTime {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);
    final progress = _isRunning && _selectedMinutes > 0
        ? 1.0 - (_remainingSeconds / (_selectedMinutes * 60))
        : 0.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Durudh Counter')),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // ─── Durudh Text ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isDark
                      ? null
                      : Border.all(
                          color: AppColors.secondary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontFamily: 'serif',
                        fontSize: 22,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'O Allah, send blessings upon Muhammad\nand upon the family of Muhammad',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Timer Selector ───────────────────────────
            if (!_isRunning) ...[
              Text(
                'Select Duration',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _durations.map((min) {
                  final isSelected = _selectedMinutes == min;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMinutes = min),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 70,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent
                              : isDark
                                  ? Colors.white10
                                  : AppColors.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accent
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$min',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black
                                    : theme.colorScheme.onSurface,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'min',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.black54
                                    : AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],

            // ─── Timer & Counter Display ──────────────────
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isRunning) ...[
                      // Timer display
                      Text(
                        _formattedTime,
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w300,
                          letterSpacing: 4,
                          color: _remainingSeconds <= 10
                              ? AppColors.muted
                              : null,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Progress bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 60),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: isDark
                                ? Colors.white10
                                : AppColors.secondary.withValues(alpha: 0.2),
                            valueColor: const AlwaysStoppedAnimation(
                                AppColors.accent),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // ─── Tap Circle ───────────────────────────
                    GestureDetector(
                      onTap: _isRunning ? _tap : _start,
                      child: ScaleTransition(
                        scale: _pulseController,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: _isRunning
                                  ? [
                                      AppColors.accent,
                                      AppColors.muted
                                    ]
                                  : [
                                      AppColors.darkText,
                                      AppColors.secondary
                                    ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isRunning ? '$_count' : 'START',
                                style: TextStyle(
                                  color: _isRunning
                                      ? Colors.black
                                      : Colors.white,
                                  fontSize: _isRunning ? 48 : 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (_isRunning)
                                Text(
                                  'TAP',
                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Bottom Buttons ───────────────────────────
            if (_isRunning || _count > 0)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isRunning)
                      _buildActionBtn(
                          Icons.stop_rounded, 'Stop', AppColors.muted, _stop),
                    if (_count > 0) ...[
                      const SizedBox(width: 20),
                      _buildActionBtn(Icons.refresh_rounded, 'Reset',
                          AppColors.muted, _reset),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
