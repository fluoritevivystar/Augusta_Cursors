#!/bin/bash

# Cursor Theme Compilation Script
# Version: 1.0
# Converts PNG sequences to XCursor and Windows cursor formats

set -e  # Exit on error

# Configuration
THEME_NAME="Augusta_Cursors"
THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PNG_DIR="${THEME_DIR}/build"
OUTPUT_DIR="${THEME_DIR}/release"
XCURSOR_DIR="${OUTPUT_DIR}/xcursor"
WINDOWS_DIR="${OUTPUT_DIR}/windows"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Create output directories
mkdir -p "${XCURSOR_DIR}/cursors"
mkdir -p "${WINDOWS_DIR}"

# Check for required tools
check_requirements() {
    echo -e "${YELLOW}Checking requirements...${NC}"
    
    if ! command -v magick &> /dev/null; then
        echo -e "${RED}Error: ImageMagick is not installed.${NC}"
        echo "Install with: sudo apt-get install imagemagick (Ubuntu/Debian)"
        echo "or: brew install imagemagick (macOS)"
        exit 1
    fi
    
    if ! command -v xcursorgen &> /dev/null; then
        echo -e "${RED}Error: xcursorgen is not installed.${NC}"
        echo "Install with: sudo apt-get install xcursorgen (Ubuntu/Debian)"
        exit 1
    fi
    
    echo -e "${GREEN}✓ All requirements satisfied${NC}"
}

# Create cursor configuration
create_config() {
    local cursor_name=$1
    local hotspots=$2
    local config_file="${THEME_DIR}/configs/${cursor_name}.cfg"
    
    mkdir -p "${THEME_DIR}/configs"
    
    # Parse hotspots (format: "x,y" or multiple "size:x,y" pairs)
    if [ -f "${config_file}" ]; then
        echo "${config_file}"
        return
    fi
    
    # Generate config with hotspots
    {
        echo "# ${cursor_name} cursor configuration"
        echo "# Format: <size> <x-hot> <y-hot> <filename> <delay>"
        
        IFS=' ' read -ra HOTSPOTS <<< "$hotspots"
        for hotspot in "${HOTSPOTS[@]}"; do
            if [[ $hotspot == *:* ]]; then
                # Size-specific hotspot
                size="${hotspot%%:*}"
                coords="${hotspot#*:}"
                x="${coords%,*}"
                y="${coords#*,}"
                echo "${size} ${x} ${y} build/${cursor_name}_${size}.png"
            else
                # Default hotspot for all sizes
                x="${hotspot%,*}"
                y="${hotspot#*,}"
                for size in 24 32 48 64 96; do
                    echo "${size} ${x} ${y} build/${cursor_name}_${size}.png"
                done
            fi
        done
    } > "${config_file}"
    
    echo "${config_file}"
}

# Resize PNGs to standard cursor sizes
resize_cursors() {
    local cursor_name=$1
    local source_png="${PNG_DIR}/${cursor_name}.png"
    
    if [ ! -f "${source_png}" ]; then
        # Try looking for sequence
        local first_frame=$(find "${PNG_DIR}" -name "${cursor_name}-*.png" | head -n1)
        if [ -n "${first_frame}" ]; then
            # Handle animated cursor
            process_animated "${cursor_name}"
            return
        else
            echo -e "${RED}Error: Source PNG not found for ${cursor_name}${NC}"
            return 1
        fi
    fi
    
    # Resize to standard cursor sizes
    local sizes=(24 32 48 64 96)
    for size in "${sizes[@]}"; do
        magick "${source_png}" -resize ${size}x${size} \
            "${THEME_DIR}/build/${cursor_name}_${size}.png"
    done
}

# Process animated cursor sequences
process_animated() {
    local cursor_name=$1
    local frame_pattern="${PNG_DIR}/${cursor_name}-*.png"
    local frames=($(ls -v ${frame_pattern} 2>/dev/null))
    
    if [ ${#frames[@]} -eq 0 ]; then
        echo -e "${RED}Error: No frames found for ${cursor_name}${NC}"
        return 1
    fi
    
    local sizes=(24 32 48 64 96)
    for size in "${sizes[@]}"; do
        mkdir -p "${THEME_DIR}/build/${cursor_name}_${size}"
        local frame_count=0
        
        for frame in "${frames[@]}"; do
            frame_count=$((frame_count + 1))
            magick "${frame}" -resize ${size}x${size} \
                "${THEME_DIR}/build/${cursor_name}_${size}/frame_${frame_count}.png"
        done
        
        # Create animated config
        local config_file="${THEME_DIR}/configs/${cursor_name}_${size}.cfg"
        {
            echo "# Animated ${cursor_name} cursor - size ${size}"
            echo "# Format: <size> <x-hot> <y-hot> <filename> <delay>"
            
            for ((i=1; i<=frame_count; i++)); do
                echo "${size} 0 0 ${cursor_name}_${size}/frame_${i}.png 50"
            done
        } > "${config_file}"
    done
}

# Build XCursor files
build_xcursor() {
    echo -e "${YELLOW}Building XCursor files...${NC}"
    
    local cursor_configs=(
        "left_ptr:0,0"
        "right_ptr:0,0"
        "hand:4,4"
        "watch:8,8"
        "xterm:4,8"
        "cross:8,8"
        "plus:8,8"
        "sb_v_double_arrow:8,8"
        "sb_h_double_arrow:8,8"
        "top_left_corner:8,8"
        "top_right_corner:8,8"
        "bottom_left_corner:8,8"
        "bottom_right_corner:8,8"
        "ibeam:8,9"
        "pencil:4,12"
        "move:8,8"
        "all-scroll:8,8"
        "not-allowed:8,8"
        "no-drop:8,8"
        "col-resize:8,8"
        "row-resize:8,8"
        "help:4,4"
        "wait:8,8"
        "text:8,8"
        "copy:8,8"
        "link:8,8"
    )
    
    for config in "${cursor_configs[@]}"; do
        IFS=':' read -r name hotspots <<< "$config"
        
        if [ -d "${PNG_DIR}/${name}" ] || [ -f "${PNG_DIR}/${name}.png" ]; then
            echo "  Building ${name}..."
            
            # Create config and resize images
            config_file=$(create_config "${name}" "${hotspots}")
            resize_cursors "${name}" || continue
            
            # Generate XCursor file
            xcursorgen "${config_file}" "${XCURSOR_DIR}/cursors/${name}"
            
            # Create symbolic links for aliases
            case "${name}" in
                "left_ptr")
                    ln -sf "left_ptr" "${XCURSOR_DIR}/cursors/default"
                    ln -sf "left_ptr" "${XCURSOR_DIR}/cursors/arrow"
                    ln -sf "left_ptr" "${XCURSOR_DIR}/cursors/top_left_arrow"
                    ;;
                "watch")
                    ln -sf "watch" "${XCURSOR_DIR}/cursors/wait"
                    ln -sf "watch" "${XCURSOR_DIR}/cursors/progress"
                    ;;
                "hand")
                    ln -sf "hand" "${XCURSOR_DIR}/cursors/hand1"
                    ln -sf "hand" "${XCURSOR_DIR}/cursors/hand2"
                    ln -sf "hand" "${XCURSOR_DIR}/cursors/pointer"
                    ;;
                "xterm")
                    ln -sf "xterm" "${XCURSOR_DIR}/cursors/text"
                    ln -sf "xterm" "${XCURSOR_DIR}/cursors/ibeam"
                    ;;
                "cross")
                    ln -sf "cross" "${XCURSOR_DIR}/cursors/crosshair"
                    ln -sf "cross" "${XCURSOR_DIR}/cursors/tcross"
                    ;;
                "sb_v_double_arrow")
                    ln -sf "sb_v_double_arrow" "${XCURSOR_DIR}/cursors/size_ver"
                    ln -sf "sb_v_double_arrow" "${XCURSOR_DIR}/cursors/ns-resize"
                    ln -sf "sb_v_double_arrow" "${XCURSOR_DIR}/cursors/row-resize"
                    ;;
                "sb_h_double_arrow")
                    ln -sf "sb_h_double_arrow" "${XCURSOR_DIR}/cursors/size_hor"
                    ln -sf "sb_h_double_arrow" "${XCURSOR_DIR}/cursors/ew-resize"
                    ln -sf "sb_h_double_arrow" "${XCURSOR_DIR}/cursors/col-resize"
                    ;;
            esac
        fi
    done
    
    echo -e "${GREEN}✓ XCursor files built successfully${NC}"
}

# Build Windows cursor files
build_windows() {
    echo -e "${YELLOW}Building Windows cursor files...${NC}"
    
    # Windows cursor naming conventions
    local cursor_map=(
        "left_ptr:arrow"
        "hand:hand"
        "watch:wait"
        "xterm:beam"
        "cross:cross"
        "sb_v_double_arrow:size_ns"
        "sb_h_double_arrow:size_we"
        "top_left_corner:sizenwse"
        "top_right_corner:sizenesw"
        "move:size_all"
        "help:help"
        "not-allowed:no"
        "copy:copy"
        "link:link"
    )
    
    for mapping in "${cursor_map[@]}"; do
        IFS=':' read -r xcursor_name win_name <<< "$mapping"
        
        if [ -f "${XCURSOR_DIR}/cursors/${xcursor_name}" ]; then
            echo "  Building ${win_name}.cur..."
            
            # Convert XCursor to Windows .cur format
            # Windows .cur files are typically 32x32 or 48x48
            local win_sizes=(32 48)
            
            for size in "${win_sizes[@]}"; do
                if [ -f "${THEME_DIR}/build/${xcursor_name}_${size}.png" ]; then
                    # Static cursor
                    magick "${THEME_DIR}/build/${xcursor_name}_${size}.png" \
                        -define icon:auto-resize="${size}" \
                        "${WINDOWS_DIR}/${win_name}.cur"
                    break
                fi
            done
            
            # Create .ani file for animated cursors
            if [ -d "${THEME_DIR}/build/${xcursor_name}_32" ]; then
                # Animated cursor
                local frame_files=($(ls -v "${THEME_DIR}/build/${xcursor_name}_32"/*.png))
                if [ ${#frame_files[@]} -gt 0 ]; then
                    # Create animated .ani file using ImageMagick
                    magick -delay 5 -loop 0 "${frame_files[@]}" \
                        "${WINDOWS_DIR}/${win_name}.ani"
                fi
            fi
        fi
    done
    
    echo -e "${GREEN}✓ Windows cursor files built successfully${NC}"
}

# Create theme index files
create_index_files() {
    echo -e "${YELLOW}Creating theme index files...${NC}"
    
    # Create index.theme for XCursor
    cat > "${XCURSOR_DIR}/index.theme" << EOF
[Icon Theme]
Name=${THEME_NAME}
Comment=Cursor theme
Example=left_ptr
EOF
    
    # Create Windows installer script
    cat > "${WINDOWS_DIR}/install.inf" << EOF
[Version]
Signature="\$Chicago\$"

[DefaultInstall]
CopyFiles = Cursor.Files
AddReg = Cursor.Reg

[Cursor.Files]
${THEME_NAME}.cursor

[Cursor.Reg]
HKCU,"Control Panel\Cursors\Schemes","${THEME_NAME}",0,"${THEME_NAME}.cursor"
EOF
    
    echo -e "${GREEN}✓ Index files created${NC}"
}

# Clean build directory
clean_build() {
    echo -e "${YELLOW}Cleaning build directory...${NC}"
    rm -rf "${THEME_DIR}/build"
    rm -rf "${OUTPUT_DIR}"
    echo -e "${GREEN}✓ Cleaned${NC}"
}

# Main build function
main() {
    echo -e "${GREEN}=== Cursor Theme Compiler v0.0.5 ===${NC}"
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --clean)
                clean_build
                exit 0
                ;;
            --help)
                echo "Usage: $0 [--clean] [--windows-only] [--xcursor-only]"
                exit 0
                ;;
            --windows-only)
                BUILD_XCURSOR=false
                BUILD_WINDOWS=true
                ;;
            --xcursor-only)
                BUILD_XCURSOR=true
                BUILD_WINDOWS=false
                ;;
        esac
        shift
    done
    
    # Set default build targets
    BUILD_XCURSOR=${BUILD_XCURSOR:-true}
    BUILD_WINDOWS=${BUILD_WINDOWS:-true}
    
    # Check requirements
    check_requirements
    
    # Create build directory
    mkdir -p "${THEME_DIR}/build"
    
    # Build cursors
    if [ "$BUILD_XCURSOR" = true ]; then
        build_xcursor
    fi
    
    if [ "$BUILD_WINDOWS" = true ]; then
        build_windows
    fi
    
    # Create index files
    create_index_files
    
    # Clean up build artifacts
    rm -rf "${THEME_DIR}/build"
    
    echo -e "${GREEN}✓ Build complete!${NC}"
    echo "Output directories:"
    echo "  XCursor: ${XCURSOR_DIR}"
    echo "  Windows: ${WINDOWS_DIR}"
}

# Run main function
main "$@"
