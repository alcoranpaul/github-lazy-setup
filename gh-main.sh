#!/bin/bash

# ============================================================
#  Generic GitHub Project Scaffolding Script
#  Reads from a YAML config file to create:
#  - GitHub repo
#  - Branches
#  - Labels
#  - Milestones
#  - Issues
#
#  Requirements:
#  - gh CLI installed and authenticated (gh auth login)
#  - yq installed (brew install yq / apt install yq)
#
#  Usage:
#  bash gh-scaffold.sh project.yaml
# ============================================================

set -e

# ── Dependency checks ──────────────────────────────────────────
if ! command -v gh &>/dev/null; then
  echo "❌ GitHub CLI (gh) is not installed."
  echo "   Install it: https://cli.github.com"
  exit 1
fi

if ! command -v yq &>/dev/null; then
  echo "❌ yq is not installed."
  echo "   Mac:   brew install yq"
  echo "   Linux: sudo apt install yq  OR  sudo snap install yq"
  exit 1
fi

if ! gh auth status &>/dev/null; then
  echo "❌ Not logged into GitHub CLI. Run: gh auth login"
  exit 1
fi

# ── Load YAML file ─────────────────────────────────────────────
YAML_FILE=${1:-"project.yaml"}

if [ ! -f "$YAML_FILE" ]; then
  echo "❌ YAML file not found: $YAML_FILE"
  echo "   Usage: bash gh-scaffold.sh project.yaml"
  exit 1
fi

echo "📄 Reading config from $YAML_FILE"

# ── Parse repo config ──────────────────────────────────────────
REPO_NAME=$(yq '.repo.name' "$YAML_FILE")
REPO_DESC=$(yq '.repo.description' "$YAML_FILE")
REPO_VISIBILITY=$(yq '.repo.visibility' "$YAML_FILE")
GITHUB_USER=$(gh api user --jq '.login')
FULL_REPO="$GITHUB_USER/$REPO_NAME"

echo ""
echo "🚀 Scaffolding: $FULL_REPO"
echo "============================================================"

# ── 1. CREATE REPO ─────────────────────────────────────────────
echo ""
echo "📁 Creating repository..."

if [ "$REPO_VISIBILITY" = "public" ]; then
  gh repo create "$REPO_NAME" \
    --public \
    --description "$REPO_DESC" \
    --clone
else
  gh repo create "$REPO_NAME" \
    --private \
    --description "$REPO_DESC" \
    --clone
fi

cd "$REPO_NAME"

# ── 2. BRANCHES ────────────────────────────────────────────────
echo ""
echo "🌿 Setting up branches..."

# Create README so main exists
cat > README.md << EOF
# $REPO_NAME

$REPO_DESC

---
*Scaffolded with gh-scaffold.sh*
EOF

git add README.md
git commit -m "chore: initial commit"
git push origin main

# Create additional branches from YAML
BRANCH_COUNT=$(yq '.branches | length' "$YAML_FILE")

for i in $(seq 0 $(( BRANCH_COUNT - 1 ))); do
  BRANCH=$(yq ".branches[$i]" "$YAML_FILE")
  if [ "$BRANCH" != "main" ]; then
    git checkout -b "$BRANCH"
    git push origin "$BRANCH"
    git checkout main
    echo "  ✔ Branch: $BRANCH"
  fi
done

echo "✅ Branches created"

# ── 3. LABELS ──────────────────────────────────────────────────
echo ""
echo "🏷  Creating labels..."

# Delete GitHub's default labels first for a clean slate
DEFAULT_LABELS=("bug" "documentation" "duplicate" "enhancement" "good first issue" "help wanted" "invalid" "question" "wontfix")
for label in "${DEFAULT_LABELS[@]}"; do
  gh label delete "$label" --repo "$FULL_REPO" --yes 2>/dev/null || true
done

LABEL_COUNT=$(yq '.labels | length' "$YAML_FILE")

for i in $(seq 0 $(( LABEL_COUNT - 1 ))); do
  NAME=$(yq ".labels[$i].name" "$YAML_FILE")
  COLOR=$(yq ".labels[$i].color" "$YAML_FILE")
  DESC=$(yq ".labels[$i].description" "$YAML_FILE")

  gh label create "$NAME" \
    --color "$COLOR" \
    --description "$DESC" \
    --repo "$FULL_REPO" 2>/dev/null || \
  gh label edit "$NAME" \
    --color "$COLOR" \
    --description "$DESC" \
    --repo "$FULL_REPO" 2>/dev/null || true

  echo "  ✔ Label: $NAME"
done

echo "✅ Labels created"

# ── 4. MILESTONES ──────────────────────────────────────────────
echo ""
echo "🎯 Creating milestones..."

MILESTONE_COUNT=$(yq '.milestones | length' "$YAML_FILE")

for i in $(seq 0 $(( MILESTONE_COUNT - 1 ))); do
  TITLE=$(yq ".milestones[$i].title" "$YAML_FILE")
  DESC=$(yq ".milestones[$i].description" "$YAML_FILE")
  DUE=$(yq ".milestones[$i].due_date // \"\"" "$YAML_FILE")

  if [ -n "$DUE" ] && [ "$DUE" != "null" ]; then
    gh api repos/$FULL_REPO/milestones --method POST \
      --field title="$TITLE" \
      --field description="$DESC" \
      --field due_on="${DUE}T00:00:00Z" > /dev/null
  else
    gh api repos/$FULL_REPO/milestones --method POST \
      --field title="$TITLE" \
      --field description="$DESC" > /dev/null
  fi

  echo "  ✔ Milestone: $TITLE"
done

echo "✅ Milestones created"

# ── 5. ISSUES ──────────────────────────────────────────────────
echo ""
echo "📋 Creating issues..."

ISSUE_COUNT=$(yq '.issues | length' "$YAML_FILE")

for i in $(seq 0 $(( ISSUE_COUNT - 1 ))); do
  TITLE=$(yq ".issues[$i].title" "$YAML_FILE")
  BODY=$(yq ".issues[$i].body" "$YAML_FILE")
  MILESTONE=$(yq ".issues[$i].milestone" "$YAML_FILE")
  
  # Build labels string (comma separated)
  LABEL_COUNT_I=$(yq ".issues[$i].labels | length" "$YAML_FILE")
  LABELS=""
  for j in $(seq 0 $(( LABEL_COUNT_I - 1 ))); do
    L=$(yq ".issues[$i].labels[$j]" "$YAML_FILE")
    if [ -z "$LABELS" ]; then
      LABELS="$L"
    else
      LABELS="$LABELS,$L"
    fi
  done

  # Build gh command
  CMD="gh issue create --title \"$TITLE\" --body \"$BODY\" --repo $FULL_REPO"
  
  if [ -n "$MILESTONE" ] && [ "$MILESTONE" != "null" ]; then
    CMD="$CMD --milestone \"$MILESTONE\""
  fi

  if [ -n "$LABELS" ]; then
    CMD="$CMD --label \"$LABELS\""
  fi

  eval $CMD > /dev/null
  echo "  ✔ Issue: $TITLE"
done

echo "✅ Issues created"

# ── DONE ───────────────────────────────────────────────────────
echo ""
echo "============================================================"
echo "✅ Project scaffolding complete!"
echo ""
echo "📌 Repo:       https://github.com/$FULL_REPO"
echo "📌 Issues:     https://github.com/$FULL_REPO/issues"
echo "📌 Milestones: https://github.com/$FULL_REPO/milestones"
echo "============================================================"