# cycle_keys.ps1 - PowerShell Interactive Installer for cycle_keys.py
# Cross-platform PowerShell installer for Windows, macOS, and Linux

#Requires -Version 5.1

[CmdletBinding()]
param()

# Set strict mode for better error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Colors and formatting
$Colors = @{
    Header = "Blue"
    Success = "Green" 
    Warning = "Yellow"
    Error = "Red"
    Info = "Cyan"
    Prompt = "White"
}

function Write-ColorOutput {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [string]$Color = "White"
    )

    if ($Host.UI.SupportsVirtualTerminal -or $env:ConEmuANSI -eq "ON") {
        Write-Host $Message -ForegroundColor $Color
    } else {
        Write-Host $Message
    }
}

function Write-Header {
    param([string]$Title)
    Write-ColorOutput "🔄 $Title" -Color $Colors.Header
    Write-ColorOutput ("=" * ($Title.Length + 3)) -Color $Colors.Blue
}

function Write-Step {
    param([string]$StepName, [int]$StepNumber)
    Write-ColorOutput "`n$StepNumber. $StepName" -Color $Colors.Success
}

function Test-DirectoryPath {
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    try {
        # Expand environment variables and resolve path
        $ResolvedPath = [System.Environment]::ExpandEnvironmentVariables($Path)
        $ResolvedPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ResolvedPath)

        # Test if path exists or can be created
        if (Test-Path $ResolvedPath -PathType Container) {
            return $ResolvedPath
        } elseif (Test-Path (Split-Path $ResolvedPath -Parent)) {
            # Parent exists, we can create this directory
            New-Item -Path $ResolvedPath -ItemType Directory -Force | Out-Null
            return $ResolvedPath
        } else {
            # Try to create the full path
            New-Item -Path $ResolvedPath -ItemType Directory -Force | Out-Null
            return $ResolvedPath
        }
    } catch {
        return $null
    }
}

function Test-EnvFileFormat {
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        [Parameter(Mandatory)]
        [string[]]$ParameterGroups
    )

    if (-not (Test-Path $FilePath)) {
        return @{
            Exists = $false
            Valid = $false
            Issues = @("File does not exist")
        }
    }

    $Issues = @()
    $Content = Get-Content $FilePath -ErrorAction SilentlyContinue

    if (-not $Content) {
        return @{
            Exists = $true
            Valid = $false  
            Issues = @("File is empty or cannot be read")
        }
    }

    Write-ColorOutput "🔍 Validating .env file format..." -Color $Colors.Info

    $GroupIndex = 1
    foreach ($Group in $ParameterGroups) {
        Write-ColorOutput "Checking Group $GroupIndex`: $Group" -Color $Colors.Warning

        $Parameters = $Group -split ","
        $ParamCounts = @()

        foreach ($Param in $Parameters) {
            $Param = $Param.Trim()
            $Pattern = "^#?\s*$([regex]::Escape($Param))\s*="
            $Matches = $Content | Where-Object { $_ -match $Pattern }
            $Count = $Matches.Count
            $ParamCounts += $Count

            if ($Count -eq 0) {
                Write-ColorOutput "   ❌ No entries found for $Param" -Color $Colors.Error
                $Issues += "No entries found for parameter: $Param"
            } else {
                Write-ColorOutput "   ✅ Found $Count entries for $Param" -Color $Colors.Success
            }
        }

        # Check if all parameters have same count
        $FirstCount = $ParamCounts[0]
        $MismatchFound = $ParamCounts | Where-Object { $_ -ne $FirstCount }
        if ($MismatchFound) {
            Write-ColorOutput "   ❌ Mismatched entry counts in group $GroupIndex" -Color $Colors.Error
            $Issues += "Mismatched entry counts in group $GroupIndex`: $Group"
        }

        $GroupIndex++
    }

    return @{
        Exists = $true
        Valid = ($Issues.Count -eq 0)
        Issues = $Issues
    }
}

function Show-EnvFileFormat {
    param(
        [Parameter(Mandatory)]
        [string[]]$ParameterGroups
    )

    Write-ColorOutput "`n📄 Correct .env file format:" -Color $Colors.Info
    Write-Host ""

    $GroupIndex = 1
    foreach ($Group in $ParameterGroups) {
        Write-ColorOutput "# Group $GroupIndex`: $Group" -Color $Colors.Warning

        $Parameters = $Group -split ","

        # Show 3 example sets
        for ($SetNum = 1; $SetNum -le 3; $SetNum++) {
            Write-ColorOutput "# Set $SetNum" -Color "Magenta"

            foreach ($Param in $Parameters) {
                $Param = $Param.Trim()
                $ParamLower = $Param.ToLower()

                if ($SetNum -eq 1) {
                    # First set active (uncommented)
                    Write-Host "$Param=value${SetNum}_for_$ParamLower"
                } else {
                    # Other sets inactive (commented)
                    Write-Host "# $Param=value${SetNum}_for_$ParamLower"
                }
            }
            Write-Host ""
        }

        $GroupIndex++
        Write-Host ""
    }

    Write-ColorOutput "💡 Key Points:" -Color $Colors.Info
    Write-Host "• Active sets are uncommented"
    Write-Host "• Inactive sets are commented with #"
    Write-Host "• All parameters at the same position form a logical set"
    Write-Host "• Each group must have the same number of entries for all parameters"
}

function Get-UserChoice {
    param(
        [Parameter(Mandatory)]
        [string]$Prompt,
        [Parameter(Mandatory)]
        [string[]]$ValidChoices
    )

    do {
        $Input = Read-Host $Prompt
        $Input = $Input.Trim().ToUpper()

        if ($Input -in $ValidChoices) {
            return $Input
        } else {
            Write-ColorOutput "Invalid choice. Please enter one of: $($ValidChoices -join ', ')" -Color $Colors.Error
        }
    } while ($true)
}

# Main installer script starts here
Clear-Host

Write-Header "API Key Cycler by h0tp-ftw"
Write-ColorOutput "Platform: $($PSVersionTable.Platform -replace '^$', 'Windows')" -Color $Colors.Info
Write-ColorOutput "PowerShell Version: $($PSVersionTable.PSVersion)" -Color $Colors.Info
Write-Host ""

# Configuration variables
$InstallDir = ""
$ParameterGroups = @()
$EnvFilePath = ""
$DefaultMode = ""
$ScriptUrl = "https://raw.githubusercontent.com/YOUR_USERNAME/cycle_keys/main/cycle_keys.py"

# Step 1: Installation Directory
Write-Step "Installation Directory" 1
Write-Host "Where would you like to install cycle_keys.py?"
Write-ColorOutput "(Press Enter for current directory, or specify a path like C:\Scripts or ~\Documents\Scripts)" -Color $Colors.Info

do {
    $InstallDir = Read-Host "Installation directory"

    if ([string]::IsNullOrWhiteSpace($InstallDir)) {
        $InstallDir = Get-Location
        Write-ColorOutput "✅ Using current directory: $InstallDir" -Color $Colors.Success
        break
    }

    $ResolvedDir = Test-DirectoryPath $InstallDir
    if ($ResolvedDir) {
        $InstallDir = $ResolvedDir
        Write-ColorOutput "✅ Directory validated: $InstallDir" -Color $Colors.Success
        break
    } else {
        Write-ColorOutput "❌ Invalid directory. Please try again." -Color $Colors.Error
        Write-ColorOutput "   Examples: C:\Scripts, %USERPROFILE%\Scripts, ~\Documents\Scripts" -Color $Colors.Warning
    }
} while ($true)

# Step 2: Parameter Groups Configuration
Write-Step "Parameter Groups Configuration" 2
Write-Host "Define the parameter groups you want to cycle through."
Write-Host "Examples:"
Write-Host "• Single service: OPENAI_KEY,OPENAI_PROJECT"
Write-Host "• Multiple groups: GEMINI_API_KEY,VERTEXAI_PROJECT|OPENAI_KEY,OPENAI_PROJECT,OPENAI_LOCATION"
Write-Host "• Use comma (,) to separate parameters within a group"
Write-Host "• Use pipe (|) to separate different groups"

do {
    $ParameterGroupInput = Read-Host "Enter parameter groups"

    if ([string]::IsNullOrWhiteSpace($ParameterGroupInput)) {
        Write-ColorOutput "❌ Please enter at least one parameter group." -Color $Colors.Error
        continue
    }

    $ParameterGroups = $ParameterGroupInput -split "\|"

    Write-ColorOutput "`n📋 Configured groups:" -Color $Colors.Info
    for ($i = 0; $i -lt $ParameterGroups.Count; $i++) {
        Write-Host "   Group $($i + 1): $($ParameterGroups[$i])"
    }

    $Confirm = Get-UserChoice "Is this correct? (Y/N)" @("Y", "N")
    if ($Confirm -eq "Y") {
        break
    }
} while ($true)

# Step 3: Default .env File Path
Write-Step "Default .env File Path" 3
Write-Host "Specify the default .env file path that cycle_keys.py will use when run without arguments."
Write-ColorOutput "(Press Enter for '.env' in the same directory as the script)" -Color $Colors.Info

do {
    $EnvFilePath = Read-Host "Default .env file path"

    if ([string]::IsNullOrWhiteSpace($EnvFilePath)) {
        $EnvFilePath = ".env"
        Write-ColorOutput "✅ Using default: .env" -Color $Colors.Success
        break
    }

    # Resolve path if it contains environment variables
    $EnvFilePath = [System.Environment]::ExpandEnvironmentVariables($EnvFilePath)
    Write-ColorOutput "✅ Default .env file: $EnvFilePath" -Color $Colors.Success
    break
} while ($true)

# Step 4: Check existing .env file and format
Write-Step ".env File Validation" 4

# Determine the full path to the .env file
if ([System.IO.Path]::IsPathRooted($EnvFilePath)) {
    $TargetEnvFile = $EnvFilePath
} else {
    $TargetEnvFile = Join-Path $InstallDir $EnvFilePath
}

Write-ColorOutput "Checking for .env file at: $TargetEnvFile" -Color $Colors.Info

$EnvValidation = Test-EnvFileFormat $TargetEnvFile $ParameterGroups

if ($EnvValidation.Exists) {
    if ($EnvValidation.Valid) {
        Write-ColorOutput "✅ .env file format is correct!" -Color $Colors.Success
    } else {
        Write-ColorOutput "❌ .env file format has issues:" -Color $Colors.Error
        foreach ($Issue in $EnvValidation.Issues) {
            Write-ColorOutput "   • $Issue" -Color $Colors.Warning
        }

        Show-EnvFileFormat $ParameterGroups

        $Continue = Get-UserChoice "`nDo you want to continue anyway? (Y/N)" @("Y", "N")
        if ($Continue -eq "N") {
            Write-ColorOutput "Please fix your .env file format and run the installer again." -Color $Colors.Warning
            exit 1
        }
    }
} else {
    Write-ColorOutput "⚠️  .env file not found at: $TargetEnvFile" -Color $Colors.Warning
    Write-Host "The file will need to be created with the following format:"
    Show-EnvFileFormat $ParameterGroups
}

# Step 5: Default Cycling Mode
Write-Step "Default Cycling Mode" 5
Write-Host "Choose the default behavior when cycle_keys.py is run without mode arguments:"
Write-Host "1) Sequential cycling (1→2→3→1...)"
Write-Host "2) Random cycling (picks random non-current set)"

$ModeChoice = Get-UserChoice "Choose default mode (1 or 2)" @("1", "2")

switch ($ModeChoice) {
    "1" {
        $DefaultMode = "sequential"
        Write-ColorOutput "✅ Sequential cycling selected" -Color $Colors.Success
    }
    "2" {
        $DefaultMode = "random"
        Write-ColorOutput "✅ Random cycling selected" -Color $Colors.Success
    }
}

# Installation Summary
Write-Header "`nInstallation Summary"
Write-ColorOutput "Installation directory: $InstallDir" -Color $Colors.Info
Write-ColorOutput "Parameter groups: $($ParameterGroups -join ' | ')" -Color $Colors.Info
Write-ColorOutput "Default .env file: $EnvFilePath" -Color $Colors.Info
Write-ColorOutput "Default cycling mode: $DefaultMode" -Color $Colors.Info
Write-Host ""

$ProceedChoice = Get-UserChoice "Proceed with installation? (Y/N)" @("Y", "N")
if ($ProceedChoice -eq "N") {
    Write-ColorOutput "Installation cancelled." -Color $Colors.Warning
    exit 0
}

# Download and configure the script
Write-Header "`nInstalling cycle_keys.py"

try {
    # Change to installation directory
    Push-Location $InstallDir

    # Download the script
    Write-ColorOutput "📡 Downloading cycle_keys.py..." -Color $Colors.Info

    if (Get-Command Invoke-WebRequest -ErrorAction SilentlyContinue) {
        Invoke-WebRequest -Uri $ScriptUrl -OutFile "cycle_keys.py" -UseBasicParsing
    } elseif (Get-Command curl -ErrorAction SilentlyContinue) {
        & curl -o "cycle_keys.py" $ScriptUrl
    } else {
        throw "Neither Invoke-WebRequest nor curl is available for downloading."
    }

    if (-not (Test-Path "cycle_keys.py")) {
        throw "Failed to download cycle_keys.py"
    }

    # Configure the script
    Write-ColorOutput "🔧 Configuring cycle_keys.py..." -Color $Colors.Info

    $ScriptContent = Get-Content "cycle_keys.py" -Raw

    # Create Python parameter groups configuration
    $PythonGroups = @()
    foreach ($Group in $ParameterGroups) {
        $Parameters = $Group -split "," | ForEach-Object { "`"$($_.Trim())`"" }
        $PythonGroups += "    [$($Parameters -join ', ')]"
    }
    $PythonGroupsString = $PythonGroups -join ",`n"

    # Replace PARAMETER_GROUPS in the script
    $ScriptContent = $ScriptContent -replace "PARAMETER_GROUPS = \[.*?\]", "PARAMETER_GROUPS = [`n$PythonGroupsString`n]", [Text.RegularExpressions.RegexOptions]::Singleline

    # Replace default .env file path if not default
    if ($EnvFilePath -ne ".env") {
        $EscapedPath = $EnvFilePath -replace "\\", "\\\\"
        $ScriptContent = $ScriptContent -replace "default='\.env'", "default='$EscapedPath'"
    }

    # Add default random mode if selected
    if ($DefaultMode -eq "random") {
        $ScriptContent = $ScriptContent -replace "action='store_true'(?=.*--random)", "action='store_true', default=True"
    }

    # Save the configured script
    $ScriptContent | Out-File "cycle_keys.py" -Encoding UTF8

    Write-ColorOutput "✅ cycle_keys.py installed and configured!" -Color $Colors.Success

} catch {
    Write-ColorOutput "❌ Installation failed: $($_.Exception.Message)" -Color $Colors.Error
    exit 1
} finally {
    Pop-Location
}

# Create template .env file if requested
if (-not $EnvValidation.Exists) {
    Write-Host ""
    $CreateTemplate = Get-UserChoice "Create a template .env file? (Y/N)" @("Y", "N")

    if ($CreateTemplate -eq "Y") {
        Write-ColorOutput "📄 Creating template .env file..." -Color $Colors.Info

        try {
            # Ensure directory exists
            $EnvFileDir = Split-Path $TargetEnvFile -Parent
            if ($EnvFileDir -and -not (Test-Path $EnvFileDir)) {
                New-Item -Path $EnvFileDir -ItemType Directory -Force | Out-Null
            }

            # Generate template content
            $TemplateContent = @()
            $TemplateContent += "# cycle_keys.py configuration file"
            $TemplateContent += "# Generated by PowerShell installer on $(Get-Date)"
            $TemplateContent += ""

            $GroupIndex = 1
            foreach ($Group in $ParameterGroups) {
                $TemplateContent += "# Group $GroupIndex`: $Group"

                $Parameters = $Group -split ","

                # Create 3 example sets
                for ($SetNum = 1; $SetNum -le 3; $SetNum++) {
                    $TemplateContent += "# Set $SetNum"

                    foreach ($Param in $Parameters) {
                        $Param = $Param.Trim()
                        $ParamLower = $Param.ToLower()

                        if ($SetNum -eq 1) {
                            $TemplateContent += "$Param=your_${ParamLower}_value_$SetNum"
                        } else {
                            $TemplateContent += "# $Param=your_${ParamLower}_value_$SetNum"
                        }
                    }
                    $TemplateContent += ""
                }

                $GroupIndex++
            }

            $TemplateContent += "# Add your actual API keys and configuration values above"

            # Write template file
            $TemplateContent | Out-File $TargetEnvFile -Encoding UTF8

            Write-ColorOutput "✅ Template .env file created at: $TargetEnvFile" -Color $Colors.Success

        } catch {
            Write-ColorOutput "❌ Failed to create template file: $($_.Exception.Message)" -Color $Colors.Error
        }
    }
}

# Final instructions
Write-Header "`nInstallation Complete!"
Write-Host ""
Write-ColorOutput "Next steps:" -Color $Colors.Success
Write-Host "1. Edit your .env file with actual API keys"
Write-Host "2. Test the installation:"
Write-Host ""
Write-ColorOutput "Basic usage:" -Color $Colors.Info

$PythonCommand = if (Get-Command python -ErrorAction SilentlyContinue) { "python" } else { "python3" }
$ScriptPath = Join-Path $InstallDir "cycle_keys.py"

Write-Host "   $PythonCommand `"$ScriptPath`" --show     # Show current config"
Write-Host "   $PythonCommand `"$ScriptPath`" --list     # List all available sets"  
Write-Host "   $PythonCommand `"$ScriptPath`"            # Cycle keys"

Write-Host ""
Write-ColorOutput "🚀 Enjoy! - h0tp" -Color $Colors.Success

# Optional: Add to PATH suggestion
if ($InstallDir -ne (Get-Location)) {
    Write-Host ""
    Write-ColorOutput "💡 Tip: Consider adding $InstallDir to your PATH environment variable" -Color $Colors.Warning
    Write-ColorOutput "   for easier access from anywhere." -Color $Colors.Warning
}
