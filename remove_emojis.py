#!/usr/bin/env python3
"""
Remove ALL emojis from .md and .txt files in the pythonprogrammingproject event directory.
Replace with plain ASCII equivalents.
"""
import re
import os
import sys

# Directory containing the project files
PROJECT_DIR = "/workspace/pythonprogrammingproject event"

# Comprehensive emoji-to-ASCII replacement mapping
EMOJI_MAP = {
    # Question marks / discussion
    '\u2753': 'Q:',       # ❓
    '\u2754': 'Q:',       # ❔
    '\U0001F64B': 'Discuss:',  # 🙋
    '\U0001F64B\u200D\u2642\uFE0F': 'Discuss:',  # 🙋‍♂️
    '\U0001F64B\u200D\u2640\uFE0F': 'Discuss:',  # 🙋‍♀️
    
    # Brooms / cleaning
    '\U0001F9F9': '[Tidy]',  # 🧹
    
    # Magnifying glass
    '\U0001F50D': '[Group]',  # 🔍
    
    # Crystal ball
    '\U0001F52E': '[Predict]',  # 🔮
    
    # Colored circles
    '\U0001F7E1': '(Y)',   # 🟡 yellow circle
    '\U0001F7E2': '(G)',   # 🟢 green circle
    '\U0001F7E3': '(P)',   # 🟣 purple circle
    '\U0001F7E0': '(O)',   # 🟠 orange circle
    '\U0001F534': '(R)',   # 🔴 red circle
    '\U0001F535': '(B)',   # 🔵 blue circle
    
    # Package / box
    '\U0001F4E6': '[Setup]',  # 📦
    
    # Check mark button
    '\u2705': '[OK]',     # ✅
    
    # Artist palette
    '\U0001F3A8': '[Color]',  # 🎨
    
    # Sleeping / thinking / explosion
    '\U0001F634': '[Not sig]',  # 😴 sleeping
    '\U0001F914': '[Unsure]',   # 🤔 thinking
    '\U0001F4A5': '[Strong]',   # 💥 explosion/collision
    
    # Stars (for ratings)
    '\u2B50': '*',  # ⭐ star
    '\U0001F31F': '*',  # 🌟 glowing star
    
    # Toolbox
    '\U0001F9F0': '[Toolkit]',  # 🧰
    
    # Rocket
    '\U0001F680': '[Advanced]',  # 🚀
    
    # Memo / notes
    '\U0001F4DD': '[Notes]',  # 📝
    
    # High voltage
    '\u26A1': '[Quick]',  # ⚡
    
    # Folder
    '\U0001F4C2': '[Folder]',  # 📂
    
    # Bandage / adhesive bandage
    '\U0001FA79': '[Fix]',  # 🩹
    
    # Microscope
    '\U0001F52C': '[Group]',  # 🔬
    
    # Abacus
    '\U0001F9EE': '[Stats]',  # 🧮
    
    # Plus
    '\u2795': '[Add]',  # ➕
    
    # Chart
    '\U0001F4CA': '[Data]',  # 📊
    
    # Robot
    '\U0001F916': '[ML]',  # 🤖
    
    # Globe
    '\U0001F310': '[Online]',  # 🌐
    
    # Money bag
    '\U0001F4B0': '[Salary]',  # 💰
    
    # Shopping cart / trolley
    '\U0001F6D2': '[Customers]',  # 🛒
    
    # Cross mark
    '\u274C': '[No]',      # ❌
    
    # White heavy check mark
    '\u2705': '[OK]',     # ✅ (already mapped)
    
    # Party popper
    '\U0001F389': '[Done]',  # 🎉
    
    # Fire
    '\U0001F525': '[Hot]',   # 🔥
    
    # Direct hit / bullseye
    '\U0001F3AF': '[Target]',  # 🎯
    
    # Memo (duplicate)
    '\U0001F4DD': '[Notes]',  # 📝
    
    # Backhand index pointing up
    '\U0001F446': '[Up]',   # 👆
    
    # OK hand
    '\U0001F44C': '[OK]',  # 👌
    
    # Clapping hands
    '\U0001F44F': '[Well done]',  # 👏
    
    # Raised hand
    '\u270B': '[Raise hand]',  # ✋
    
    # Waving hand
    '\U0001F44B': '[Hi]',   # 👋
    
    # Folded hands
    '\U0001F64F': '[Thanks]',  # 🙏
    
    # Fire emoji (also)
    '\U0001F525': '[Fire]',  # 🔥
}

# Additional manual replacements for compound or multi-codepoint emoji sequences
# that are hard to catch with single-char mapping
MANUAL_REPLACEMENTS = [
    # Notebook with decorative cover
    ('\U0001F4D4', '[Notes]'),
    # Open book
    ('\U0001F4D6', '[Book]'),
    # Light bulb
    ('\U0001F4A1', '[Idea]'),
    # Chart with upwards trend
    ('\U0001F4C8', '[Chart]'),
    # Bar chart
    ('\U0001F4CA', '[Chart]'),
    # Gear
    ('\u2699', '[Settings]'),
    # Warning
    ('\u26A0', '[Warning]'),
    # Heavy check mark
    ('\u2714', '[OK]'),
    # Heavy ballot X
    ('\u2718', '[No]'),
    # Right arrow (these are fine, keep as is)
    # Actually let's keep arrows - they're already ASCII
    # Heavy large circle
    ('\u2B55', '(O)'),
]

def is_emoji(char):
    """Check if a character is an emoji."""
    cp = ord(char)
    
    # Check known emoji ranges
    ranges = [
        (0x1F300, 0x1F9FF),  # Misc symbols, emoticons, pictographs
        (0x1FA00, 0x1FAFF),  # Symbols extended-A
        (0x2600, 0x27BF),    # Misc symbols, dingbats
        (0x2300, 0x23FF),    # Misc technical
        (0x2400, 0x243F),    # Control pictures
        (0x2440, 0x245F),    # OCR
        (0x25A0, 0x25FF),    # Geometric shapes
        (0x2700, 0x27BF),    # Dingbats
        (0xFE00, 0xFE0F),    # Variation selectors
        (0x200D, 0x200D),    # ZWJ
        (0x1F1E6, 0x1F1FF),  # Regional indicators
    ]
    
    for start, end in ranges:
        if start <= cp <= end:
            return True
    
    # Also check for characters in the Supplementary Multilingual Plane (SMP)
    # that look like emojis
    if cp >= 0x1F000 and cp <= 0x1FFFF:
        return True
    
    # Dingbat ranges
    if cp >= 0x2776 and cp <= 0x2793:  # Dingbat negative circled digits
        return False  # These are just numbered circles, not emojis
    
    return False

def replace_emoji_sequence(text):
    """Replace emoji sequences with ASCII equivalents."""
    result = []
    i = 0
    while i < len(text):
        char = text[i]
        
        # Check for variation selector following a character
        cp = ord(char)
        
        # Skip variation selectors and ZWJ
        if cp == 0xFE0F or cp == 0xFE0E or cp == 0x200D:
            i += 1
            continue
        
        # Check for skin tone modifiers
        if 0x1F3FB <= cp <= 0x1F3FF:
            i += 1
            continue
        
        # Check the emoji map first
        if char in EMOJI_MAP:
            result.append(EMOJI_MAP[char])
            i += 1
            continue
        
        # Check regex ranges for emoji
        if is_emoji(char):
            # Try to find a mapping
            cp = ord(char)
            # Generic placeholder based on codepoint
            result.append(f'[{hex(cp)[2:]}]')
        else:
            result.append(char)
        
        i += 1
    
    return ''.join(result)

def count_emojis(text):
    """Count emoji characters in text."""
    count = 0
    i = 0
    while i < len(text):
        cp = ord(text[i])
        if cp == 0xFE0F or cp == 0xFE0E or cp == 0x200D:
            i += 1
            continue
        if 0x1F3FB <= cp <= 0x1F3FF:
            i += 1
            continue
        if is_emoji(text[i]) or text[i] in EMOJI_MAP:
            count += 1
        i += 1
    return count

def find_emoji_positions(text):
    """Find all emoji positions and characters in text."""
    positions = []
    i = 0
    while i < len(text):
        cp = ord(text[i])
        if cp == 0xFE0F or cp == 0xFE0E or cp == 0x200D:
            i += 1
            continue
        if 0x1F3FB <= cp <= 0x1F3FF:
            i += 1
            continue
        if is_emoji(text[i]) or text[i] in EMOJI_MAP:
            # Get surrounding context
            start = max(0, i - 20)
            end = min(len(text), i + 20)
            context = text[start:end].replace('\n', '\\n')
            positions.append((i, text[i], hex(ord(text[i])), context))
        i += 1
    return positions

def process_file(filepath):
    """Process a single file: remove emojis."""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find all emojis first
    emoji_positions = find_emoji_positions(content)
    emoji_count = len(emoji_positions)
    
    if emoji_count == 0:
        print(f"  No emojis found: {filepath}")
        return 0
    
    print(f"\n  Found {emoji_count} emoji(s) in: {filepath}")
    for pos, char, hex_val, context in emoji_positions:
        print(f"    Pos {pos}: U+{hex_val[2:].upper()} '{char}' context: ...{context}...")
    
    # Replace emojis
    cleaned = replace_emoji_sequence(content)
    
    # Also apply manual replacements
    for old, new in MANUAL_REPLACEMENTS:
        cleaned = cleaned.replace(old, new)
    
    # Verify replacement
    remaining = find_emoji_positions(cleaned)
    remaining_count = len(remaining)
    
    if remaining_count > 0:
        print(f"  WARNING: {remaining_count} emojis still remain!")
        for pos, char, hex_val, context in remaining:
            print(f"    Remaining: U+{hex_val[2:].upper()} '{char}' ...{context}...")
    
    # Write back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(cleaned)
    
    print(f"  Written: {filepath}")
    return emoji_count

def main():
    files_to_process = []
    for fname in os.listdir(PROJECT_DIR):
        if fname.endswith('.md') or fname.endswith('.txt'):
            files_to_process.append(os.path.join(PROJECT_DIR, fname))
    
    files_to_process.sort()
    
    print("=" * 70)
    print("EMOJI REMOVAL FROM HONOURS PROJECT FILES")
    print("=" * 70)
    print(f"\nFiles to process: {len(files_to_process)}")
    for f in files_to_process:
        print(f"  {f}")
    
    total_removed = 0
    for filepath in files_to_process:
        total_removed += process_file(filepath)
    
    print("\n" + "=" * 70)
    print(f"SUMMARY: Removed {total_removed} emoji instances total")
    print("=" * 70)
    
    # Final verification: scan all files for remaining emojis
    print("\n" + "=" * 70)
    print("FINAL VERIFICATION - Checking all files for remaining emojis")
    print("=" * 70)
    grand_total = 0
    for filepath in files_to_process:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        remaining = find_emoji_positions(content)
        if remaining:
            print(f"\n  !! REMAINING EMOJIS in {filepath}: {len(remaining)}")
            for pos, char, hex_val, context in remaining:
                print(f"     U+{hex_val[2:].upper()} '{char}' ...{context}...")
            grand_total += len(remaining)
        else:
            print(f"  CLEAN: {os.path.basename(filepath)}")
    
    if grand_total == 0:
        print("\n*** ALL FILES CLEAN - ZERO EMOJIS REMAINING ***")
    else:
        print(f"\n*** WARNING: {grand_total} emojis still remaining ***")
        sys.exit(1)

if __name__ == '__main__':
    main()
