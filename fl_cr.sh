#!/bin/bash

# Doctor summary (to see all details, run flutter doctor -v):
# [√] Flutter (Channel stable, 3.24.5, on Microsoft Windows [Version 10.0.22631.4541], locale en-US)
# [√] Windows Version (Installed version of Windows is version 10 or higher)
# [√] Android toolchain - develop for Android devices (Android SDK version 35.0.0)
# [√] Chrome - develop for the web
# [√] Visual Studio - develop Windows apps (Visual Studio Community 2022 17.9.2)
# [√] Android Studio (version 2023.3)
# [√] VS Code (version 1.95.3)
# [√] Connected device (3 available)
# [√] Network resources

# • No issues found!

# ------------------------------------creating project-----------------------------------
# Prompt the user for the project name
read -p "Enter the project name: " PROJECT_NAME

# Validate project name
if [[ -z "$PROJECT_NAME" ]]; then
    echo "Error: Project name cannot be empty."
    exit 1
fi

# Prompt the user for the organization domain
read -p "Enter the organization domain (e.g., com.example): " ORG_DOMAIN

# Validate organization domain
if [[ -z "$ORG_DOMAIN" ]]; then
    echo "Error: Organization domain cannot be empty."
    exit 1
fi

# Create the Flutter project
echo "Creating Flutter project '$PROJECT_NAME' with organization domain '$ORG_DOMAIN'..."
flutter create "$PROJECT_NAME" --org="$ORG_DOMAIN" 

# Check if the project was created successfully
if [[ $? -eq 0 ]]; then
    echo "Flutter project '$PROJECT_NAME' created successfully!"
    echo "Navigate to the project directory using: cd $PROJECT_NAME"
else
    echo "Error: Failed to create Flutter project."
    exit 1
fi

# ------------------------------------removing comments from pubspec yaml file-----------------------------------
# Navigate to the project directory
cd "$PROJECT_NAME" || exit

# Check if pubspec.yaml exists
if [[ ! -f "pubspec.yaml" ]]; then
    echo "Error: pubspec.yaml file not found in the current directory."
    exit 1
fi

# Create a temporary file for storing changes
TEMP_FILE="pubspec_temp.yaml"

# Process the file, removing lines with comments up to line 60
awk 'NR <= 90 && /^ *#/ {next} {print}' pubspec.yaml > "$TEMP_FILE"

# Replace the original file with the processed file
mv "$TEMP_FILE" pubspec.yaml

echo "Comments removed from pubspec.yaml up to line 60."

# ------------------------------------adding dependencies-----------------------------------

# Add packages to the pubspec.yaml
echo "Adding packages to the Flutter project..."

PACKAGES=(
  "flutter_riverpod:^2.6.1"
#   "nb_utils:^7.0.7"
#   "flex_color_scheme:^8.0.2"
#   "firebase_core:^3.8.1"
#   "firebase_analytics:^11.3.6"
#   "firebase_crashlytics:^4.2.0"
#   "firebase_messaging:^15.1.6"
)

for PACKAGE in "${PACKAGES[@]}"; do
    flutter pub add "$PACKAGE"
done

# Check if packages were added successfully
if [[ $? -eq 0 ]]; then
    echo "Packages added successfully!"
else
    echo "Error: Failed to add packages."
    exit 1
fi

# Run flutter pub get to fetch the packages
flutter pub get

# ------------------------------------create a folder in the project called assets and subfolders----------------------
# Define the root folder and subfolders
ROOT_FOLDER="assets"
SUBFOLDERS=("anims" "fonts" "icon")

# Check if the root folder already exists
if [[ -d "$ROOT_FOLDER" ]]; then
    echo "The '$ROOT_FOLDER' folder already exists."
else
    # Create the root folder
    mkdir "$ROOT_FOLDER"
    echo "Created folder: $ROOT_FOLDER"
fi

# Create the subfolders
for SUBFOLDER in "${SUBFOLDERS[@]}"; do
    SUBFOLDER_PATH="$ROOT_FOLDER/$SUBFOLDER"
    if [[ -d "$SUBFOLDER_PATH" ]]; then
        echo "The folder '$SUBFOLDER_PATH' already exists."
    else
        mkdir "$SUBFOLDER_PATH"
        echo "Created subfolder: $SUBFOLDER_PATH"
    fi
done

echo "Assets Folder structure created successfully!"


# ------------------------------------add the assets folder to pubspec.yaml file----------------------

# Define the folders to be added
ASSETS=(
  "assets/"
  "assets/anims/"
  "assets/fonts/"
  "assets/icon/"
)

# Check if pubspec.yaml exists
if [[ ! -f "pubspec.yaml" ]]; then
    echo "Error: pubspec.yaml file not found in the current directory."
    exit 1
fi

# Check if 'flutter:' section exists
if ! grep -q '^flutter:' pubspec.yaml; then
    echo "Error: 'flutter:' section not found in pubspec.yaml."
    exit 1
fi

# Backup the original pubspec.yaml
cp pubspec.yaml pubspec_backup.yaml
echo "Backup created: pubspec_backup.yaml"

# Add assets to the 'flutter:' section
echo "Adding assets folders to pubspec.yaml..."
awk -v assets="${ASSETS[*]}" '
BEGIN {
    split(assets, assetList, " ")
    for (i in assetList) assetYaml[i] = "    - " assetList[i]
}
{
    print $0
    if ($0 ~ /^flutter:/) {
        inFlutterSection = 1
    }
    if (inFlutterSection && $0 ~ /^ *assets:/) {
        printed = 1
        for (i in assetYaml) {
            print assetYaml[i]
        }
    }
}
END {
    if (inFlutterSection && !printed) {
        print "  assets:"
        for (i in assetYaml) {
            print assetYaml[i]
        }
    }
}' pubspec.yaml > pubspec_temp.yaml

# Replace the original file with the updated file
mv pubspec_temp.yaml pubspec.yaml

echo "Assets folders successfully added to pubspec.yaml!"


# ------------------------------------copy fonts from the fonts directory to assets/fonts----------------------


# Define the source and destination directories
SOURCE_DIR="fonts"
DEST_DIR="$PROJECT_NAME/assets/fonts"

# Navigate back out of the project directory
cd .. || exit

# Check if the source 'fonts' folder exists
if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: 'fonts' directory not found in the current directory."
    exit 1
fi

# Check if the destination 'assets/fonts' folder exists in the Flutter project
if [[ ! -d "$DEST_DIR" ]]; then
    echo "Error: '$DEST_DIR' directory not found in the Flutter project."
    exit 1
fi

# Copy files from 'fonts' directory to 'assets/fonts'
echo "Copying files from '$SOURCE_DIR' to '$DEST_DIR'..."
cp -r "$SOURCE_DIR/"* "$DEST_DIR/"

# Navigate to the project directory
cd "$PROJECT_NAME" || exit
pwd

# Verify if the files were copied
if [[ $? -eq 0 ]]; then
    echo "Fonts files copied successfully!"
else
    echo "Error: Failed to copy font files."
    exit 1
fi