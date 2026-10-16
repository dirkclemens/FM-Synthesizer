#!/usr/bin/env python3
"""
Generate macOS AppIcon PNG files using Pillow (no external SVG renderer needed).

Draws an FM synthesizer-themed icon programmatically:
- Dark rounded-square background with gradient
- Six operator dots in a circle (FM synthesis)
- Connecting lines between operators (FM routing)
- Sine wave across the center
- Accent bars at top and bottom

Required sizes for macOS App Icon:
 16x16, 32x32, 64x64, 128x128, 256x256, 512x512, 1024x1024
 Each with @1x and @2x variants where applicable.

Usage:
 python3 generate_appicon.py

Requirements:
 pip install Pillow
"""

import math
import json
from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter

ASSET_DIR = Path(__file__).parent / "Synthesizer" / "Assets.xcassets" / "AppIcon.appiconset"

# macOS AppIcon required sizes (base_size, @2x?)
SIZES = [
 (16, 1),
 (32, 1),
 (32, 2),
 (64, 1),
 (64, 2),
 (128, 1),
 (128, 2),
 (256, 1),
 (256, 2),
 (512, 1),
 (512, 2),
 (1024, 1),
]

# Color palette (FM synth aesthetic)
COLOR_BG_TOP = (10, 10, 15) # Dark navy-black
COLOR_BG_MID = (26, 26, 46) # Dark blue-purple
COLOR_BG_BOTTOM = (15, 15, 26) # Dark navy
COLOR_BORDER = (51, 51, 68) # Muted border

# Wave gradient colors (cyan -> purple -> magenta)
COLOR_WAVE_START = (0, 212, 255) # Cyan
COLOR_WAVE_MID = (123, 44, 191) # Purple
COLOR_WAVE_END = (255, 0, 110) # Magenta

COLOR_OP1 = (0, 212, 255) # Cyan
COLOR_OP2 = (123, 44, 191) # Purple
COLOR_OP3 = (255, 0, 110) # Magenta
COLOR_CONNECT = (42, 42, 74, 150) # Connection lines


def lerp_color(c1, c2, t):
 """Linear interpolate between two RGB colors."""
 return tuple(int(c1[i] + (c2[i] - c1[i]) * t) for i in range(3))


def t(v):
 """Convert float to int for PIL."""
 return int(round(v))


def draw_icon(base_size, scale):
 """Draw the FM synthesizer icon at the given size."""
 size = base_size * scale
 img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
 draw = ImageDraw.Draw(img)

 # Scale factor relative to 1024 base
 sc = size / 1024.0

 # --- Background: vertical gradient rounded square ---
 rect_x = t(40 * sc)
 rect_y = t(40 * sc)
 rect_w = t(944 * sc)
 rect_h = t(944 * sc)
 rect_r = t(200 * sc)

 # Create vertical gradient
 gradient = Image.new("RGB", (1, rect_h), (0, 0, 0))
 gd = ImageDraw.Draw(gradient)
 for y in range(rect_h):
 tt = y / rect_h
 if tt < 0.5:
 t2 = tt / 0.5
 c = lerp_color(COLOR_BG_TOP, COLOR_BG_MID, t2)
 else:
 t2 = (tt - 0.5) / 0.5
 c = lerp_color(COLOR_BG_MID, COLOR_BG_BOTTOM, t2)
 gradient.putpixel((0, y), c)

 gradient = gradient.resize((rect_w, rect_h), Image.LANCZOS)
 mask = Image.new("L", (rect_w, rect_h), 0)
 md = ImageDraw.Draw(mask)
 md.rounded_rectangle([0, 0, rect_w, rect_h], radius=rect_r, fill=255)

 bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
 bg.paste(gradient.convert("RGBA"), (rect_x, rect_y), mask)
 img = Image.alpha_composite(img, bg)
 draw = ImageDraw.Draw(img)

 # --- Border ---
 draw.rounded_rectangle(
 [rect_x, rect_y, rect_x + rect_w, rect_y + rect_h],
 radius=rect_r,
 outline=COLOR_BORDER,
 width=max(1, t(8 * sc)),
 )

 # --- Center circle (synth knob aesthetic) ---
 center_x = t(512 * sc)
 center_y = t(512 * sc)
 circle_r_outer = t(260 * sc)
 circle_r_inner = t(240 * sc)
 draw.ellipse(
 [center_x - circle_r_outer, center_y - circle_r_outer,
 center_x + circle_r_outer, center_y + circle_r_outer],
 outline=(42, 42, 58),
 width=max(1, t(4 * sc)),
 )
 draw.ellipse(
 [center_x - circle_r_inner, center_y - circle_r_inner,
 center_x + circle_r_inner, center_y + circle_r_inner],
 outline=(26, 26, 36),
 width=max(1, t(2 * sc)),
 )

 # --- Six operator dots in a circle ---
 # Positions around center (angle in degrees, color, radius)
 operator_positions = [
 (270, COLOR_OP1, 22), # Top - Cyan
 (30, COLOR_OP2, 20), # Top-right - Purple
 (150, COLOR_OP3, 22), # Bottom-right - Magenta
 (210, COLOR_OP1, 20), # Bottom - Cyan
 (330, COLOR_OP2, 22), # Bottom-left - Purple
 (120, COLOR_OP3, 20), # Top-left - Magenta
 ]

 operator_centers = []
 for angle_deg, color, radius_op in operator_positions:
 angle_rad = math.radians(angle_deg)
 r = 232 * sc
 ox = center_x + r * math.cos(angle_rad)
 oy = center_y + r * math.sin(angle_rad)
 op_r = t(radius_op * sc)
 draw.ellipse(
 [ox - op_r, oy - op_r, ox + op_r, oy + op_r],
 fill=color + (255,),
 )
 # Glow effect
 glow_r = t(op_r * 1.8)
 glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
 gd = ImageDraw.Draw(glow)
 gd.ellipse(
 [ox - glow_r, oy - glow_r, ox + glow_r, oy + glow_r],
 fill=color + (60,),
 )
 glow = glow.filter(ImageFilter.GaussianBlur(radius=max(1, t(8 * sc))))
 img = Image.alpha_composite(img, glow)
 draw = ImageDraw.Draw(img)
 operator_centers.append((ox, oy))

 # --- Connecting lines between operators ---
 line_width = max(1, t(3 * sc))
 # Hexagon connections between adjacent operators
 for i_idx in range(6):
 x1, y1 = operator_centers[i_idx]
 x2, y2 = operator_centers[(i_idx + 1) % 6]
 draw.line([x1, y1, x2, y2], fill=COLOR_CONNECT, width=line_width)

 # Center connections (each operator to center)
 for ox, oy in operator_centers:
 draw.line([center_x, center_y, ox, oy], fill=COLOR_CONNECT, width=line_width)

 # --- Sine wave across center ---
 wave_y = t(512 * sc)
 wave_amplitude = t(90 * sc)
 points = []
 num_segments = 100
 for i_idx in range(num_segments + 1):
 tt = i_idx / num_segments
 x = t(180 * sc + tt * (980 * sc - 180 * sc))
 # Sine wave: sin(2 * pi * t * 2.5 cycles)
 wave_val = math.sin(2 * math.pi * tt * 2.5)
 y = wave_y - int(wave_val * wave_amplitude)
 points.append((x, y))

 # Draw wave with gradient color
 for i_idx in range(len(points) - 1):
 tt = i_idx / (len(points) - 1)
 c = lerp_color(COLOR_WAVE_START, COLOR_WAVE_END, tt)
 if 0.3 < tt < 0.7:
 t2 = (tt - 0.3) / 0.4
 c = lerp_color(COLOR_WAVE_MID, COLOR_WAVE_END, t2)
 draw.line([points[i_idx], points[i_idx + 1]], fill=c + (255,),
 width=max(1, t(28 * sc)))

 # --- Small waveform detail circles ---
 detail_circles = [
 (t(340 * sc), t(512 * sc), t(8 * sc), 200),
 (t(500 * sc), t(512 * sc), t(8 * sc), 150),
 (t(660 * sc), t(512 * sc), t(8 * sc), 200),
 ]
 for cx, cy, r, alpha in detail_circles:
 draw.ellipse(
 [cx - r, cy - r, cx + r, cy + r],
 fill=(255, 255, 255, alpha),
 )

 # --- Top accent bar ---
 acc_x = t(200 * sc)
 acc_y = t(100 * sc)
 acc_w = t(624 * sc)
 acc_h = t(16 * sc)
 draw.rounded_rectangle(
 [acc_x, acc_y, acc_x + acc_w, acc_y + acc_h],
 radius=t(8 * sc),
 fill=(0, 212, 255, 30),
 )
 draw.rounded_rectangle(
 [acc_x, acc_y, acc_x + t(200 * sc), acc_y + acc_h],
 radius=t(8 * sc),
 fill=COLOR_WAVE_START + (255,),
 )

 # --- Bottom accent bar ---
 acc_y2 = t(908 * sc)
 draw.rounded_rectangle(
 [acc_x, acc_y2, acc_x + acc_w, acc_y2 + acc_h],
 radius=t(8 * sc),
 fill=(255, 0, 110, 30),
 )
 draw.rounded_rectangle(
 [acc_x + t(424 * sc), acc_y2, acc_x + t(624 * sc), acc_y2 + acc_h],
 radius=t(8 * sc),
 fill=COLOR_WAVE_END + (255,),
 )

 return img


def generate_contents_json():
 """Generate the Contents.json for the AppIcon asset catalog."""
 images = []
 for size, scale in SIZES:
 scale_str = f"{scale}x"
 size_str = f"{size}x{size}"
 filename = f"icon_{size_str}_{scale_str}.png"

 images.append({
 "size": size_str,
 "idiom": "mac",
 "filename": filename,
 "scale": scale_str,
 })

 contents = {
 "images": images,
 "info": {
 "author": "xcode",
 "version": 1,
 },
 }

 json_path = ASSET_DIR / "Contents.json"
 with open(json_path, "w") as f:
 json.dump(contents, f, indent=2)
 print(f" Generated Contents.json with {len(images)} entries")


def main():
 ASSET_DIR.mkdir(parents=True, exist_ok=True)

 print(f"Output directory: {ASSET_DIR}")
 print(f"Using renderer: Pillow (built-in)")
 print()

 generated = 0
 for size, scale in SIZES:
 png_size = size * scale
 scale_str = f"{scale}x"
 size_str = f"{size}x{size}"
 filename = f"icon_{size_str}_{scale_str}.png"
 output_path = ASSET_DIR / filename

 try:
 img = draw_icon(size, scale)
 img.save(output_path, "PNG")
 print(f" ✓ {filename} ({png_size}x{png_size})")
 generated += 1
 except Exception as e:
 print(f" ✗ {filename} FAILED: {e}")

 print()
 generate_contents_json()

 print(f"\nGenerated {generated}/{len(SIZES)} icon files")
 print()
 print("Next steps:")
 print(" 1. Open Synthesizer.xcodeproj in Xcode")
 print(" 2. Select AppIcon.appiconset in Assets.xcassets")
 print(" 3. Verify all icon slots show the generated PNGs")
 print(" 4. Build and run — the app icon should appear in Finder/Dock")


if __name__ == "__main__":
 main()
