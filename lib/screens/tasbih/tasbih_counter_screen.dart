import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/task_provider.dart';
import '../../models/task_model.dart';


class TasbihCounterScreen extends StatefulWidget {
  const TasbihCounterScreen({super.key});

  @override
  State<TasbihCounterScreen> createState() => _TasbihCounterScreenState();
}

class _TasbihCounterScreenState extends State<TasbihCounterScreen>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _breatheController;
  late Animation<double> _breatheAnimation;

  bool _isSoundEnabled = true;
  bool _isVibrationEnabled = true;

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

    _breatheController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
    _breatheAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breatheController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  // Uses default Stitch dark color for dark mode
  Color _getBgColor(bool isDark) => isDark ? const Color(0xFF2B2E33) : AppColors.lightBackground;
  Color _getGlassColor(bool isDark) => isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.secondary.withValues(alpha: 0.05);
  Color _getGlassBorder(bool isDark) => isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.secondary.withValues(alpha: 0.1);

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

    // Safely clamp selected index if tasks were removed
    if (_selectedIndex >= tasbihTasks.length) {
      _selectedIndex = 0;
    }

    final currentTask = tasbihTasks[_selectedIndex];
    final count = taskProvider.getTasbihCountToday(currentTask.id);
    final progress = (count / currentTask.targetCount).clamp(0.0, 1.0);
    final totalCountToday = taskProvider.totalTasbihCountToday;

    return Scaffold(
      backgroundColor: _getBgColor(isDark),
      body: SafeArea(
        child: Column(
          children: [
            // ─── Custom Header ──────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHeaderButton(
                        icon: Icons.arrow_back_ios_new,
                        isDark: isDark,
                        onTap: () => Navigator.pop(context),
                      ),
                      _buildHeaderButton(
                        icon: Icons.add,
                        isDark: isDark,
                        onTap: () => _showAddTasbihDialog(context),
                      ),
                    ],
                  ),
                  Text(
                    'Tasbih Counter',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white.withValues(alpha: 0.9) : AppColors.darkText,
                    ),
                  ),
                ],
              ),
            ),

            // ─── Current Dhikr Dropdown ─────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GestureDetector(
                onTap: () => _showDhikrSelector(context, tasbihTasks, isDark),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _getGlassColor(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _getGlassBorder(isDark)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CURRENT DHIKR',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.accent.withValues(alpha: 0.8),
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              currentTask.title,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : AppColors.darkText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        height: 32,
                        width: 1,
                        color: isDark ? Colors.white.withValues(alpha: 0.2) : AppColors.secondary.withValues(alpha: 0.2),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppColors.accent.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.expand_more,
                          color: AppColors.accent,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ─── Progress Bar ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 0),
              child: Row(
                children: [
                  Text(
                    'TARGET: ${currentTask.targetCount}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.secondary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ─── Interactive glowing counter ────────────
            Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () {
                    if (_isVibrationEnabled) {
                      HapticFeedback.lightImpact();
                    }
                    if (_isSoundEnabled) {
                      // Optionally play a tick sound if added later
                    }
                    _pulseController.forward().then((_) {
                      if (mounted) _pulseController.reverse();
                    });
                    taskProvider.incrementTasbih(currentTask.id);
                  },
                  child: AnimatedBuilder(
                    animation: Listenable.merge([_pulseAnimation, _breatheAnimation]),
                    builder: (context, child) {
                      final scale = _pulseAnimation.value;
                      final breathe = _breatheAnimation.value;
                      final overallScale = scale * breathe;

                      return Transform.scale(
                        scale: overallScale,
                        child: Container(
                          width: 260,
                          height: 260,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getBgColor(isDark),
                            border: Border.all(
                              color: isDark ? Colors.white.withValues(alpha: 0.1) : AppColors.accent.withValues(alpha: 0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: isDark ? 0.3 : 0.2),
                                blurRadius: 40,
                                spreadRadius: isDark ? 5 : 2,
                              ),
                              BoxShadow(
                                color: _getBgColor(isDark),
                                blurRadius: 20,
                                spreadRadius: -10,
                                blurStyle: BlurStyle.inner,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$count',
                                  style: TextStyle(
                                    fontSize: 80,
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                    color: isDark ? Colors.white : AppColors.darkText,
                                    shadows: [
                                      if (isDark)
                                        BoxShadow(
                                          color: Colors.white.withValues(alpha: 0.4),
                                          blurRadius: 15,
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'TAP TO COUNT',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.accent.withValues(alpha: 0.7),
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // ─── Action Buttons ─────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      icon: Icons.refresh,
                      isDark: isDark,
                      onTap: () => taskProvider.resetTasbih(currentTask.id),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: _isSoundEnabled ? Icons.volume_up : Icons.volume_off,
                      isDark: isDark,
                      isActive: _isSoundEnabled,
                      onTap: () {
                        setState(() {
                          _isSoundEnabled = !_isSoundEnabled;
                        });
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      icon: _isVibrationEnabled ? Icons.vibration : Icons.mobile_off,
                      isDark: isDark,
                      isActive: _isVibrationEnabled,
                      onTap: () {
                        setState(() {
                          _isVibrationEnabled = !_isVibrationEnabled;
                        });
                        if (_isVibrationEnabled) HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ─── Statistics ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      title: 'SESSION',
                      value: count.toString(),
                      icon: Icons.dark_mode,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStatCard(
                      title: 'TOTAL',
                      value: totalCountToday.toString(),
                      icon: Icons.all_inclusive,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton({required IconData icon, required bool isDark, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getGlassColor(isDark),
          shape: BoxShape.circle,
          border: Border.all(color: _getGlassBorder(isDark)),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.white : AppColors.darkText,
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required bool isDark,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: _getGlassColor(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _getGlassBorder(isDark)),
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.accent : (isDark ? Colors.white.withValues(alpha: 0.7) : AppColors.darkText.withValues(alpha: 0.7)),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getGlassColor(isDark),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getGlassBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                  letterSpacing: 1.0,
                ),
              ),
              Icon(
                icon,
                size: 16,
                color: AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xFFF5F6F7) : AppColors.darkText,
            ),
          ),
        ],
      ),
    );
  }

  void _showDhikrSelector(BuildContext context, List<TaskModel> tasks, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _getBgColor(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : AppColors.secondary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Select Dhikr',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.darkText,
                  ),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isSelected = _selectedIndex == index;
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.check_circle : Icons.circle_outlined,
                        color: isSelected ? AppColors.accent : AppColors.secondary,
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isDark ? Colors.white : AppColors.darkText,
                        ),
                      ),
                      trailing: Text(
                        'Target: ${task.targetCount}',
                        style: const TextStyle(
                          color: AppColors.secondary,
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        setState(() {
                          _selectedIndex = index;
                        });
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _showAddTasbihDialog(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add New Dhikr'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: const BorderSide(color: AppColors.accent),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddTasbihDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF2B2E33)
            : AppColors.lightBackground,
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

                // Switch to the newly added task
                final provider = context.read<TaskProvider>();
                setState(() {
                  _selectedIndex = provider.tasbihTasks.length - 1;
                });
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
