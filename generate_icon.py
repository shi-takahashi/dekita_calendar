from PIL import Image, ImageDraw, ImageFont

# Create a 1024x1024 icon
size = 1024
image = Image.new('RGB', (size, size), color='#4CAF50')
draw = ImageDraw.Draw(image)

# Draw calendar shape
margin = 100
calendar_rect = [margin, margin + 80, size - margin, size - margin]
draw.rectangle(calendar_rect, fill='white', outline='#2E7D32', width=8)

# Draw header (top red bar)
header_rect = [margin, margin + 80, size - margin, margin + 200]
draw.rectangle(header_rect, fill='#FF5252')

# Draw binding rings
ring_y = margin + 80
ring_radius = 30
ring_positions = [
    size // 4,
    size // 2,
    3 * size // 4
]
for x in ring_positions:
    draw.ellipse([x - ring_radius, ring_y - ring_radius,
                  x + ring_radius, ring_y + ring_radius],
                 fill='#2E7D32', outline='#1B5E20', width=4)

# Draw grid lines (calendar dates)
grid_start_y = margin + 250
grid_rows = 5
grid_cols = 7
cell_width = (size - 2 * margin) // grid_cols
cell_height = (size - margin - grid_start_y) // grid_rows

for i in range(1, grid_rows):
    y = grid_start_y + i * cell_height
    draw.line([(margin, y), (size - margin, y)], fill='#E0E0E0', width=3)

for i in range(1, grid_cols):
    x = margin + i * cell_width
    draw.line([(x, grid_start_y), (x, size - margin)], fill='#E0E0E0', width=3)

# Draw some dots to represent dates
try:
    font = ImageFont.truetype("/System/Library/Fonts/Helvetica.ttc", 80)
except:
    font = ImageFont.load_default()

# Add a few sample numbers
sample_positions = [
    (1, 0), (2, 1), (3, 2), (4, 3), (5, 4)
]
for row, col in sample_positions:
    x = margin + col * cell_width + cell_width // 2
    y = grid_start_y + row * cell_height + cell_height // 2
    draw.ellipse([x - 25, y - 25, x + 25, y + 25], fill='#4CAF50')

# Save the image
image.save('/Users/takahashi-sh/Project/dekita_calendar/assets/icon.png')
print("Icon created successfully at assets/icon.png")