import os
import re

def process_file(path):
    if not os.path.exists(path): return
    with open(path, 'r') as f:
        content = f.read()

    # Fix const AppColors.something
    content = re.sub(r'const\s+AppColors\.', 'AppColors.', content)
    # Fix const (isDark ? ... )
    content = re.sub(r'const\s+\(isDark', '(isDark', content)
    # Fix const LinearGradient when it contains isDark
    content = content.replace('gradient: const LinearGradient(\n          colors: [(isDark', 'gradient: LinearGradient(\n          colors: [(isDark')

    # fix durudh_counter_screen.dart mutedAccent
    content = content.replace('AppColors.mutedAccent', 'AppColors.muted')

    # fix leaderboard_screen.dart AppColors.secondary[700] -> AppColors.secondary
    content = content.replace('AppColors.secondary[700]', 'AppColors.secondary')
    content = content.replace('AppColors.darkText[100]', 'AppColors.darkText')
    content = content.replace('AppColors.muted[100]', 'AppColors.muted')

    with open(path, 'w') as f:
        f.write(content)

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            process_file(os.path.join(root, file))
