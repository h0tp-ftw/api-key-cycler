***

# API Key Cycler
<div align="center"> <!-- Shields.io badges for visual impact --> <a href="https://github.com/h0tp-ftw/api-key-cycler"> <img src="https://img.shields.io/github/stars/h0tp-ftw/api-key-cycler?style=for-the-badge&label=Stars" alt="GitHub stars" /> </a> <a href="https://github.com/h0tp-ftw/api-key-cycler/releases"> <img src="https://img.shields.io/github/v/release/h0tp-ftw/api-key-cycler?style=for-the-badge&label=Latest" alt="Latest Release" /> </a> <a href="https://github.com/h0tp-ftw/api-key-cycler/blob/main/LICENSE"> <img src="https://img.shields.io/github/license/h0tp-ftw/api-key-cycler?style=for-the-badge" alt="MIT License"/> </a> <a href="https://www.python.org/downloads/"> <img src="https://img.shields.io/badge/Python-3.7%2B-blue?style=for-the-badge" alt="Python 3.7+"/> </a> <a href="https://github.com/h0tp-ftw/api-key-cycler"> <img src="https://img.shields.io/badge/Platform-Windows%20%7C%20Linux%20%7C%20macOS-blue?style=for-the-badge" alt="Windows | Linux | macOS"/> </a> </div>


**Universal API key and environment variable cycler.** Seamlessly cycle through multiple API credential sets for OpenAI, Gemini, Azure, Anthropic, and any other service for locally-stored environment variables (e.g. in a .env file). Features interactive installers, cross-platform compatibility, and intelligent configuration validation. **CURRENTLY IN ALPHA - PENDING MORE CROSS-PLATFORM TESTING AND USER REVIEWS**

***

## 🚀 Quick Start

### Linux/macOS
```bash
bash <(curl -s https://raw.githubusercontent.com/h0tp-ftw/api-key-cycler/main/install.sh)
```

### Windows PowerShell
```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/h0tp-ftw/api-key-cycler/main/install.ps1" -OutFile install.ps1; .\install.ps1
```

***

## ✨ Features

- **🔄 Universal Key Cycling**: Works with any API service (OpenAI, Gemini, Azure, Anthropic, etc.)
- **🎯 Multiple Cycling Modes**: Sequential, random, or jump to specific sets
- **🛠️ Interactive Installers**: Guided setup for both Unix/Linux and Windows
- **📁 Flexible File Support**: Works with any `.env`-style configuration file
- **🖥️ Cross-Platform**: Linux, macOS via Python script, Windows via bat script
- **⚙️ Zero Dependencies**: Uses only Python standard library

***

## 📋 Table of Contents

- [Installation Options](#installation-options)
- [Configuration](#configuration)
- [Usage](#usage)
  - [Command Line Arguments](#command-line-arguments)
  - [Basic Examples](#basic-examples)
  - [Windows Usage](#windows-usage)
- [Supported File Format](#supported-file-format)
- [Example Scenarios](#example-scenarios)
- [Platform Compatibility](#platform-compatibility)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)
- [License](#license)
- [Author](#author)
- [Responsible Usage Notice](#responsible-usage-notice)

***

## 🛠️ Installation Options

| Method | Platform | Command |
|--------|----------|---------|
| **Interactive Bash** | Linux/Mac/WSL | `bash <(curl -s https://raw.githubusercontent.com/h0tp-ftw/api-key-cycler/main/install.sh)` |
| **Interactive PowerShell** | Windows | `Invoke-WebRequest -Uri https://raw.githubusercontent.com/h0tp-ftw/api-key-cycler/main/install.ps1 -OutFile install.ps1; .\install.ps1` |
| **Manual Download** | Any | Download `cycle_keys.py` or `cycle_keys.bat` directly and modify it |

### What the Installers Do
1. **📁 Directory Setup**: Choose installation location
2. **🔧 Parameter Configuration**: Define your API key groups
3. **📄 File Path Setup**: Set default .env file location
4. **🔍 Format Validation**: Check existing .env files and provide guidance
5. **🎯 Mode Selection**: Choose default cycling behavior (sequential/random)
6. **📄 Template Generation**: Create sample .env files if needed

***

## ⚙️ Configuration

During installation, configure your parameter groups. Examples:

### Single Service (2 parameters)
```
GEMINI_API_KEY,VERTEXAI_PROJECT
```

### Multiple Services (using | separator)
```
GEMINI_API_KEY,VERTEXAI_PROJECT|OPENAI_KEY,OPENAI_PROJECT,OPENAI_LOCATION
```

### Complex Setup
```
OPENAI_KEY,OPENAI_PROJECT,OPENAI_LOCATION|AZURE_KEY,AZURE_ENDPOINT,AZURE_REGION|ANTHROPIC_API_KEY
```

***

## 💻 Usage

### Command Line Arguments

| Argument | Short | Description |
|----------|-------|-------------|
| `--file PATH` | `-f` | Path to .env file (default: `.env` in same directory as script) |
| `--random` | `-r` | Cycle to random set (excludes current set) |
| `--jump N` | `-j` | Jump directly to set number N (1-based) |
| `--show` | `-s` | Display current configuration without changes |
| `--list` | `-l` | List all available sets for each group |
| `--help` | `-h` | Show help message and usage examples |

### Basic Examples

```bash
# Basic cycling (sequential)
python cycle_keys.py

# Random cycling
python cycle_keys.py --random

# Jump to specific set
python cycle_keys.py --jump 3

# Use custom file
python cycle_keys.py --file production.env --random

# Show current configuration
python cycle_keys.py --show

# List all available sets
python cycle_keys.py --list
```

### Windows Usage

After installation, Windows users get additional convenience:

```cmd
# Using the batch launcher (no need to type "python")
cycle_keys --show
cycle_keys --random
cycle_keys --jump 2
```

***

## 📄 Supported File Format

Create your `.env` file with this structure:

```env
# Group 1: OpenAI Configuration
# Set 1 (currently active)
OPENAI_KEY=sk-proj-abc123...
OPENAI_PROJECT=project-alpha
OPENAI_LOCATION=us-east-1

# Set 2 (inactive)
# OPENAI_KEY=sk-proj-def456...
# OPENAI_PROJECT=project-beta
# OPENAI_LOCATION=eu-west-1

# Set 3 (inactive)
# OPENAI_KEY=sk-proj-ghi789...
# OPENAI_PROJECT=project-gamma
# OPENAI_LOCATION=asia-pacific-1

# Group 2: Database URLs
DATABASE_URL=postgres://prod-server/db1
# DATABASE_URL=postgres://staging-server/db1
# DATABASE_URL=postgres://dev-server/db1

# Other configuration (not managed by cycle_keys)
PORT=3000
DEBUG=false
```

### Format Rules
- ✅ **Active sets**: Uncommented lines
- ✅ **Inactive sets**: Commented with `#`
- ✅ **Logical grouping**: Parameters at same position form a set
- ✅ **Consistent ordering**: Maintain same order across all parameter groups

***

## 🎯 Example Scenarios

### Scenario 1: API Key Problem Recovery
```bash
# When your API key isn't working and you want to cycle to the next
python cycle_keys.py 
```

### Scenario 2: Environment-Specific Management
```bash
# Development environment
python cycle_keys.py dev.env --jump 2

# Production environment (check first, then switch)
python cycle_keys.py prod.env --show
python cycle_keys.py prod.env --random
```

### Scenario 3: Automated Failover
```bash
#!/bin/bash
# Simple failover script
if ! curl -f "https://api.example.com/health"; then
    echo "API down, cycling keys..."
    python cycle_keys.py --random
    systemctl restart api-service
fi
```

### Scenario 4: Windows Batch Integration
```batch
@echo off
REM Windows batch script for key cycling
cycle_keys --random
if %errorlevel% equ 0 (
    echo Key cycling successful
    net restart "My API Service"
) else (
    echo Key cycling failed
)
```

***

## 🖥️ Platform Compatibility

### ✅ Fully Supported Platforms

| Platform | Installer | Execution Method |
|----------|-----------|------------------|
| **Linux** | `install.sh` | `python3 cycle_keys.py` |
| **macOS** | `install.sh` | `python3 cycle_keys.py` |
| **Windows PowerShell** | `install.ps1` | `python cycle_keys.py` or `cycle_keys.bat` |
| **Windows WSL** | `install.sh` | `python3 cycle_keys.py` |
| **Git Bash** | `install.sh` | `python cycle_keys.py` |
| **Windows Terminal** | `install.ps1` | `python cycle_keys.py` or `cycle_keys.bat` |

### Execution Options
- **Direct Python**: `python cycle_keys.py [args]`
- **Windows Batch**: `cycle_keys [args]` (Windows only)
- **Shebang**: `./cycle_keys.py [args]` (Unix-like systems)

***

## 🔧 Troubleshooting

**Q: "Python not found" error on Windows**
```cmd
# Try these commands in order:
python --version
python3 --version  
py --version

# If none work, install Python from python.org
```

**Q: ".env file format issues"**
- Run `python cycle_keys.py --list` to see current format
- Use installer to generate template files
- Ensure all parameter groups have same number of entries

**Q: "Permission denied" on Unix systems**
```bash
chmod +x cycle_keys.py
# Or use: python3 cycle_keys.py
```

**Q: "Script not found" after installation**
```bash
# Check installation directory
which cycle_keys.py
# Add to PATH or use full path
export PATH=$PATH:/path/to/installation/directory
```

### Getting Help
- Run `python cycle_keys.py --help` for usage information
- Re-run installer to reconfigure settings
- Check the installation directory for all files
- Verify .env file format with `--list` command

***

## 🤝 Contributing

Contributions are welcome! Here's how you can help:

### Development Setup
```bash
# Clone the repository
git clone https://github.com/h0tp-ftw/api-key-cycler.git
cd api-key-cycler

# Test the script
python cycle_keys.py --help

# Test installers
bash install.sh  # Unix/Linux
# or
PowerShell install.ps1  # Windows
```

### Contributing Guidelines
1. **🍴 Fork** the repository
2. **🌿 Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **🧪 Test** your changes on multiple platforms if possible
4. **📝 Update** documentation if needed
5. **✅ Commit** your changes (`git commit -m 'Add amazing feature'`)
6. **🚀 Push** to your branch (`git push origin feature/amazing-feature`)
7. **🎯 Open** a Pull Request

***

## 🚨 Exit Codes

| Code | Description |
|------|-------------|
| `0` | Success - operation completed successfully |
| `1` | Error - configuration issue, file not found, invalid format, etc. |

***

## 📊 Project Stats

- **🐍 Python 3.7+** compatible
- **📦 Zero external dependencies** required
- **⚡ < 500 lines** of clean, documented code
- **🧪 Cross-platform tested** across multiple environments
- **📚 Comprehensive documentation** with real-world examples

***

## 🔗 Related Projects

- [python-dotenv](https://github.com/theskumar/python-dotenv) - Load environment variables from .env files
- [direnv](https://direnv.net/) - Environment variable management per directory  
- [dotenv-vault](https://www.dotenv.org/) - Encrypted .env file management

***

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

***

## 👨‍💻 Author

**Created by [@h0tp-ftw](https://github.com/h0tp-ftw)**, powered by *Claude 4.0 Sonnet* 

If this tool helped you manage your API keys more efficiently, consider giving it a ⭐!

***

## ⚠️ Responsible Usage Notice

**API Key Cycler is intended for responsible API key management only.**  
Do **not** use this tool to evade service rate limits, quotas, account restrictions, or engage in unauthorized, abusive, or illegal activities.

**Always follow the terms of service** and usage policies of your API providers.  
Use API Key Cycler for security best practices—such as safe key rotation, disaster recovery, and organizational credential management—not for circumventing provider limits or abusing access.

If you have questions about permitted usage, consult the relevant API documentation or service agreement.

***

*(Responsible API key usage helps protect your account, your service, and the wider community.)*

***

