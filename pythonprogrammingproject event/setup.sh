#!/usr/bin/env bash
#
# setup.sh — One-command build script for
# "Data Speaks. Can You Hear It?" — Python Econometrics Workshop
#
# Usage:
#   cd /path/to/project && chmod +x setup.sh && ./setup.sh
#
# What it does:
#   1. Checks Python 3 and pip
#   2. Installs Python packages (pandas, numpy, matplotlib, seaborn,
#      statsmodels, scikit-learn)
#   3. Generates datasets (salary_messy.csv, customer_segments.csv)
#   4. Runs all computations (clean data, groupby, clustering, regression)
#   5. Checks for Node.js / npx, installs @marp-team/marp-cli if missing
#   6. Builds SLIDES.md → /workspace/slides/SLIDES.html
#   7. Prints final status and file locations
#
set -e

# ── Colour helpers ──────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Colour

ok()   { echo -e "${GREEN}✓${NC} $1"; }
info() { echo -e "${CYAN}ℹ${NC}  $1"; }
warn() { echo -e "${YELLOW}⚠${NC}  $1"; }
err()  { echo -e "${RED}✗${NC}  $1"; }

# ── Resolve project root (script location) ──────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SLIDES_SRC="$SCRIPT_DIR/SLIDES.md"
SLIDES_OUT="/workspace/slides/SLIDES.html"
CSS_FILE="$SCRIPT_DIR/uu-theme.css"

echo ""
echo -e "${YELLOW}══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  Data Speaks. Can You Hear It? — Build Script${NC}"
echo -e "${YELLOW}══════════════════════════════════════════════════════════${NC}"
echo ""

# ── Step 0: Working directory ───────────────────────────────────
cd "$SCRIPT_DIR"
ok "Project root: $SCRIPT_DIR"

# ── Step 1: Check Python 3 ─────────────────────────────────────
info "Step 1: Checking Python 3 …"
if ! command -v python3 &> /dev/null; then
    err "python3 not found. Please install Python 3.9+."
    exit 1
fi
PY_VER=$(python3 --version 2>&1)
ok "Python: $PY_VER"

# ── Step 2: Check / Install pip ────────────────────────────────
info "Step 2: Checking pip …"
if ! command -v pip3 &> /dev/null && ! python3 -m pip --version &> /dev/null; then
    warn "pip not found — attempting to install …"
    python3 -m ensurepip --upgrade
fi
PIP_VER=$(python3 -m pip --version 2>&1 | head -1)
ok "pip: $PIP_VER"

# ── Step 3: Install Python packages ─────────────────────────────
info "Step 3: Installing Python packages …"
python3 -m pip install --quiet --upgrade pip
python3 -m pip install --quiet pandas numpy matplotlib seaborn statsmodels scikit-learn
ok "Python packages installed (pandas, numpy, matplotlib, seaborn, statsmodels, scikit-learn)"

# ── Step 4: Generate datasets (if needed) ──────────────────────
info "Step 4: Checking datasets …"
if [ ! -f "$SCRIPT_DIR/salary_messy.csv" ] || [ ! -f "$SCRIPT_DIR/customer_segments.csv" ]; then
    echo "  Generating synthetic datasets …"
    python3 "$SCRIPT_DIR/generate_datasets.py"
    ok "Datasets generated"
else
    ok "Datasets already exist — skipping generation"
fi

# ── Step 5: Run all computations ───────────────────────────────
info "Step 5: Running computations …"
python3 "$SCRIPT_DIR/compute_all.py"
if [ -f "$SCRIPT_DIR/computed_values.json" ]; then
    ok "Computations complete → computed_values.json written"
else
    warn "computed_values.json not found — check compute_all.py for errors"
fi

# ── Step 6: Build slides with Marp ──────────────────────────────
info "Step 6: Building slides …"

# Ensure output directory exists
mkdir -p "$(dirname "$SLIDES_OUT")"

# Check for Node.js / npx
if ! command -v npx &> /dev/null && ! command -v node &> /dev/null; then
    err "Node.js / npx not found. Please install Node.js (https://nodejs.org)."
    err "Slides build skipped — you can still run the workshop from the markdown."
else
    # Check if @marp-team/marp-cli is already available
    if npx --yes @marp-team/marp-cli --version &> /dev/null 2>&1; then
        ok "Marp CLI available"
    else
        info "Installing @marp-team/marp-cli …"
        npm install -g @marp-team/marp-cli
    fi

    # Build HTML from SLIDES.md
    echo "  Building: $SLIDES_SRC → $SLIDES_OUT"

    # Copy uu-theme.css alongside the slides so Marp can find it
    if [ -f "$CSS_FILE" ]; then
        cp "$CSS_FILE" "/workspace/slides/uu-theme.css"
    fi

    npx --yes @marp-team/marp-cli "$SLIDES_SRC" \
        --output "$SLIDES_OUT" \
        --html \
        --allow-local-files

    if [ -f "$SLIDES_OUT" ]; then
        ok "Slides built → $SLIDES_OUT"
    else
        err "Slides build failed — check Marp output above"
    fi
fi

# ── Step 7: Final status ───────────────────────────────────────
echo ""
echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✓ BUILD COMPLETE${NC}"
echo -e "${GREEN}══════════════════════════════════════════════════════════${NC}"
echo ""
echo "  Project:   $SCRIPT_DIR"
echo "  Datasets:"
echo "    • $SCRIPT_DIR/salary_messy.csv       (messy, for tidying)"
echo "    • $SCRIPT_DIR/salary_clean.csv        (cleaned, for prediction)"
echo "    • $SCRIPT_DIR/customer_segments.csv   (segments, for grouping)"
echo "  Computed:  $SCRIPT_DIR/computed_values.json"
echo "  Slides:    $SLIDES_OUT"
echo "  Theme:     $CSS_FILE"
echo ""
echo "  Run the workshop by opening SLIDES.html in a browser."
echo ""
