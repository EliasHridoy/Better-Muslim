import os

def cleanse_file(path):
    with open(path, 'r') as f:
        content = f.read()

    new_content = content.replace('Colors.orange', 'AppColors.secondary')
    new_content = new_content.replace('Colors.purple', 'AppColors.muted')
    new_content = new_content.replace('Colors.blue', 'AppColors.darkText')
    new_content = new_content.replace('Colors.green', 'AppColors.secondary')
    new_content = new_content.replace('Colors.red', 'AppColors.muted') # Or keep error red if needed, but the user asked for these 4 colors.

    if content != new_content:
        with open(path, 'w') as f:
            f.write(new_content)
        print(f"Updated {path}")

for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            cleanse_file(os.path.join(root, file))
