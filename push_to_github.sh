#!/bin/bash
# Run this from inside the R-Journal project root directory.
# It resets git history and pushes a clean initial commit to your GitHub remote.

set -e

echo "→ Removing old git history..."
rm -rf .git

echo "→ Initialising fresh repo..."
git init
git branch -m main

echo "→ Staging all files (respecting .gitignore)..."
git add .

echo "→ Creating initial commit..."
git commit -m "feat: initial release — R-Journal v1.0

Native macOS trading journal for Nifty 50 options traders.

Features:
- Trade log with CE/PE, emotion tagging, rule compliance
- Analytics dashboard: win rate, profit factor, expectancy,
  max drawdown, equity curve, emotion vs P&L, discipline score
- Calendar journal with per-day P&L heat map
- Daily notes: pre-market plan, mistakes, learnings
- Trading rules engine with live discipline alerts
- Local JSON persistence, debounced writes, sample data on first launch

Stack: SwiftUI · Swift Charts · MVVM · macOS 13+"

echo "→ Adding remote..."
git remote add origin https://github.com/ravii-k/R-Journal.git

echo "→ Pushing to GitHub..."
git push -u origin main --force

echo "✓ Done. Visit https://github.com/ravii-k/R-Journal"
