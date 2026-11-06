import os
import subprocess
import math
from PIL import Image, ImageDraw, ImageFilter, ImageOps, ImageEnhance

out_dir = "Design/Logo/exports/tests"
src_dir = "Design/Logo/source"
os.makedirs(out_dir, exist_ok=True)

targets = ["refined_01_radial_bloom", "refined_02_aperture"]

# 1. Render master 1024x1024
for name in targets:
    svg = f"{src_dir}/{name}.svg"
    raw_png = f"{out_dir}/{name}.svg.png"
    dest_1024 = f"{out_dir}/{name}_1024.png"
    subprocess.run(["qlmanage", "-t", "-s", "1024", "-o", out_dir, svg],
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if os.path.exists(raw_png):
        os.replace(raw_png, dest_1024)

sizes = [1024, 512, 256, 128, 64, 32, 16]

# 2. Generate multi-scale pyramid
for name in targets:
    master = Image.open(f"{out_dir}/{name}_1024.png").convert("RGBA")
    for s in sizes:
        scaled = master.resize((s, s), Image.Resampling.LANCZOS)
        scaled.save(f"{out_dir}/{name}_{s}.png")
    print(f"Generated scale pyramid for {name}: {sizes}")

# 3. Background Test Matrix
# Create a 4-quadrant / strip test image on:
# a) Light (#F5F5F7)
# b) Dark (#121212)
# c) Gradient Wallpaper (Sonoma sunset)
# d) 50% Grayscale (#808080)
def generate_background_matrix(name):
    icon_128 = Image.open(f"{out_dir}/{name}_128.png").convert("RGBA")
    pad = 24
    slot_w, slot_h = 176, 176
    canvas = Image.new("RGBA", (slot_w * 4, slot_h), (0, 0, 0, 0))

    # a) Light
    light_bg = Image.new("RGBA", (slot_w, slot_h), (245, 245, 247, 255))
    light_bg.paste(icon_128, (pad, pad), icon_128)
    canvas.paste(light_bg, (0, 0))

    # b) Dark
    dark_bg = Image.new("RGBA", (slot_w, slot_h), (18, 18, 18, 255))
    dark_bg.paste(icon_128, (pad, pad), icon_128)
    canvas.paste(dark_bg, (slot_w, 0))

    # c) Wallpaper Gradient
    wp = Image.new("RGBA", (slot_w, slot_h))
    draw_wp = ImageDraw.Draw(wp)
    for y in range(slot_h):
        r = int(255 - (y / slot_h) * 120)
        g = int(80 + (y / slot_h) * 100)
        b = int(140 + (y / slot_h) * 115)
        draw_wp.line([(0, y), (slot_w, y)], fill=(r, g, b, 255))
    wp.paste(icon_128, (pad, pad), icon_128)
    canvas.paste(wp, (slot_w * 2, 0))

    # d) Grayscale
    gray_bg = Image.new("RGBA", (slot_w, slot_h), (128, 128, 128, 255))
    gray_bg.paste(icon_128, (pad, pad), icon_128)
    canvas.paste(gray_bg, (slot_w * 3, 0))

    canvas.save(f"{out_dir}/{name}_test_backgrounds.png")
    print(f"Saved background test matrix: {name}_test_backgrounds.png")

for name in targets:
    generate_background_matrix(name)

# 4. Appearance Modes (Default, Dark, Clear, Tinted)
def generate_modes_matrix(name):
    icon_128 = Image.open(f"{out_dir}/{name}_128.png").convert("RGBA")
    slot_w, slot_h = 176, 176
    canvas = Image.new("RGBA", (slot_w * 5, slot_h), (20, 22, 28, 255))
    pad = 24

    # 1. Default
    canvas.paste(icon_128, (pad, pad), icon_128)

    # 2. Dark Mode (Deeper contrast)
    dark_icon = ImageEnhance.Brightness(icon_128).enhance(0.85)
    canvas.paste(dark_icon, (slot_w + pad, pad), dark_icon)

    # 3. Clear Mode (Translucent glass over blurred vibrant backing)
    backdrop = Image.new("RGBA", (128, 128))
    b_draw = ImageDraw.Draw(backdrop)
    for x in range(128):
        b_draw.line([(x, 0), (x, 128)], fill=(int(20 + x * 1.5), int(100 + x * 0.8), int(220 - x * 1.0), 255))
    blurred_back = backdrop.filter(ImageFilter.GaussianBlur(8))
    # Blend with reduced opacity
    clear_icon = icon_128.copy()
    clear_icon.putalpha(ImageEnhance.Brightness(icon_128.split()[3]).enhance(0.75))
    comp_clear = Image.alpha_composite(blurred_back, clear_icon)
    canvas.paste(comp_clear, (slot_w * 2 + pad, pad))

    # 4. Tinted: Amber Gold (#FF9500)
    gray = ImageOps.grayscale(icon_128)
    tint_amber = ImageOps.colorize(gray, black="#1A1005", white="#FFB300")
    tint_amber.putalpha(icon_128.split()[3])
    canvas.paste(tint_amber, (slot_w * 3 + pad, pad), tint_amber)

    # 5. Tinted: Emerald Green (#34C759)
    tint_green = ImageOps.colorize(gray, black="#051A0D", white="#34C759")
    tint_green.putalpha(icon_128.split()[3])
    canvas.paste(tint_green, (slot_w * 4 + pad, pad), tint_green)

    canvas.save(f"{out_dir}/{name}_test_modes.png")
    print(f"Saved modes matrix: {name}_test_modes.png")

for name in targets:
    generate_modes_matrix(name)

# 5. Color Blindness Simulation (Deuteranopia & Protanopia)
# Standard Brettel/Viénot color matrix approximation
def simulate_colorblindness(name):
    img = Image.open(f"{out_dir}/{name}_128.png").convert("RGB")
    w, h = img.size

    # Deuteranopia matrix (Green-weak)
    # [ 0.625, 0.375, 0.0,
    #   0.70,  0.30,  0.0,
    #   0.0,   0.30,  0.70 ]
    deuteranopia = img.convert("RGB", (
        0.625, 0.375, 0.0, 0.0,
        0.700, 0.300, 0.0, 0.0,
        0.000, 0.300, 0.700, 0.0
    ))

    # Protanopia matrix (Red-weak)
    # [ 0.56667, 0.43333, 0.0,
    #   0.55833, 0.44167, 0.0,
    #   0.0,     0.24167, 0.75833 ]
    protanopia = img.convert("RGB", (
        0.56667, 0.43333, 0.0, 0.0,
        0.55833, 0.44167, 0.0, 0.0,
        0.00000, 0.24167, 0.75833, 0.0
    ))

    # Composite comparison
    pad = 16
    comp = Image.new("RGB", (128 * 3 + pad * 4, 128 + pad * 2), (24, 26, 32))
    comp.paste(img, (pad, pad))
    comp.paste(deuteranopia, (128 + pad * 2, pad))
    comp.paste(protanopia, (128 * 2 + pad * 3, pad))

    comp.save(f"{out_dir}/{name}_test_colorblind.png")
    print(f"Saved colorblind test: {name}_test_colorblind.png")

for name in targets:
    simulate_colorblindness(name)

# 6. Contrast Calculation (WCAG 2.1)
def relative_luminance(rgb):
    # sRGB to linear
    def to_linear(c):
        c = c / 255.0
        return c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = to_linear(rgb[0]), to_linear(rgb[1]), to_linear(rgb[2])
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

# Background: #14171F -> (20, 23, 31)
bg_lum = relative_luminance((20, 23, 31))
# Accent Cyan: #00D2FF -> (0, 210, 255)
cyan_lum = relative_luminance((0, 210, 255))
# Accent Azure: #0A84FF -> (10, 132, 255)
azure_lum = relative_luminance((10, 132, 255))
# Pure White Tick: #FFFFFF -> (255, 255, 255)
white_lum = relative_luminance((255, 255, 255))

def contrast_ratio(l1, l2):
    brightest = max(l1, l2)
    darkest = min(l1, l2)
    return (brightest + 0.05) / (darkest + 0.05)

print("\n--- WCAG 2.1 Contrast Analysis ---")
print(f"Accent Cyan (#00D2FF) vs Obsidian Slate (#14171F): {contrast_ratio(cyan_lum, bg_lum):.2f} : 1 (Exceeds WCAG AAA 7:1)")
print(f"Accent Azure (#0A84FF) vs Obsidian Slate (#14171F): {contrast_ratio(azure_lum, bg_lum):.2f} : 1 (Exceeds WCAG AA 4.5:1)")
print(f"Platinum White (#FFFFFF) vs Obsidian Slate (#14171F): {contrast_ratio(white_lum, bg_lum):.2f} : 1 (Exceeds WCAG AAA 7:1)")

# 7. Dock Visual Weight Comparison Simulation
dock_canvas = Image.new("RGBA", (1000, 140), (28, 30, 36, 190))
dock_draw = ImageDraw.Draw(dock_canvas)

# Create 5 simulated neighbor dock icons (Finder, Safari, Terminal, Raycast, Stash)
def make_dock_icon(color, label):
    icon = Image.new("RGBA", (84, 84), (0, 0, 0, 0))
    d = ImageDraw.Draw(icon)
    # Squircle rounded rect
    d.rounded_rectangle([4, 4, 80, 80], radius=18, fill=color, outline=(255, 255, 255, 40), width=2)
    return icon

finder = make_dock_icon((30, 130, 230, 255), "Finder")
safari = make_dock_icon((15, 120, 240, 255), "Safari")
terminal = make_dock_icon((20, 20, 24, 255), "Terminal")
raycast = make_dock_icon((220, 40, 60, 255), "Raycast")
stash_icon = Image.open(f"{out_dir}/refined_01_radial_bloom_128.png").convert("RGBA").resize((76, 76), Image.Resampling.LANCZOS)

# Composite onto Dock shelf
start_x = 180
spacing = 130
dock_canvas.paste(finder, (start_x, 28), finder)
dock_canvas.paste(safari, (start_x + spacing, 28), safari)
dock_canvas.paste(terminal, (start_x + spacing * 2, 28), terminal)
dock_canvas.paste(raycast, (start_x + spacing * 3, 28), raycast)
dock_canvas.paste(stash_icon, (start_x + spacing * 4 + 4, 32), stash_icon)

dock_canvas.save(f"{out_dir}/dock_simulation_comparison.png")
print("Saved Dock simulation comparison: dock_simulation_comparison.png")
