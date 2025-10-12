from PIL import Image, ImageDraw, ImageFont
import math

# Create a 1024x500 feature graphic
width = 1024
height = 500
image = Image.new('RGB', (width, height), color='#4CAF50')
draw = ImageDraw.Draw(image)

# Simple gradient background (green to lighter green)
for y in range(height):
    progress = y / height
    r = int(76 + (120 - 76) * progress)
    g = int(175 + (200 - 175) * progress)
    b = int(80 + (120 - 80) * progress)
    draw.rectangle([0, y, width, y + 1], fill=(r, g, b))

# Load font
try:
    title_font = ImageFont.truetype("/Users/takahashi-sh/Project/dekita_calendar/assets/NotoSansJP.ttf", 80)
    subtitle_font = ImageFont.truetype("/Users/takahashi-sh/Project/dekita_calendar/assets/NotoSansJP.ttf", 36)
    simple_font = ImageFont.truetype("/Users/takahashi-sh/Project/dekita_calendar/assets/NotoSansJP.ttf", 28)
    calendar_font = ImageFont.truetype("/Users/takahashi-sh/Project/dekita_calendar/assets/NotoSansJP.ttf", 24)
    small_font = ImageFont.truetype("/Users/takahashi-sh/Project/dekita_calendar/assets/NotoSansJP.ttf", 18)
    print("Using Noto Sans JP font")
except Exception as e:
    print(f"Font loading error: {e}")
    title_font = ImageFont.load_default()
    subtitle_font = ImageFont.load_default()
    simple_font = ImageFont.load_default()
    calendar_font = ImageFont.load_default()
    small_font = ImageFont.load_default()

# Draw calendar widget on the left
cal_x = 50
cal_y = 60
cal_width = 280
cal_height = 320
cal_margin = 20

# Calendar background (white rounded rectangle)
draw.rounded_rectangle([cal_x, cal_y, cal_x + cal_width, cal_y + cal_height],
                       radius=15, fill='white', outline='#2E7D32', width=3)

# Calendar header (month)
header_height = 50
draw.rounded_rectangle([cal_x, cal_y, cal_x + cal_width, cal_y + header_height],
                       radius=15, fill='#FF5252')
draw.rectangle([cal_x, cal_y + 35, cal_x + cal_width, cal_y + header_height],
               fill='#FF5252')

# Month text
month_text = "10月"
month_bbox = draw.textbbox((0, 0), month_text, font=calendar_font)
month_width = month_bbox[2] - month_bbox[0]
draw.text((cal_x + (cal_width - month_width) // 2, cal_y + 12),
          month_text, fill='white', font=calendar_font)

# Draw day labels (Sun-Sat)
days = ['日', '月', '火', '水', '木', '金', '土']
day_y = cal_y + header_height + 15
cell_width = (cal_width - 2 * cal_margin) // 7

for i, day in enumerate(days):
    x = cal_x + cal_margin + i * cell_width
    color = '#D32F2F' if i == 0 else '#1976D2' if i == 6 else '#666666'
    draw.text((x + 5, day_y), day, fill=color, font=small_font)

# Draw calendar grid with some dates marked as completed
grid_start_y = day_y + 30
cell_height = 35

# Sample calendar data (week view with completed days)
weeks = [
    [1, 2, 3, 4, 5, 6, 7],
    [8, 9, 10, 11, 12, 13, 14],
    [15, 16, 17, 18, 19, 20, 21],
    [22, 23, 24, 25, 26, 27, 28],
]

# Completed days (marked with circles)
completed_days = [1, 2, 3, 5, 8, 9, 10, 12, 15, 16, 17, 19, 22, 23, 24]

for week_idx, week in enumerate(weeks):
    for day_idx, day in enumerate(week):
        x = cal_x + cal_margin + day_idx * cell_width
        y = grid_start_y + week_idx * cell_height

        # Draw date number
        draw.text((x + 4, y + 2), str(day), fill='#333333', font=small_font)

        # If completed, draw small marker dots below the date
        if day in completed_days:
            # Draw 2-3 small dots below the date to represent completed habits
            dot_y = y + 22
            dot_radius = 2.5
            # Draw 3 small green dots
            for i in range(3):
                dot_x = x + 8 + i * 6
                draw.ellipse([dot_x - dot_radius, dot_y - dot_radius,
                             dot_x + dot_radius, dot_y + dot_radius],
                            fill='#4CAF50')

# Draw badges below calendar
badge_y = cal_y + cal_height + 20
badge_size = 30
badge_spacing = 42

badges = [
    ('#CD7F32', 'Bronze'),      # Bronze
    ('#C0C0C0', 'Silver'),      # Silver
    ('#FFD700', 'Gold'),        # Gold
    ('#E5E4E2', 'Platinum'),    # Platinum
    ('#B9F2FF', 'Diamond'),     # Diamond (light blue)
]

badge_start_x = cal_x + 20
for i, (color, name) in enumerate(badges):
    x = badge_start_x + i * badge_spacing
    # Draw badge circle
    draw.ellipse([x - badge_size//2, badge_y - badge_size//2,
                  x + badge_size//2, badge_y + badge_size//2],
                fill=color, outline='#FFFFFF', width=2)

# Text content on the right
text_x = 350
text_y_title = 50
text_y_subtitle = 155
text_y_simple = 215
text_y_feature1 = 275
text_y_feature2 = 335

# Title - draw multiple times for bold effect
title = "できたカレンダー"
# Draw text multiple times with slight offsets to make it bold
for dx in range(-2, 3):
    for dy in range(-2, 3):
        if dx != 0 or dy != 0:
            draw.text((text_x + dx, text_y_title + dy), title, fill='white', font=title_font)
draw.text((text_x, text_y_title), title, fill='white', font=title_font)

# Subtitle - also make bold
subtitle = "習慣を続けて、成長を実感"
for dx in range(-1, 2):
    for dy in range(-1, 2):
        if dx != 0 or dy != 0:
            draw.text((text_x + dx, text_y_subtitle + dy), subtitle, fill='white', font=subtitle_font)
draw.text((text_x, text_y_subtitle), subtitle, fill='white', font=subtitle_font)

# Simple description - emphasize simplicity
simple_desc = "複雑な機能なし、シンプルに習慣管理"
for dx in range(-1, 2):
    for dy in range(-1, 2):
        if dx != 0 or dy != 0:
            draw.text((text_x + dx, text_y_simple + dy), simple_desc, fill='white', font=simple_font)
draw.text((text_x, text_y_simple), simple_desc, fill='white', font=simple_font)

# Feature bullets
feature1 = "✓ カレンダーで一目で進捗確認"
feature2 = "✓ 統計情報で達成状況を可視化"

# Bold features too
for dx in range(-1, 2):
    for dy in range(-1, 2):
        if dx != 0 or dy != 0:
            draw.text((text_x + dx, text_y_feature1 + dy), feature1, fill='white', font=subtitle_font)
draw.text((text_x, text_y_feature1), feature1, fill='white', font=subtitle_font)

for dx in range(-1, 2):
    for dy in range(-1, 2):
        if dx != 0 or dy != 0:
            draw.text((text_x + dx, text_y_feature2 + dy), feature2, fill='white', font=subtitle_font)
draw.text((text_x, text_y_feature2), feature2, fill='white', font=subtitle_font)

# Save the image
image.save('/Users/takahashi-sh/Project/dekita_calendar/assets/feature_graphic.png')
print("Feature graphic created successfully at assets/feature_graphic.png")
print("Size: 1024 x 500 pixels")
