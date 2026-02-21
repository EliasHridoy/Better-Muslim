import re
import os

files_to_fix = [
    "lib/screens/durudh/durudh_counter_screen.dart",
    "lib/screens/charity/log_sadaka_screen.dart",
    "lib/screens/charity/charity_tracker_screen.dart",
    "lib/screens/splash/splash_screen.dart",
    "lib/screens/stats/activity_stats_screen.dart",
    "lib/screens/prayer/dua_page_screen.dart",
    "lib/screens/home/dashboard_screen.dart",
    "lib/screens/onboarding/onboarding_screen.dart",
    "lib/utils/tier_calculator.dart",
    "lib/screens/prayer/prayer_tracker_screen.dart"
]

def process_file(file_path):
    if not os.path.exists(file_path):
        return
    with open(file_path, 'r') as f:
        content = f.read()
    
    # Simple strategy: Replace Color(0xFF....) with our theme colors.
    # We will use mostly `AppColors.muted` or `AppColors.secondary` or `AppColors.darkText`.
    # But since some need dark mode support, let's replace custom colors in specific ways or generally with theme-aware ones.
    # To keep it safe, if `isDark` is accessible, use the ternary. However, `isDark` might not be in scope everywhere.
    # A generic approach is to just use standard Theme.of(context).colorScheme.primary where possible, but regex replacement is tricky.

    # Let's do some specific replaces for dashboard_screen:
    if "dashboard_screen.dart" in file_path:
        content = re.sub(r'Color\(0xFF00E676\)', r'AppColors.muted', content)
        content = content.replace('const Color(0xFF1B5E20).withValues(alpha: 0.5)', 'AppColors.secondary.withValues(alpha: 0.5)')
        content = content.replace('Color(0xFF1B5E20)', '(isDark ? AppColors.darkSurface : AppColors.secondary)')
        content = content.replace('Color(0xFF2E7D32)', 'AppColors.muted')
        content = content.replace('const Color(0xFF1B5E20)', 'AppColors.muted')
        content = content.replace('const Color(0xFFE8F5E9)', '(isDark ? AppColors.darkSurface : AppColors.lightBackground)')
        content = content.replace('const Color(0xFF2E7D32)', 'AppColors.muted')
        content = content.replace('const Color(0xFF81C784)', 'AppColors.muted')
        
        content = content.replace('const Color(0xFFE0F2F1)', '(isDark ? AppColors.darkSurface : AppColors.secondary.withValues(alpha: 0.2))')
        content = content.replace('const Color(0xFF00897B)', 'AppColors.muted')
        
        content = content.replace('const Color(0xFFE8EAF6)', '(isDark ? AppColors.darkSurface : AppColors.secondary.withValues(alpha: 0.2))')
        content = content.replace('const Color(0xFF3F51B5)', 'AppColors.muted')
        
        content = content.replace('const Color(0xFFFFF3E0)', '(isDark ? AppColors.darkSurface : AppColors.secondary.withValues(alpha: 0.2))')
        content = content.replace('const Color(0xFFE65100)', 'AppColors.muted')
        
        content = content.replace('const Color(0xFFEDE7F6)', '(isDark ? AppColors.darkSurface : AppColors.secondary.withValues(alpha: 0.2))')
        content = content.replace('const Color(0xFF6A1B9A)', 'AppColors.muted')

        content = content.replace('const Color(0xFF1E293B)', 'AppColors.darkText')
        content = content.replace('Colors.blue', 'AppColors.muted')
        content = content.replace('Colors.orange', 'AppColors.secondary')
        
    elif "charity_tracker_screen.dart" in file_path or "log_sadaka_screen.dart" in file_path:
        content = content.replace('const Color(0xFFF7F8FA)', 'AppColors.lightBackground')
        content = content.replace('const Color(0xFF9098B1)', 'AppColors.muted')
        content = content.replace('const Color(0xFF263C3C)', 'AppColors.darkText')
        content = content.replace('const Color(0xFF4B7BE5)', 'AppColors.muted')
        content = content.replace('const Color(0xFF9C4BE5)', 'AppColors.secondary')
        content = content.replace('const Color(0xFFE58D4B)', 'AppColors.darkText')
        content = content.replace('const Color(0xFFE8EBF2)', 'AppColors.secondary')
        content = content.replace('const Color(0xFFC4CBD8)', 'AppColors.secondary')
        content = content.replace('const Color(0xFF4B5563)', 'AppColors.muted')

    elif "splash_screen.dart" in file_path:
        content = content.replace('Color(0xFF0D1B2A)', 'AppColors.darkText')
        content = content.replace('Color(0xFF1B2D45)', 'AppColors.muted')
        content = content.replace('const Color(0xFF00E676)', 'AppColors.secondary')
        
    elif "activity_stats_screen.dart" in file_path:
        content = content.replace('const Color(0xFF6A1B9A)', 'AppColors.muted')
        content = content.replace('const Color(0xFF3F51B5)', 'AppColors.secondary')

    elif "dua_page_screen.dart" in file_path:
        content = content.replace('const Color(0xFF1565C0)', 'AppColors.secondary')
        content = content.replace('const Color(0xFF42A5F5)', 'AppColors.lightBackground')
        content = content.replace('const Color(0xFF1A237E)', 'AppColors.darkText')
        content = content.replace('const Color(0xFF5C6BC0)', 'AppColors.muted')
        
    elif "onboarding_screen.dart" in file_path:
        content = content.replace('Color(0xFF00E676)', 'AppColors.darkText')
        content = content.replace('Color(0xFF42A5F5)', 'AppColors.muted')
        content = content.replace('Color(0xFFFFD54F)', 'AppColors.secondary')
        content = content.replace('Color(0xFFE040FB)', 'AppColors.darkText')
        content = content.replace('Color(0xFF0D1B2A)', 'AppColors.darkBackground')
        
    elif "durudh_counter_screen.dart" in file_path:
        content = content.replace('const Color(0xFF00E676)', 'AppColors.muted')
        content = content.replace('const Color(0xFF1B5E20)', 'AppColors.darkText')
        content = content.replace('const Color(0xFF2E7D32)', 'AppColors.secondary')

    with open(file_path, 'w') as f:
        f.write(content)

for f in files_to_fix:
    process_file(f)
