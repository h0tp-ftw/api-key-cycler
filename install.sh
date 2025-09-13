#!/bin/bash
# Advanced cycle_keys.py Interactive Installer
# This installer will set up cycle_keys.py with full configuration

set -e  # Exit on any error

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration variables
INSTALL_DIR=""
PARAMETER_GROUPS=""
ENV_FILE_PATH=""
DEFAULT_MODE=""
SCRIPT_URL="https://raw.githubusercontent.com/h0tp-ftw/api-key-cycler/main/cycle_keys.py"

echo -e "${BLUE}🔄 API Key Cycler by h0tp-ftw${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Function to validate directory path
validate_directory() {
    local dir="$1"
    if [[ -z "$dir" ]]; then
        return 1
    fi
    
    # Expand tilde to home directory
    dir="${dir/#\~/$HOME}"
    
    # Check if directory exists or can be created
    if [[ -d "$dir" ]]; then
        return 0
    elif mkdir -p "$dir" 2>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to validate .env file format
validate_env_format() {
    local env_file="$1"
    local -a param_groups=("${!2}")
    
    if [[ ! -f "$env_file" ]]; then
        return 2  # File doesn't exist
    fi
    
    local issues_found=0
    local group_index=1
    
    echo -e "${CYAN}🔍 Validating .env file format...${NC}"
    
    for group in "${param_groups[@]}"; do
        echo -e "${YELLOW}Checking Group $group_index: $group${NC}"
        
        # Split parameters by comma
        IFS=',' read -ra PARAMS <<< "$group"
        local param_counts=()
        
        for param in "${PARAMS[@]}"; do
            param=$(echo "$param" | xargs)  # Trim whitespace
            local count=$(grep -c "^#\?\s*$param\s*=" "$env_file" 2>/dev/null || echo 0)
            param_counts+=($count)
            
            if [[ $count -eq 0 ]]; then
                echo -e "   ${RED}❌ No entries found for $param${NC}"
                issues_found=1
            else
                echo -e "   ${GREEN}✅ Found $count entries for $param${NC}"
            fi
        done
        
        # Check if all parameters have same count
        local first_count=${param_counts[0]}
        for count in "${param_counts[@]}"; do
            if [[ $count -ne $first_count ]]; then
                echo -e "   ${RED}❌ Mismatched entry counts in group $group_index${NC}"
                issues_found=1
                break
            fi
        done
        
        ((group_index++))
    done
    
    return $issues_found
}

# Function to show correct .env format
show_env_format() {
    local -a param_groups=("${!1}")
    
    echo -e "${CYAN}📄 Correct .env file format:${NC}"
    echo ""
    
    local group_index=1
    for group in "${param_groups[@]}"; do
        echo -e "${YELLOW}# Group $group_index: $group${NC}"
        
        # Split parameters by comma
        IFS=',' read -ra PARAMS <<< "$group"
        
        # Show 3 example sets
        for set_num in 1 2 3; do
            echo -e "${PURPLE}# Set $set_num${NC}"
            for param in "${PARAMS[@]}"; do
                param=$(echo "$param" | xargs)  # Trim whitespace
                
                if [[ $set_num -eq 1 ]]; then
                    # First set active (uncommented)
                    echo "${param}=value${set_num}_for_${param,,}"
                else
                    # Other sets inactive (commented)
                    echo "# ${param}=value${set_num}_for_${param,,}"
                fi
            done
            echo ""
        done
        
        ((group_index++))
        echo ""
    done
    
    echo -e "${CYAN}💡 Key Points:${NC}"
    echo "• Active sets are uncommented"
    echo "• Inactive sets are commented with #"
    echo "• All parameters at the same position form a logical set"
    echo "• Each group must have the same number of entries for all parameters"
}

# Step 1: Installation Directory
echo -e "${GREEN}📁 Step 1: Installation Directory${NC}"
echo "Where would you like to install cycle_keys.py?"
echo "(Press Enter for current directory, or specify a path like ~/scripts)"

while true; do
    read -p "Installation directory: " INSTALL_DIR
    
    # Default to current directory if empty
    if [[ -z "$INSTALL_DIR" ]]; then
        INSTALL_DIR="."
        echo -e "${GREEN}✅ Using current directory${NC}"
        break
    fi
    
    if validate_directory "$INSTALL_DIR"; then
        INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"  # Expand tilde
        echo -e "${GREEN}✅ Directory validated: $INSTALL_DIR${NC}"
        break
    else
        echo -e "${RED}❌ Invalid directory. Please try again.${NC}"
    fi
done

# Step 2: Parameter Groups Configuration
echo ""
echo -e "${GREEN}🔧 Step 2: Parameter Groups Configuration${NC}"
echo "Define the parameter groups you want to cycle through."
echo "Examples:"
echo "• Single service: OPENAI_KEY,OPENAI_PROJECT"
echo "• Multiple groups: GEMINI_API_KEY,VERTEXAI_PROJECT|OPENAI_KEY,OPENAI_PROJECT,OPENAI_LOCATION"
echo "• Use comma (,) to separate parameters within a group"
echo "• Use pipe (|) to separate different groups"

declare -a PARAM_GROUPS_ARRAY

while true; do
    read -p "Enter parameter groups: " PARAMETER_GROUPS
    
    if [[ -z "$PARAMETER_GROUPS" ]]; then
        echo -e "${RED}❌ Please enter at least one parameter group.${NC}"
        continue
    fi
    
    # Split by pipe and validate
    IFS='|' read -ra PARAM_GROUPS_ARRAY <<< "$PARAMETER_GROUPS"
    
    echo -e "${CYAN}📋 Configured groups:${NC}"
    # FIXED: Remove 'local' keyword here since we're not inside a function
    group_index=1
    for group in "${PARAM_GROUPS_ARRAY[@]}"; do
        echo "   Group $group_index: $group"
        ((group_index++))
    done
    
    read -p "Is this correct? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        break
    fi
done

# Step 3: Default .env File Path
echo ""
echo -e "${GREEN}📄 Step 3: Default .env File Path${NC}"
echo "Specify the default .env file path that cycle_keys.py will use when run without arguments."
echo "(Press Enter for '.env' in the same directory as the script)"

while true; do
    read -p "Default .env file path: " ENV_FILE_PATH
    
    if [[ -z "$ENV_FILE_PATH" ]]; then
        ENV_FILE_PATH=".env"
        echo -e "${GREEN}✅ Using default: .env${NC}"
        break
    fi
    
    # Expand tilde if present
    ENV_FILE_PATH="${ENV_FILE_PATH/#\~/$HOME}"
    echo -e "${GREEN}✅ Default .env file: $ENV_FILE_PATH${NC}"
    break
done

# Step 4: Check existing .env file and format
echo ""
echo -e "${GREEN}🔍 Step 4: .env File Validation${NC}"

# Check if the .env file exists in the target location
target_env_file="$ENV_FILE_PATH"
if [[ ! "$ENV_FILE_PATH" = /* ]]; then
    # Relative path, make it relative to install directory
    target_env_file="$INSTALL_DIR/$ENV_FILE_PATH"
fi

if [[ -f "$target_env_file" ]]; then
    echo -e "${CYAN}📄 Found existing .env file: $target_env_file${NC}"
    
    if validate_env_format "$target_env_file" PARAM_GROUPS_ARRAY[@]; then
        echo -e "${GREEN}✅ .env file format is correct!${NC}"
    else
        echo -e "${RED}❌ .env file format has issues.${NC}"
        echo ""
        show_env_format PARAM_GROUPS_ARRAY[@]
        echo ""
        read -p "Do you want to continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Please fix your .env file format and run the installer again.${NC}"
            exit 1
        fi
    fi
else
    echo -e "${YELLOW}⚠️  .env file not found at: $target_env_file${NC}"
    echo "The file will need to be created with the following format:"
    echo ""
    show_env_format PARAM_GROUPS_ARRAY[@]
    echo ""
fi

# Step 5: Default Cycling Mode
echo ""
echo -e "${GREEN}🎯 Step 5: Default Cycling Mode${NC}"
echo "Choose the default behavior when cycle_keys.py is run without mode arguments:"
echo "1) Sequential cycling (1→2→3→1...)"
echo "2) Random cycling (picks random non-current set)"

while true; do
    read -p "Choose default mode (1 or 2): " -n 1 -r DEFAULT_MODE
    echo
    
    case $DEFAULT_MODE in
        1)
            DEFAULT_MODE="sequential"
            echo -e "${GREEN}✅ Sequential cycling selected${NC}"
            break
            ;;
        2)
            DEFAULT_MODE="random"
            echo -e "${GREEN}✅ Random cycling selected${NC}"
            break
            ;;
        *)
            echo -e "${RED}❌ Please enter 1 or 2.${NC}"
            ;;
    esac
done

# Summary and confirmation
echo ""
echo -e "${BLUE}📋 Installation Summary${NC}"
echo -e "${BLUE}======================${NC}"
echo -e "Installation directory: ${CYAN}$INSTALL_DIR${NC}"
echo -e "Parameter groups: ${CYAN}$PARAMETER_GROUPS${NC}"
echo -e "Default .env file: ${CYAN}$ENV_FILE_PATH${NC}"
echo -e "Default cycling mode: ${CYAN}$DEFAULT_MODE${NC}"
echo ""

read -p "Proceed with installation? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Installation cancelled.${NC}"
    exit 0
fi

# Download and configure the script
echo ""
echo -e "${BLUE}🚀 Installing cycle_keys.py...${NC}"

cd "$INSTALL_DIR"

# Download the script
echo -e "${CYAN}📡 Downloading cycle_keys.py...${NC}"
if command -v curl >/dev/null 2>&1; then
    curl -o cycle_keys.py "$SCRIPT_URL" || {
        echo -e "${RED}❌ Failed to download with curl${NC}"
        exit 1
    }
elif command -v wget >/dev/null 2>&1; then
    wget -O cycle_keys.py "$SCRIPT_URL" || {
        echo -e "${RED}❌ Failed to download with wget${NC}"
        exit 1
    }
else
    echo -e "${RED}❌ Neither curl nor wget is available!${NC}"
    echo "Please install curl or wget first."
    exit 1
fi

# Make executable
chmod +x cycle_keys.py

# Configure the script
echo -e "${CYAN}🔧 Configuring cycle_keys.py...${NC}"

# Create the parameter groups configuration for Python
python_groups=""
group_index=1
for group in "${PARAM_GROUPS_ARRAY[@]}"; do
    if [[ $group_index -gt 1 ]]; then
        python_groups+=",\n    "
    fi
    
    # Convert comma-separated parameters to Python list format
    python_list="["
    IFS=',' read -ra PARAMS <<< "$group"
    param_index=1
    for param in "${PARAMS[@]}"; do
        param=$(echo "$param" | xargs)  # Trim whitespace
        if [[ $param_index -gt 1 ]]; then
            python_list+=", "
        fi
        python_list+="\"$param\""
        ((param_index++))
    done
    python_list+="]"
    
    python_groups+="$python_list"
    ((group_index++))
done

# Update the script with configurations
temp_file=$(mktemp)

# Replace PARAMETER_GROUPS
sed "s|PARAMETER_GROUPS = \[.*\]|PARAMETER_GROUPS = [\n    $python_groups\n]|g" cycle_keys.py > "$temp_file"

# Replace default .env file path (if not default)
if [[ "$ENV_FILE_PATH" != ".env" ]]; then
    sed -i "s|default='.env'|default='$ENV_FILE_PATH'|g" "$temp_file"
fi

# Add default random mode if selected
if [[ "$DEFAULT_MODE" == "random" ]]; then
    # Add random as default in the argument parser
    sed -i "s|action='store_true'|action='store_true', default=True|g" "$temp_file"
fi

mv "$temp_file" cycle_keys.py
chmod +x cycle_keys.py

echo -e "${GREEN}✅ cycle_keys.py installed and configured!${NC}"

# Create a simple .env template if requested
if [[ ! -f "$target_env_file" ]]; then
    echo ""
    read -p "Create a template .env file? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${CYAN}📄 Creating template .env file...${NC}"
        
        # Determine the correct path for .env file
        if [[ "$ENV_FILE_PATH" = /* ]]; then
            template_env_file="$ENV_FILE_PATH"
        else
            template_env_file="$INSTALL_DIR/$ENV_FILE_PATH"
        fi
        
        # Create directories if needed
        mkdir -p "$(dirname "$template_env_file")"
        
        # Generate template content
        {
            echo "# cycle_keys.py configuration file"
            echo "# Generated by installer on $(date)"
            echo ""
            
            # FIXED: Remove 'local' keyword here since we're not inside a function
            group_index=1
            for group in "${PARAM_GROUPS_ARRAY[@]}"; do
                echo "# Group $group_index: $group"
                
                IFS=',' read -ra PARAMS <<< "$group"
                
                # Create 3 example sets
                for set_num in 1 2 3; do
                    echo "# Set $set_num"
                    for param in "${PARAMS[@]}"; do
                        param=$(echo "$param" | xargs)
                        
                        if [[ $set_num -eq 1 ]]; then
                            echo "${param}=your_${param,,}_value_${set_num}"
                        else
                            echo "# ${param}=your_${param,,}_value_${set_num}"
                        fi
                    done
                    echo ""
                done
                
                ((group_index++))
            done
            
            echo "# Add your actual API keys and configuration values above"
        } > "$template_env_file"
        
        echo -e "${GREEN}✅ Template .env file created at: $template_env_file${NC}"
    fi
fi

# Final instructions
echo ""
echo -e "${BLUE}🎉 Installation Complete!${NC}"
echo -e "${BLUE}======================${NC}"
echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. Edit your .env file with actual API keys"
if [[ "$INSTALL_DIR" != "." ]]; then
    echo "2. Add $INSTALL_DIR to your PATH or use full path to run"
fi
echo "3. Test the installation:"
echo ""
echo -e "${CYAN}Basic usage:${NC}"
if [[ "$INSTALL_DIR" == "." ]]; then
    echo "   python cycle_keys.py --show     # Show current config"
    echo "   python cycle_keys.py --list     # List all available sets"
    echo "   python cycle_keys.py            # Cycle keys"
else
    echo "   python $INSTALL_DIR/cycle_keys.py --show     # Show current config"
    echo "   python $INSTALL_DIR/cycle_keys.py --list     # List all available sets"
    echo "   python $INSTALL_DIR/cycle_keys.py            # Cycle keys"
fi
echo ""
echo -e "${GREEN}🚀 Enjoy! - h0tp${NC}"
