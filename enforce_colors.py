import os
import re

files_to_fix = [
    "lib/screens/charity/charity_tracker_screen.dart",
    "lib/screens/charity/log_sadaka_screen.dart",
    "lib/screens/home/dashboard_screen.dart",
    "lib/screens/durudh/durudh_counter_screen.dart",
    "lib/screens/prayer/dua_page_screen.dart",
    "lib/screens/prayer/prayer_tracker_screen.dart",
    "lib/screens/stats/activity_stats_screen.dart",
    "lib/screens/leaderboard/leaderboard_screen.dart",
    "lib/screens/splash/splash_screen.dart",
    "lib/widgets/bottom_nav_shell.dart"
]

def process_file(file_path):
    if not os.path.exists(file_path):
        return
    with open(file_path, 'r') as f:
        content = f.read()
    
    # We want to replace any stray colors with the 4 allowed colors.
    # AppColors.darkText -> Colors.white where it's meant to be text in dark mode.
    # Actually, let's just make sure we use AppColors properties correctly.
    # Let's replace any `AppColors.darkText` with `Colors.white` if it's used as text color in dark mode, or keep it if it's card background.
    
    if "charity_tracker_screen.dart" in file_path:
        content = content.replace("AppColors.darkText, // Dark greenish", "AppColors.darkCard,")
        content = content.replace("AppColors.muted, //", "AppColors.accent, //")
        content = content.replace("AppColors.secondary, //", "AppColors.accent, //")
        content = content.replace("AppColors.darkText, //", "AppColors.accent, //")
        
        content = re.sub(r'iconColor = AppColors\.muted;', 'iconColor = AppColors.accent;', content)
        content = re.sub(r'iconColor = AppColors\.secondary;', 'iconColor = AppColors.accent;', content)
        content = re.sub(r'iconColor = AppColors\.darkText;', 'iconColor = AppColors.accent;', content)

    if "log_sadaka_screen.dart" in file_path:
        pass # Will check manually if needed

    with open(file_path, 'w') as f:
        f.write(content)

for f in files_to_fix:
    process_file(f)

