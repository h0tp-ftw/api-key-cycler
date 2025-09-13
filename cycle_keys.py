***

# API Key Cycler

![status](https://img.shields.io/badge/status-active-brightgreenhttps://img.shields.io/badgehttps://img.shields.io/badgegeneric API key cycler** for managing environment variable sets in `.env`-style files. Instantly cycle through multiple API credential groups—either sequentially, randomly, or by a specific index—using a robust command-line interface.

***

## Table of Contents

- [Features](#features)
- [How it Works](#how-it-works)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
    - [Basic Operations](#basic-operations)
    - [Arguments Reference](#arguments-reference)
    - [Advanced Examples](#advanced-examples)
- [Supported .env Format](#supported-env-format)
- [Exit Codes](#exit-codes)
- [Contributing](#contributing)
- [License](#license)

***

## Features

- **Cycle API Keys/Secrets** for any service (OpenAI, Gemini, Azure, Anthropic, etc.)
- **Works with any file** (not limited to `.env`)
- **Customizable groups** of related configuration parameters
- **Sequential, random, and direct jump cycling**
- **View current/available key sets without changes**
- **Clean, fully English CLI interface**
- **Comprehensive error handling**
- **Ready for automation and scripting**

***

## How it Works

**cycle_keys.py** manages environment variable sets (e.g., API credentials, project IDs) defined in "groups." For each group, it enables you to:
- Cycle to next or previous set (by uncommenting and commenting lines)
- Jump directly to a specific set
- Swap to a random set (excluding the currently active one)
- Show current configuration or view all available sets

***

## Installation

**No dependencies required except Python (3.7+)**

1. Download `cycle_keys.py` and place it in your project directory.

2. Ensure your `.env` or configuration file is formatted correctly (see below).

3. Make the script executable (Linux/macOS only):
```bash
chmod +x cycle_keys.py
```

***

## Configuration

Edit the `PARAMETER_GROUPS` variable at the top of `cycle_keys.py`:
```python
PARAMETER_GROUPS = [
    ["OPENAI_KEY", "OPENAI_PROJECT", "OPENAI_LOCATION"],    # 3 parameters
    ["GEMINI_API_KEY", "VERTEXAI_PROJECT"],                 # 2 parameters
    ["AZURE_KEY", "AZURE_ENDPOINT", "AZURE_REGION"]         # 3 parameters
]
```
- Each sub-list represents a logical set that cycles together.
- You can add/remove groups for your needs.

***

## Usage

### Basic Operations
```bash
python cycle_keys.py                 # Cycle to next set in .env
python cycle_keys.py custom.env      # Use another file
python cycle_keys.py --random        # Switch to a random set
python cycle_keys.py --jump 3        # Jump to set #3
```

### Arguments Reference
| Argument          | Description                                                    |
|-------------------|---------------------------------------------------------------|
| `--file, -f`      | Path to .env file (default: `.env`)                           |
| `--random, -r`    | Cycle to a random set (not the current)                       |
| `--jump, -j N`    | Jump directly to the Nth set (1-based index)                  |
| `--show, -s`      | Print current configuration without modifying file             |
| `--list, -l`      | List all available sets for each parameter group               |
| `--help, -h`      | Display help message and usage instructions                   |

### Advanced Examples
```bash
python cycle_keys.py prod.env --random      # Random cycling in prod.env
python cycle_keys.py --file test.env -j 2   # Jump to set 2 in test.env
python cycle_keys.py staging.env --show     # Inspect config in staging.env
python cycle_keys.py --list                 # Print all possible sets for selection
```

***

## Supported .env Format

For each parameter group, create corresponding entries:

```env
# Active set (uncommented)
OPENAI_KEY=key1
OPENAI_PROJECT=project1
OPENAI_LOCATION=us-east-1

# Inactive sets (commented)
# OPENAI_KEY=key2
# OPENAI_PROJECT=project2
# OPENAI_LOCATION=eu-west-1

# OPENAI_KEY=key3
# OPENAI_PROJECT=project3
# OPENAI_LOCATION=asia-pacific-1
```
- All parameters in the same position (nth occurrence) are treated as a set.

***

## Exit Codes

- `0`: Success
- `1`: Error (missing file, invalid configuration, etc.)

***

## Contributing

Contributions and feedback welcome! If you'd like to add new features, improve documentation, or report bugs:
- Fork the repository
- Create a feature branch
- Open a pull request with your changes

***

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

***

**cycle_keys.py** is the fastest way to manage and automate API key cycling for multi-service projects. Clean, robust, and fully customizable.

***

If you have any questions or need more help, feel free to open an issue or contact the author.

***

*Inspired by best practices from [Real Python](https://realpython.com/readme-python-project/) and the [Best-README-Template](https://github.com/othneildrew/Best-README-Template).*[1][3]

[1](https://realpython.com/readme-python-project/)
[2](https://www.makeareadme.com)
[3](https://github.com/othneildrew/Best-README-Template)
[4](https://packaging.python.org/guides/making-a-pypi-friendly-readme/)
[5](https://github.com/catiaspsilva/README-template)
[6](https://www.youtube.com/watch?v=12trn2NKw5I)
[7](https://ubc-library-rc.github.io/rdm/content/03_create_readme.html)
[8](https://docs.techstartucalgary.com/projects/readme/index.html)
[9](https://www.reddit.com/r/Python/comments/u7081n/i_developed_a_template_for_starting_new_python/)