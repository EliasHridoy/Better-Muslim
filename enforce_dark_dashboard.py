import os
import re

dashboard_path = "lib/screens/home/dashboard_screen.dart"

with open(dashboard_path, "r") as f:
    content = f.read()

# Replace any background that was made invisible
# iconBgColor: (isDark ? AppColors.darkSurface : ... ) -> AppColors.darkBackground
content = re.sub(r'iconBgColor:\s*\(isDark \? AppColors\.darkSurface : \w+\.[\w\(\)\.\:\s]+\),', 'iconBgColor: AppColors.darkBackground,', content)
content = re.sub(r'iconBgColor:\s*\(isDark \? AppColors\.darkSurface : \w+\.\w+\),', 'iconBgColor: AppColors.darkBackground,', content)

content = content.replace("AppColors.muted", "AppColors.accent") 
# wait, actually let's use search and replace for specific broken parts.
content = content.replace("AppColors.secondary.withValues(alpha: 0.5)", "Colors.white10")
content = content.replace("(isDark ? AppColors.darkSurface : AppColors.lightBackground)", "AppColors.darkBackground")

content = content.replace("color: isDark ? AppColors.darkCard : Colors.white", "color: AppColors.darkCard")

# The stat cards
content = content.replace("iconColor: AppColors.secondary,", "iconColor: AppColors.accent,")

with open(dashboard_path, "w") as f:
    f.write(content)

