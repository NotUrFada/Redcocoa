#!/bin/bash
# Fixes "GeneratedAssetSymbols" and "Error closing" build issues by cleaning derived data
echo "Cleaning Xcode DerivedData for RedCocoa..."
rm -rf ~/Library/Developer/Xcode/DerivedData/RedCocoa-*
echo "Done. Reopen Xcode and build again (Product → Build)."
