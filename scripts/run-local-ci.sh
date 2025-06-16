#!/bin/bash
# Script to run GitHub Actions locally using act
# This simulates the CI pipeline without consuming GitHub Actions minutes

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}BPC.DBRefresh Local CI Runner${NC}"
echo "================================"

# Check if act is installed
if ! command -v act &> /dev/null; then
    echo -e "${YELLOW}Installing act...${NC}"
    curl -s https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}Error: Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Parse command line arguments
WORKFLOW=""
PLATFORM="ubuntu-latest"
EVENT="push"

while [[ $# -gt 0 ]]; do
    case $1 in
        -w|--workflow)
            WORKFLOW="$2"
            shift 2
            ;;
        -p|--platform)
            PLATFORM="$2"
            shift 2
            ;;
        -e|--event)
            EVENT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -w, --workflow <file>    Specify workflow file (default: all workflows)"
            echo "  -p, --platform <os>      Platform to test on (default: ubuntu-latest)"
            echo "  -e, --event <event>      GitHub event to simulate (default: push)"
            echo "  -h, --help               Show this help message"
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            exit 1
            ;;
    esac
done

# Create act configuration if it doesn't exist
if [ ! -f .actrc ]; then
    echo -e "${YELLOW}Creating .actrc configuration...${NC}"
    cat > .actrc << EOF
# Default image for ubuntu-latest
-P ubuntu-latest=catthehacker/ubuntu:act-latest
-P ubuntu-22.04=catthehacker/ubuntu:act-22.04
-P ubuntu-20.04=catthehacker/ubuntu:act-20.04

# Windows images (note: these are Linux containers simulating Windows)
-P windows-latest=catthehacker/ubuntu:act-latest
-P windows-2022=catthehacker/ubuntu:act-latest
-P windows-2019=catthehacker/ubuntu:act-latest

# macOS images (note: these are Linux containers simulating macOS)
-P macos-latest=catthehacker/ubuntu:act-latest
-P macos-12=catthehacker/ubuntu:act-latest
-P macos-11=catthehacker/ubuntu:act-latest

# Default runner
--container-architecture linux/amd64
EOF
fi

# Run act with the specified options
echo -e "${GREEN}Running GitHub Actions locally...${NC}"
echo "Platform: $PLATFORM"
echo "Event: $EVENT"

if [ -n "$WORKFLOW" ]; then
    echo "Workflow: $WORKFLOW"
    act $EVENT -W "$WORKFLOW" -P "$PLATFORM"
else
    echo "Running all workflows..."
    act $EVENT -P "$PLATFORM"
fi

# Check exit code
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Local CI run completed successfully!${NC}"
else
    echo -e "${RED}✗ Local CI run failed!${NC}"
    exit 1
fi