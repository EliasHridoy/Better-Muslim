import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../config/theme.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/achievement_provider.dart';
import '../../models/achievement_model.dart';

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
  final PageController _pageController = PageController();
  int _currentDurudhIndex = 0;

  final _durations = [1, 3, 5];

  final List<Map<String, String>> _durudhTexts = [
    {
      'arabic': 'صَلَّىٰ ٱللَّٰهُ عَلَيْهِ وَسَلَّمَ',
      'pronunciation': 'Sal-lal-laa-hu ‘alay-hi wa-sal-lam',
      'meaning': 'May the peace and blessings of Allah be upon him',
    },
    {
      'arabic': 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ',
      'pronunciation': 'Al-laa-hum-ma sal-li ‘a-laa Mu-ham-mad',
      'meaning': 'O Allah, send blessings upon Muhammad.',
    },
    {
      'arabic': 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ وَعَلَىٰ آلِ مُحَمَّدٍ',
      'pronunciation': 'Al-laa-hum-ma sal-li ‘a-laa Mu-ham-mad-iw wa-‘a-laa aa-li Mu-ham-mad',
      'meaning': 'O Allah, send blessings upon Muhammad and upon the family of Muhammad',
    },
    {
      'arabic': 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَىٰ نَبِيِّنَا مُحَمَّدٍ',
      'pronunciation': 'Al-laa-hum-ma sal-li wa-sal-lim ‘a-laa na-biy-yi-naa Mu-ham-mad',
      'meaning': 'O Allah, send Your blessings and peace upon our Prophet Muhammad.',
    },
    {
      'arabic': 'صَلَّىٰ ٱللّٰهُ عَلَىٰ النَّبِيِّ مُحَمَّدٍ',
      'pronunciation': 'Sal-lal-laa-hu ‘a-lan-na-biy-yi Mu-ham-mad',
      'meaning': 'Allah\'s blessings be upon the Prophet Muhammad.',
    },
  ];

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
    _pageController.dispose();
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

  void _spawnFloatingText(Offset globalPosition, String text, Color color) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;
    final random = Random();

    // Start at tapping position
    // final startX = globalPosition.dx - 60 + (random.nextDouble() - 0.5) * 40;
    // final startY = globalPosition.dy - 80 + (random.nextDouble() - 0.5) * 20;
    final startX = globalPosition.dx - 20;
    final startY = globalPosition.dy - 50;

    // Random direction where it floats
    final floatDistanceX = (random.nextDouble() - 0.5) * 120.0;
    final floatDistanceY = -150.0 - random.nextDouble() * 100.0;

    // Slight random rotation for style
    final rotation = (random.nextDouble() - 0.5) * 0.5;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          left: startX,
          top: startY,
          child: Material(
            color: Colors.transparent,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 5000),
              curve: Curves.easeOutCubic,
              onEnd: () {
                overlayEntry.remove();
                overlayEntry.dispose();
              },
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(floatDistanceX * value, floatDistanceY * value),
                  child: Transform.rotate(
                    angle: rotation * value,
                    child: Opacity(
                      // Fade in fast, then fade out
                      opacity: value < 0.1 ? (value * 10) : (1.0 - ((value - 0.1) / 0.9)),
                      child: child!,
                    ),
                  ),
                );
              },
              child: Text(
                text,
                style: TextStyle(
                  color: color,
                  fontSize: 12 + random.nextDouble() * 8, // slight size variation
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);
  }

  void _tap(Offset globalPosition) async {
    if (!_isRunning) return;
    setState(() => _count++);
    _pulseController.reverse().then((_) => _pulseController.forward());

    _spawnFloatingText(globalPosition, '🍂 -10 Sins', Colors.redAccent.shade100);
    _spawnFloatingText(globalPosition, '🤍 +10 Bless', Colors.greenAccent.shade100);
    _spawnFloatingText(globalPosition, '👑 +10 Ranks', Colors.amberAccent);

    final provider = context.read<TaskProvider>();
    provider.incrementDurudh();

    // Check achievements
    final achievementProvider = context.read<AchievementProvider>();
    final points = await achievementProvider.checkAndUnlock(
      context,
      AchievementCategory.durood,
    );
    if (points > 0 && mounted) {
      provider.addBonusPoints(points);
    }
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
                padding: const EdgeInsets.symmetric(vertical: 20),
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
                    SizedBox(
                      height: 170, // Fixed height for slider
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentDurudhIndex = index;
                          });
                        },
                        itemCount: _durudhTexts.length,
                        itemBuilder: (context, index) {
                          final text = _durudhTexts[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  text['arabic']!,
                                  textAlign: TextAlign.center,
                                  textDirection: TextDirection.rtl,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontFamily: 'serif',
                                    fontSize: 22,
                                    height: 1.5,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  text['pronunciation']!,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurface,
                                    fontWeight: FontWeight.w500,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  text['meaning']!,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.muted,
                                    fontStyle: FontStyle.italic,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Indication dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _durudhTexts.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: _currentDurudhIndex == index ? 20 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _currentDurudhIndex == index
                                ? AppColors.accent
                                : (isDark ? Colors.white24 : Colors.black12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Stats Cards ──────────────────────────────
            Consumer<TaskProvider>(
              builder: (context, provider, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Today',
                          provider.durudhCountToday,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatCard(
                          context,
                          'Lifetime',
                          provider.totalDurudhLifetimeCount,
                          isDark,
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                      onTapDown: _isRunning ? (details) => _tap(details.globalPosition) : null,
                      onTap: _isRunning ? () {} : _start,
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

  Widget _buildStatCard(BuildContext context, String title, int count, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDark
            ? null
            : Border.all(color: AppColors.secondary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}
