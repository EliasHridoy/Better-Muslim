import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';
import '../../models/task_model.dart';
import '../durudh/durudh_counter_screen.dart';

class TasbihCounterScreen extends StatefulWidget {
  const TasbihCounterScreen({super.key});

  @override
  State<TasbihCounterScreen> createState() => _TasbihCounterScreenState();
}

class _TasbihCounterScreenState extends State<TasbihCounterScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final taskProvider = context.watch<TaskProvider>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tasbihTasks = taskProvider.tasbihTasks;

    if (tasbihTasks.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tasbih Counter')),
        body: const Center(child: Text('No tasbih phrases configured.')),
      );
    }

    final currentTask = tasbihTasks[_selectedIndex];
    final count = taskProvider.getTasbihCountToday(currentTask.id);
    final progress = (count / currentTask.targetCount).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasbih Counter'),
        actions: [
          IconButton(
            icon: const Icon(Icons.timer_outlined),
            tooltip: 'Durudh Counter',
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DurudhCounterScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => _showAddTasbihDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Phrase selector ──────────────────────────
          SizedBox(
            height: 50,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: tasbihTasks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = index == _selectedIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent
                          : isDark
                              ? AppColors.darkCard
                              : AppColors.lightBackground,
                      borderRadius: BorderRadius.circular(25),
                      border: isSelected
                          ? null
                          : Border.all(
                              color: isDark
                                  ? Colors.white10
                                  : AppColors.secondary.withValues(alpha: 0.3),
                            ),
                    ),
                    child: Center(
                      child: Text(
                        tasbihTasks[index].title,
                        style: TextStyle(
                          color: isSelected ? Colors.black : null,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ─── Counter display ──────────────────────────
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _pulseController.forward().then((_) {
                  _pulseController.reverse();
                });
                taskProvider.incrementTasbih(currentTask.id);
              },
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: child,
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Circular counter
                        SizedBox(
                          width: 220,
                          height: 220,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              CircularProgressIndicator(
                                value: progress,
                                strokeWidth: 8,
                                backgroundColor: isDark
                                    ? Colors.white10
                                    : AppColors.secondary.withValues(alpha: 0.2),
                                valueColor: AlwaysStoppedAnimation(
                                  count >= currentTask.targetCount
                                      ? AppColors.accent
                                      : AppColors.accent.withValues(alpha: 0.7),
                                ),
                                strokeCap: StrokeCap.round,
                              ),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '$count',
                                      style: theme.textTheme.headlineLarge
                                          ?.copyWith(
                                        fontSize: 56,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    Text(
                                      'of ${currentTask.targetCount}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          currentTask.title,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap anywhere to count',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.muted,
                          ),
                        ),
                        if (count >= currentTask.targetCount)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                '✅ Target reached!',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Reset button ─────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => taskProvider.resetTasbih(currentTask.id),
                icon: const Icon(Icons.refresh),
                label: const Text('Reset Counter'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : AppColors.secondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTasbihDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Dhikr'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Dhikr phrase (e.g. La ilaha illallah)',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                context
                    .read<TaskProvider>()
                    .addTask(controller.text.trim(), TaskCategory.tasbih);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
