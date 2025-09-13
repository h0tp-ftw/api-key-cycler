#!/usr/bin/env python3
"""
Generic API Key Cycler

This script enables automatic cycling of any group of related environment
parameters (e.g., API keys, projects, regions, etc.) in a .env file.

The script can intelligently detect the currently active parameter set
and switch to the next one, a random one, or jump to a specific set number.

Configuration: Modify the PARAMETER_GROUPS variable below to define
your own parameter groups.

Usage Examples:
    python cycle_keys.py                     # Cycle to next set
    python cycle_keys.py --file custom.env   # Use custom file
    python cycle_keys.py --random            # Switch to random set
    python cycle_keys.py --jump 3            # Jump to set #3
    python cycle_keys.py --show              # Show current config
    python cycle_keys.py --help              # Show help

Example configuration for OpenAI:
    PARAMETER_GROUPS = [
        ["OPENAI_KEY", "OPENAI_PROJECT", "OPENAI_LOCATION"]
    ]

Example configuration for multiple services:
    PARAMETER_GROUPS = [
        ["GEMINI_API_KEY", "VERTEXAI_PROJECT"],
        ["OPENAI_KEY", "OPENAI_PROJECT", "OPENAI_LOCATION"],
        ["AZURE_KEY", "AZURE_ENDPOINT", "AZURE_REGION"]
    ]
"""

import re
import sys
import os
import argparse
import random

# ============================================================================
# CONFIGURATION - MODIFY THIS SECTION
# ============================================================================

# Define your parameter groups here
# Each sub-list represents a group of parameters that should be cycled together
#
# Expected format in .env file:
#
# For a group ["PARAM1", "PARAM2", "PARAM3"]:
# PARAM1=value1
# # PARAM1=value2  
# # PARAM1=value3
# 
# PARAM2=project1
# # PARAM2=project2
# # PARAM2=project3
#
# PARAM3=location1
# # PARAM3=location2
# # PARAM3=location3
#
# All parameters at the same index (1st, 2nd, 3rd...) form a logical "set"

PARAMETER_GROUPS = [
    # Example for Gemini
    ["GEMINI_API_KEY", "VERTEXAI_PROJECT"],

    # Example for OpenAI  
    # ["OPENAI_KEY", "OPENAI_PROJECT", "OPENAI_LOCATION"],

    # Example for Azure
    # ["AZURE_KEY", "AZURE_ENDPOINT", "AZURE_REGION"],

    # Add your own groups here
]

# ============================================================================
# MAIN CODE - DO NOT MODIFY UNLESS NECESSARY  
# ============================================================================

def find_parameter_lines(lines, parameter_name):
    """
    Find all lines corresponding to a given parameter
    (both commented and uncommented)

    Returns: list of dictionaries with index, commented, line
    """
    param_lines = []

    for i, line in enumerate(lines):
        line_stripped = line.strip()

        # Search for parameter (with or without comment)
        pattern = rf'^#?\s*{re.escape(parameter_name)}\s*='
        if re.match(pattern, line_stripped):
            is_commented = line_stripped.startswith('#')
            param_lines.append({'index': i, 'commented': is_commented, 'line': line})

    return param_lines

def get_current_active_index(all_param_lines, parameter_group, num_sets):
    """
    Find the currently active set index

    Returns: current active index (-1 if none found)
    """
    current_active_index = -1

    for i in range(num_sets):
        # Check if all parameters at this index are uncommented
        all_uncommented = True
        for param_name in parameter_group:
            if all_param_lines[param_name][i]['commented']:
                all_uncommented = False
                break

        if all_uncommented:
            if current_active_index != -1:
                print("⚠️  Warning: Multiple active sets detected. Using the first one.")
                break
            current_active_index = i

    return current_active_index

def cycle_parameter_group(env_file_path, parameter_group, target_index=None, random_selection=False):
    """
    Perform cycling for a specific parameter group

    Args:
        env_file_path (str): Path to .env file
        parameter_group (list): List of parameter names to cycle together
        target_index (int, optional): Specific index to jump to (0-based)
        random_selection (bool): Whether to select a random set

    Returns:
        bool: True if cycling succeeded, False otherwise
    """

    # Read the .env file
    try:
        with open(env_file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
    except FileNotFoundError:
        print(f"❌ Error: File {env_file_path} not found!")
        return False
    except Exception as e:
        print(f"❌ Error reading file: {e}")
        return False

    # Find lines for each parameter in the group
    all_param_lines = {}

    for param_name in parameter_group:
        param_lines = find_parameter_lines(lines, param_name)
        all_param_lines[param_name] = param_lines

        if len(param_lines) == 0:
            print(f"⚠️  No entries found for {param_name}")
            return False

    # Validation: all parameters must have the same number of entries
    param_counts = [len(all_param_lines[param]) for param in parameter_group]
    if len(set(param_counts)) > 1:
        print(f"❌ Error: Different number of entries between parameters:")
        for param in parameter_group:
            print(f"   {param}: {len(all_param_lines[param])} entries")
        return False

    num_sets = param_counts[0]
    if num_sets == 0:
        print("❌ No entries found for this parameter group!")
        return False

    print(f"📊 Found {num_sets} sets for group {parameter_group}")

    # Find currently active set
    current_active_index = get_current_active_index(all_param_lines, parameter_group, num_sets)

    # Determine next active index based on mode
    if target_index is not None:
        # Jump to specific index
        if target_index < 0 or target_index >= num_sets:
            print(f"❌ Error: Target index {target_index + 1} is out of range (1-{num_sets})")
            return False
        next_active_index = target_index
        print(f"🎯 Jumping to set: #{next_active_index + 1}")
    elif random_selection:
        # Random selection (excluding current if possible)
        if num_sets == 1:
            next_active_index = 0
            print("🎲 Only one set available, selecting it")
        else:
            available_indices = [i for i in range(num_sets) if i != current_active_index]
            next_active_index = random.choice(available_indices)
            print(f"🎲 Randomly selected set: #{next_active_index + 1}")
    else:
        # Sequential cycling (default)
        if current_active_index == -1:
            print("🔄 No active set found. Activating the first set.")
            next_active_index = 0
        else:
            next_active_index = (current_active_index + 1) % num_sets
            print(f"🔄 Currently active set: #{current_active_index + 1}")
        print(f"➡️  Cycling to set: #{next_active_index + 1}")

    # Create new lines with modifications
    new_lines = lines.copy()

    # Comment all sets first
    for i in range(num_sets):
        for param_name in parameter_group:
            param_line_info = all_param_lines[param_name][i]
            line_idx = param_line_info['index']

            if not param_line_info['commented']:
                new_lines[line_idx] = '# ' + lines[line_idx]

    # Uncomment the target set
    for param_name in parameter_group:
        param_line_info = all_param_lines[param_name][next_active_index]
        line_idx = param_line_info['index']

        # Uncomment by removing the '# ' prefix
        line = new_lines[line_idx]
        if line.strip().startswith('#'):
            new_lines[line_idx] = re.sub(r'^#\s*', '', line)

    # Write to file
    try:
        with open(env_file_path, 'w', encoding='utf-8') as file:
            file.writelines(new_lines)
        print(f"✅ Successfully cycled group {parameter_group}")
        return True
    except Exception as e:
        print(f"❌ Error writing to {env_file_path}: {e}")
        return False

def display_current_active_sets(env_file_path):
    """
    Display currently active sets for all groups
    """
    try:
        with open(env_file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
    except FileNotFoundError:
        print(f"❌ Error: File {env_file_path} not found!")
        return

    print("📋 Current Configuration:")

    for group_idx, parameter_group in enumerate(PARAMETER_GROUPS):
        print(f"\n🔧 Group {group_idx + 1}: {parameter_group}")

        # Find active values for this group
        active_values = {}
        for param_name in parameter_group:
            for line in lines:
                line_stripped = line.strip()

                # Search for uncommented parameter
                pattern = rf'^{re.escape(param_name)}\s*=(.+)$'
                match = re.match(pattern, line_stripped)
                if match:
                    active_values[param_name] = match.group(1).strip()
                    break

        # Display values
        if len(active_values) == len(parameter_group):
            for param_name in parameter_group:
                print(f"   ✅ {param_name} = {active_values[param_name]}")
        else:
            print("   ⚠️  Incomplete configuration:")
            for param_name in parameter_group:
                if param_name in active_values:
                    print(f"   ✅ {param_name} = {active_values[param_name]}")
                else:
                    print(f"   ❌ {param_name} = (not defined)")

def list_available_sets(env_file_path):
    """
    List all available sets for each group
    """
    try:
        with open(env_file_path, 'r', encoding='utf-8') as file:
            lines = file.readlines()
    except FileNotFoundError:
        print(f"❌ Error: File {env_file_path} not found!")
        return

    print("📋 Available Sets:")

    for group_idx, parameter_group in enumerate(PARAMETER_GROUPS):
        print(f"\n🔧 Group {group_idx + 1}: {parameter_group}")

        # Get all parameter lines for the first parameter to count sets
        first_param = parameter_group[0]
        param_lines = find_parameter_lines(lines, first_param)

        if not param_lines:
            print("   ❌ No sets found")
            continue

        # Display each set
        for i, _ in enumerate(param_lines):
            print(f"   Set #{i + 1}:")
            for param_name in parameter_group:
                param_lines_for_name = find_parameter_lines(lines, param_name)
                if i < len(param_lines_for_name):
                    line = param_lines_for_name[i]['line']
                    # Extract value from line
                    match = re.search(rf'{re.escape(param_name)}\s*=(.+)$', line.strip().lstrip('# '))
                    if match:
                        value = match.group(1).strip()
                        status = "🟢 ACTIVE" if not param_lines_for_name[i]['commented'] else "⚪ INACTIVE"
                        print(f"     {param_name} = {value} {status}")

def parse_arguments():
    """
    Parse command-line arguments
    """
    parser = argparse.ArgumentParser(
        description="Generic API Key Cycler - Cycle environment variables in .env files",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  %(prog)s                           Cycle to next set (default)
  %(prog)s --file custom.env         Use custom .env file
  %(prog)s --random                  Switch to random set
  %(prog)s --jump 3                  Jump to set #3
  %(prog)s --show                    Show current configuration
  %(prog)s --list                    List all available sets

The script reads parameter groups from PARAMETER_GROUPS in the code.
Modify that variable to configure which parameters to cycle together.
        """
    )

    parser.add_argument(
        'file', 
        nargs='?', 
        default='.env',
        help='Path to the .env file (default: .env)'
    )

    parser.add_argument(
        '-f', '--file',
        dest='env_file',
        help='Path to the .env file (same as positional argument)'
    )

    parser.add_argument(
        '-r', '--random',
        action='store_true',
        help='Select a random set instead of the next sequential one'
    )

    parser.add_argument(
        '-j', '--jump',
        type=int,
        metavar='N',
        help='Jump to a specific set number (1-based indexing)'
    )

    parser.add_argument(
        '-s', '--show',
        action='store_true',
        help='Show current active configuration without making changes'
    )

    parser.add_argument(
        '-l', '--list',
        action='store_true',
        help='List all available sets for each parameter group'
    )

    return parser.parse_args()

def main():
    """Main function"""

    # Parse arguments
    args = parse_arguments()

    # Determine the .env file path
    env_file_path = args.env_file if args.env_file else args.file

    # Validate configuration
    if not PARAMETER_GROUPS:
        print("❌ Error: No parameter groups defined in PARAMETER_GROUPS!")
        print("🔧 Modify the PARAMETER_GROUPS variable in the script.")
        sys.exit(1)

    print("🔄 Generic API Key Cycler")
    print("=" * 50)
    print(f"📁 File: {env_file_path}")
    print(f"🎯 Configured groups: {len(PARAMETER_GROUPS)}")

    # Check file existence
    if not os.path.exists(env_file_path):
        print(f"❌ File {env_file_path} does not exist!")
        print("💡 Create your .env file with the API keys first.")
        sys.exit(1)

    # Handle show-only mode
    if args.show:
        display_current_active_sets(env_file_path)
        return

    # Handle list mode
    if args.list:
        list_available_sets(env_file_path)
        return

    # Show current configuration before cycling
    print("\nCurrent configuration:")
    display_current_active_sets(env_file_path)

    print("\n" + "="*50)
    print("🔄 Starting key cycling...")

    # Perform cycling for each group
    success_count = 0
    for group_idx, parameter_group in enumerate(PARAMETER_GROUPS):
        print(f"\n🔧 Cycling group {group_idx + 1}: {parameter_group}")

        # Determine target index if jumping
        target_index = None
        if args.jump is not None:
            target_index = args.jump - 1  # Convert to 0-based indexing

        if cycle_parameter_group(env_file_path, parameter_group, target_index, args.random):
            success_count += 1
        else:
            print(f"❌ Failed to cycle group {group_idx + 1}")

    print("\n" + "="*50)

    if success_count == len(PARAMETER_GROUPS):
        print("🎉 All key cycling completed successfully!")
        print("\n📋 New configuration:")
        display_current_active_sets(env_file_path)
    else:
        print(f"⚠️  {success_count}/{len(PARAMETER_GROUPS)} cycling operations succeeded")
        sys.exit(1)

if __name__ == "__main__":
    main()
