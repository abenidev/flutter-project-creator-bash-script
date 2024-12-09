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

# Define the path to the dependencies file
DEPENDENCIES_FILE="../dependencies.txt"

# Check if the dependencies file exists
if [[ ! -f "$DEPENDENCIES_FILE" ]]; then
    echo "Error: 'dependencies.txt' file not found in the script's directory."
    exit 1
fi

# Check if pubspec.yaml exists
if [[ ! -f "pubspec.yaml" ]]; then
    echo "Error: 'pubspec.yaml' file not found in the current directory."
    exit 1
fi

# Backup the original pubspec.yaml
cp pubspec.yaml pubspec_backup.yaml
echo "Backup created: pubspec_backup.yaml"

# Add dependencies to pubspec.yaml
echo "Adding dependencies to pubspec.yaml..."
awk -v deps_file="$DEPENDENCIES_FILE" '
BEGIN {
    while ((getline dep < deps_file) > 0) {
        # Trim leading and trailing whitespace
        gsub(/^[ \t]+|[ \t]+$/, "", dep)
        if (dep != "") {
            deps_list[dep] = dep
        }
    }
}
{
    print $0
    if ($0 ~ /^dependencies:/) {
        for (dep in deps_list) {
            print "  " dep
        }
        printed = 1
    }
}
END {
    if (!printed) {
        print "dependencies:"
        for (dep in deps_list) {
            print "  " dep
        }
    }
}' pubspec.yaml > pubspec_temp.yaml

# Replace the original file with the updated file
mv pubspec_temp.yaml pubspec.yaml

echo "Dependencies successfully added to pubspec.yaml!"

# ------------------------------------adding dev dependencies----------------------
# Define the source and target files
DEV_DEPENDENCIES_FILE="../dev_dependencies.txt"
PUBSPEC_FILE="pubspec.yaml"

# Check if dev_dependencies.txt exists
if [[ ! -f "$DEV_DEPENDENCIES_FILE" ]]; then
    echo "Error: '$DEV_DEPENDENCIES_FILE' file not found in the current directory."
    exit 1
fi

# Check if pubspec.yaml exists
if [[ ! -f "$PUBSPEC_FILE" ]]; then
    echo "Error: '$PUBSPEC_FILE' file not found in the current directory."
    exit 1
fi

# Prepare the lines to add
echo "Reading dependencies from '$DEV_DEPENDENCIES_FILE'..."
DEPENDENCIES=$(cat "$DEV_DEPENDENCIES_FILE")

# Check if dev_dependencies section exists in pubspec.yaml
if grep -q "dev_dependencies:" "$PUBSPEC_FILE"; then
    echo "Adding dependencies to existing 'dev_dependencies' section in '$PUBSPEC_FILE'..."
    
    # Add each dependency under dev_dependencies
    while read -r LINE; do
        # Ensure the line is not empty
        if [[ -n "$LINE" ]]; then
            sed -i "/dev_dependencies:/a \  $LINE" "$PUBSPEC_FILE"
        fi
    done <<< "$DEPENDENCIES"
else
    echo "No 'dev_dependencies' section found. Adding it to '$PUBSPEC_FILE'..."
    
    # Add dev_dependencies section at the end of the file
    echo "" >> "$PUBSPEC_FILE"
    echo "dev_dependencies:" >> "$PUBSPEC_FILE"
    while read -r LINE; do
        # Ensure the line is not empty
        if [[ -n "$LINE" ]]; then
            echo "  $LINE" >> "$PUBSPEC_FILE"
        fi
    done <<< "$DEPENDENCIES"
fi

echo "Dev dependencies successfully added to '$PUBSPEC_FILE'!"


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

# ------------------------------------add the fonts to pubspec.yaml file----------------------

# Define the target file
TARGET_FILE="pubspec.yaml"

# Define the lines to append
LINES=(
    ""
    "  fonts:"
    "    - family: Poppins"
    "      fonts:"
    "        - asset: assets/fonts/Poppins-Regular.ttf"
    "        - asset: assets/fonts/Poppins-Italic.ttf"
    "          style: italic"
    "    - family: Madimi"
    "      fonts:"
    "        - asset: assets/fonts/MadimiOne-Regular.ttf"
    ""
    "# native_splash"
    "# dart run flutter_native_splash:create"
    "flutter_native_splash:"
    "  color: '#03346E'"
    "  color_dark: '#201E43'"
    "  android_12:"
    "    color: '#03346E'"
    "    color_dark: '#201E43'"
)

# Check if the target file exists
if [[ ! -f "$TARGET_FILE" ]]; then
    echo "Error: '$TARGET_FILE' file not found in the current directory."
    exit 1
fi

# Append the lines to the file
echo "Appending font configuration to '$TARGET_FILE'..."
for LINE in "${LINES[@]}"; do
    echo "$LINE" >> "$TARGET_FILE"
done

echo "Font configuration successfully added to '$TARGET_FILE'!"

# ------------------------------------copy fonts from the fonts directory to assets/fonts----------------------

# Define the source and destination directories
SOURCE_DIR="../fonts"
DEST_DIR="assets/fonts"

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

# Verify if the files were copied
if [[ $? -eq 0 ]]; then
    echo "Fonts files copied successfully!"
else
    echo "Error: Failed to copy font files."
    exit 1
fi

# ------------------------------------creating sub directories under the lib folder----------------------

# Define the target directory and the new subdirectories to create
TARGET_DIR="lib"
SUBDIRS=("constants" "helpers" "models" "providers" "screens" "utils" "widgets")

# Check if the target directory exists
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: The 'lib' directory does not exist in the current project."
    exit 1
fi

# Create the subdirectories
echo "Creating directories under '$TARGET_DIR'..."
for SUBDIR in "${SUBDIRS[@]}"; do
    SUBDIR_PATH="$TARGET_DIR/$SUBDIR"
    if [[ -d "$SUBDIR_PATH" ]]; then
        echo "Directory '$SUBDIR_PATH' already exists. Skipping."
    else
        mkdir "$SUBDIR_PATH"
        echo "Created directory: $SUBDIR_PATH"
    fi
done

echo "All specified directories have been created successfully!"

# ------------------------------------modify the read me file----------------------

# Define the additional lines to add to README.md
NEW_LINES=(
    "## Table of Contents"
    "1. [Introduction](#introduction)"
    "2. [Features](#features)"
    "3. [Installation](#installation)"
    "4. [Usage](#usage)"
    "5. [Contributing](#contributing)"
    "6. [License](#license)"
)

# Check if README.md exists
if [[ ! -f "README.md" ]]; then
    echo "Error: 'README.md' file not found in the current directory."
    exit 1
fi

# Backup the original README.md
cp README.md README_backup.md
echo "Backup created: README_backup.md"

# Read the first line of README.md
FIRST_LINE=$(head -n 1 README.md)

# Write the first line back to README.md
echo "$FIRST_LINE" > README.md

# Append the new lines to README.md
echo "Adding new content to README.md..."
for LINE in "${NEW_LINES[@]}"; do
    echo "$LINE" >> README.md
done

echo "README.md successfully updated!" 

# ------------------------------------add files to the lib/constants directory----------------------

# Define the target directory and the files to be created
TARGET_DIR="lib/constants"
FILES=(
    "bools.dart"
    "colors.dart"
    "app_consts.dart"
    "dates.dart"
    "nums.dart"
    "strings.dart"
    "styles.dart"
    "hive_consts.dart"
    "shared_prefs_consts.dart"
)

# Check if the target directory exists
if [[ ! -d "$TARGET_DIR" ]]; then
    echo "Error: The 'lib/constants' directory does not exist."
    echo "Creating 'lib/constants' directory..."
    mkdir -p "$TARGET_DIR"
    echo "'lib/constants' directory created."
fi

# Create the specified files
echo "Creating files under '$TARGET_DIR'..."
for FILE in "${FILES[@]}"; do
    FILE_PATH="$TARGET_DIR/$FILE"
    if [[ -f "$FILE_PATH" ]]; then
        echo "File '$FILE_PATH' already exists. Skipping."
    else
        touch "$FILE_PATH"
        echo "Created file: $FILE_PATH"
    fi
done

echo "All specified files have been created successfully!"

# ------------------------------------add the required lines to lib/constants/nums.dart file----------------------

# Define the target file
TARGET_FILE="lib/constants/nums.dart"

# Define the lines to add
LINES=(
    "//ad"
    "const int kAdShowDelayInSeconds = 40;"
    "const int kClicksDelayCountForAd = 3;"
)

# Check if the target directory exists
if [[ ! -d "lib/constants" ]]; then
    echo "Error: The 'lib/constants' directory does not exist."
    echo "Please create the directory structure first."
    exit 1
fi

# Create the target file if it doesn't exist
if [[ ! -f "$TARGET_FILE" ]]; then
    echo "File '$TARGET_FILE' does not exist. Creating it..."
    touch "$TARGET_FILE"
    echo "Created file: $TARGET_FILE"
fi

# Append the lines to the file
echo "Adding lines to '$TARGET_FILE'..."
for LINE in "${LINES[@]}"; do
    echo "$LINE" >> "$TARGET_FILE"
done

echo "Lines successfully added to '$TARGET_FILE'!"

# ------------------------------------add the required lines to lib/constants/strings.dart file----------------------

# Define the target file
TARGET_FILE="lib/constants/strings.dart"

# Define the lines to add
LINES=(
    "const String kStrCommonError = 'Something went wrong, please reopen the application.';"
    "//TODO: fill in these informations"
    "const String supportEmail = 'samethdevs@gmail.com';"
    "const String appPackageName = '';"
    "const String appName = '';"
    "const List<String> appFeedbackReciepients = [supportEmail];"
    "const String websiteAddress = 'https://abeni.dev/';"
)

# Check if the target directory exists
if [[ ! -d "lib/constants" ]]; then
    echo "Error: The 'lib/constants' directory does not exist."
    echo "Please create the directory structure first."
    exit 1
fi

# Create the target file if it doesn't exist
if [[ ! -f "$TARGET_FILE" ]]; then
    echo "File '$TARGET_FILE' does not exist. Creating it..."
    touch "$TARGET_FILE"
    echo "Created file: $TARGET_FILE"
fi

# Append the lines to the file
echo "Adding lines to '$TARGET_FILE'..."
for LINE in "${LINES[@]}"; do
    echo "$LINE" >> "$TARGET_FILE"
done

echo "Lines successfully added to '$TARGET_FILE'!"



# ------------------------------------add the required lines to lib/constants/styles.dart file----------------------

# Define the target file
TARGET_FILE="lib/constants/styles.dart"

# Define the lines to add
LINES=(
    "import 'package:flutter/material.dart';"
    "import 'package:flutter_screenutil/flutter_screenutil.dart';"
    "TextStyle kAppBarTitleStyle = TextStyle(fontSize: 19.3.sp);"
)

# Check if the target directory exists
if [[ ! -d "lib/constants" ]]; then
    echo "Error: The 'lib/constants' directory does not exist."
    echo "Please create the directory structure first."
    exit 1
fi

# Create the target file if it doesn't exist
if [[ ! -f "$TARGET_FILE" ]]; then
    echo "File '$TARGET_FILE' does not exist. Creating it..."
    touch "$TARGET_FILE"
    echo "Created file: $TARGET_FILE"
fi

# Append the lines to the file
echo "Adding lines to '$TARGET_FILE'..."
for LINE in "${LINES[@]}"; do
    echo "$LINE" >> "$TARGET_FILE"
done

echo "Lines successfully added to '$TARGET_FILE'!"




# ------------------------------------add the required lines to lib/constants/shared_prefs_consts.dart file----------------------

# Define the target file
TARGET_FILE="lib/constants/shared_prefs_consts.dart"

# Define the lines to add
LINES=(
    "const String kIsIntroShownKey = 'isIntroShown';"
    "const String kIsFirebaseInited = 'kIsFirebaseInited';"
    "const String kIsPremiumModalShown = 'kIsPremiumModalShown';"
    "const String kAdClickCountPref = 'kAdClickCountPref';"
    "const String kLastAdViewTimestamp = 'kLastAdViewTimestamp';"
    "const String kLastAdClickTimestamp = 'kLastAdClickTimestamp';"
)

# Check if the target directory exists
if [[ ! -d "lib/constants" ]]; then
    echo "Error: The 'lib/constants' directory does not exist."
    echo "Please create the directory structure first."
    exit 1
fi

# Create the target file if it doesn't exist
if [[ ! -f "$TARGET_FILE" ]]; then
    echo "File '$TARGET_FILE' does not exist. Creating it..."
    touch "$TARGET_FILE"
    echo "Created file: $TARGET_FILE"
fi

# Append the lines to the file
echo "Adding lines to '$TARGET_FILE'..."
for LINE in "${LINES[@]}"; do
    echo "$LINE" >> "$TARGET_FILE"
done

echo "Lines successfully added to '$TARGET_FILE'!"


# ------------------------modify compile, target and min sdk in android/app/build.gradle--------------

# Define the target file
BUILD_GRADLE_FILE="android/app/build.gradle"

# Define the SDK versions
COMPILE_SDK=35
TARGET_SDK=35
MIN_SDK=21

# Check if the target file exists
if [[ ! -f "$BUILD_GRADLE_FILE" ]]; then
    echo "Error: '$BUILD_GRADLE_FILE' file not found in the current directory."
    exit 1
fi

# Replace 'flutter.compileSdkVersion' with the actual compileSdkVersion
if grep -q "flutter\.compileSdkVersion" "$BUILD_GRADLE_FILE"; then
    sed -i "s/flutter\.compileSdkVersion/$COMPILE_SDK/" "$BUILD_GRADLE_FILE"
    echo "Replaced 'flutter.compileSdkVersion' with $COMPILE_SDK."
else
    echo "Error: 'flutter.compileSdkVersion' not found in '$BUILD_GRADLE_FILE'."
fi

# Replace 'flutter.targetSdkVersion' with the actual targetSdkVersion
if grep -q "flutter\.targetSdkVersion" "$BUILD_GRADLE_FILE"; then
    sed -i "s/flutter\.targetSdkVersion/$TARGET_SDK/" "$BUILD_GRADLE_FILE"
    echo "Replaced 'flutter.targetSdkVersion' with $TARGET_SDK."
else
    echo "Error: 'flutter.targetSdkVersion' not found in '$BUILD_GRADLE_FILE'."
fi

# Replace 'flutter.minSdkVersion' with the actual minSdkVersion
if grep -q "flutter\.minSdkVersion" "$BUILD_GRADLE_FILE"; then
    sed -i "s/flutter\.minSdkVersion/$MIN_SDK/" "$BUILD_GRADLE_FILE"
    echo "Replaced 'flutter.minSdkVersion' with $MIN_SDK."
else
    echo "Error: 'flutter.minSdkVersion' not found in '$BUILD_GRADLE_FILE'."
fi

echo "Flutter SDK placeholders replaced in '$BUILD_GRADLE_FILE'."


# ------------------------------------adds abi filters to android/app/build.gradle-----------------

# Define the target file
BUILD_GRADLE_FILE="android/app/build.gradle"

# Define the lines to add
NEW_LINES=$(cat <<EOF
        ndk.abiFilters 'armeabi-v7a', 'arm64-v8a','x86_64'
EOF
)

# Check if the target file exists
if [[ ! -f "$BUILD_GRADLE_FILE" ]]; then
    echo "Error: '$BUILD_GRADLE_FILE' file not found in the current directory."
    exit 1
fi

# Locate the line containing "versionName = flutter.versionName" and add new lines below it
if grep -q "versionName = flutter.versionName" "$BUILD_GRADLE_FILE"; then
    sed -i "/versionName = flutter.versionName/a $NEW_LINES" "$BUILD_GRADLE_FILE"
    echo "Added new lines below 'versionName = flutter.versionName' in '$BUILD_GRADLE_FILE'."
else
    echo "Error: 'versionName = flutter.versionName' not found in '$BUILD_GRADLE_FILE'."
fi

echo "abi filters added to '$BUILD_GRADLE_FILE'."



# ------------------------------------create key.properties file----------------------

# Define the target file path
KEY_PROPERTIES_FILE="android/key.properties"

# Define the content to be written to the file
KEY_PROPERTIES_CONTENT=$(cat <<EOF
storePassword=
keyPassword=
keyAlias=upload
storeFile=C:\\Users\\AB\\Desktop\\proj\\Flutter_Apps\\unity_ads_status\\android\\upload-keystore.jks
EOF
)

# Check if the android directory exists
if [[ ! -d "android" ]]; then
    echo "Error: 'android' directory not found in the current directory."
    exit 1
fi

# Create the key.properties file and write the content
echo "$KEY_PROPERTIES_CONTENT" > "$KEY_PROPERTIES_FILE"

# Confirm the creation of the file
if [[ -f "$KEY_PROPERTIES_FILE" ]]; then
    echo "Successfully created 'key.properties' in the 'android' directory."
else
    echo "Error: Failed to create 'key.properties'."
fi

echo "key.properties file created."


# ---------------------------------get the key.properties inside the app/build.gradle----------

# Define the target file
BUILD_GRADLE_FILE="android/app/build.gradle"

# Define the keystore properties lines to be added
KEYSTORE_LINES=$(cat <<'EOF'
def keystoreProperties = new Properties()
def keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(new FileInputStream(keystorePropertiesFile))
}
EOF
)

# Check if the target file exists
if [[ ! -f "$BUILD_GRADLE_FILE" ]]; then
    echo "Error: '$BUILD_GRADLE_FILE' file not found in the current directory."
    exit 1
fi

# Check if the lines are already present
if grep -q "keystoreProperties = new Properties()" "$BUILD_GRADLE_FILE"; then
    echo "'keystoreProperties' definition already exists in '$BUILD_GRADLE_FILE'."
    exit 0
fi

# Add the lines after the plugins block
TEMP_FILE=$(mktemp)
awk -v insert="$KEYSTORE_LINES" '
    /plugins \{/ { found=1 }
    found && /^\}/ { print; print insert; found=0; next }
    { print }
' "$BUILD_GRADLE_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$BUILD_GRADLE_FILE"

# Confirm the operation
if grep -q "keystoreProperties = new Properties()" "$BUILD_GRADLE_FILE"; then
    echo "Successfully added 'keystoreProperties' definition to '$BUILD_GRADLE_FILE'."
else
    echo "Error: Failed to add 'keystoreProperties' definition to '$BUILD_GRADLE_FILE'."
fi

# !
# ---------------------------------add signingConfigs to android/app/build.gradle file----------

# Define the target file
BUILD_GRADLE_FILE="android/app/build.gradle"

# Define the signingConfigs block to be added under defaultConfig
SIGNING_CONFIGS_BLOCK=$(cat <<'EOF'

    signingConfigs { 
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
EOF
)

# Check if the target file exists
if [[ ! -f "$BUILD_GRADLE_FILE" ]]; then
    echo "Error: '$BUILD_GRADLE_FILE' file not found in the current directory."
    exit 1
fi

# Check if the signingConfigs block is already present under defaultConfig
if grep -q "signingConfigs {" "$BUILD_GRADLE_FILE"; then
    echo "'signingConfigs' block already exists under defaultConfig in '$BUILD_GRADLE_FILE'."
    exit 0
fi

# Insert the signingConfigs block under defaultConfig
TEMP_FILE=$(mktemp)

awk -v insert="$SIGNING_CONFIGS_BLOCK" '
/defaultConfig {/ { found=1 }
found && /}/ {
    print
    print insert
    found=0
    next
}
{ print }
' "$BUILD_GRADLE_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$BUILD_GRADLE_FILE"

# Confirm the operation
if grep -q "signingConfigs" "$BUILD_GRADLE_FILE"; then
    echo "Successfully added 'signingConfigs' block under 'defaultConfig' in '$BUILD_GRADLE_FILE'."
else
    echo "Error: Failed to add 'signingConfigs' block under 'defaultConfig' in '$BUILD_GRADLE_FILE'."
fi

# ---------------------------------set storeconfigs.release in app/build.gradle----------

# Define the target file
BUILD_GRADLE_FILE="android/app/build.gradle"

# Check if the target file exists
if [[ ! -f "$BUILD_GRADLE_FILE" ]]; then
    echo "Error: '$BUILD_GRADLE_FILE' file not found in the current directory."
    exit 1
fi

# Replace signingConfigs.debug with signingConfigs.release
sed -i 's/signingConfigs\.debug/signingConfigs\.release/g' "$BUILD_GRADLE_FILE"

# Confirm the operation
if grep -q "signingConfigs.release" "$BUILD_GRADLE_FILE"; then
    echo "Successfully replaced 'signingConfigs.debug' with 'signingConfigs.release' in '$BUILD_GRADLE_FILE'."
else
    echo "Error: 'signingConfigs.release' was not found in '$BUILD_GRADLE_FILE'."
fi


# ------------------------------------run pub get to get dependencies----------------------
# Run flutter pub get to fetch the packages
flutter pub get


#! ------------------------------------configure firebase project----------------------
# Function to prompt the user for Firebase configuration
# configure_firebase() {
#     echo "Do you want to configure Firebase for your Flutter project? (yes/no)"
#     read -r user_input

#     case $user_input in
#         yes|YES|y|Y)
#             echo "Configuring Firebase using FlutterFire CLI..."
            
#             # Check if FlutterFire CLI is installed
#             if ! command -v flutterfire &> /dev/null; then
#                 echo "Error: FlutterFire CLI is not installed."
#                 echo "Please install it using the following command:"
#                 echo "dart pub global activate flutterfire_cli"
#                 exit 1
#             fi

#             # Run the FlutterFire configuration command
#             flutterfire configure

#             # Check if the command succeeded
#             if [[ $? -eq 0 ]]; then
#                 echo "Firebase successfully configured for your Flutter project!"
#             else
#                 echo "Error: Failed to configure Firebase. Please check the logs above."
#                 exit 1
#             fi
#             ;;
#         no|NO|n|N)
#             echo "Skipping Firebase configuration."
#             ;;
#         *)
#             echo "Invalid input. Please answer 'yes' or 'no'."
#             configure_firebase # Recursively call the function until valid input is given
#             ;;
#     esac
# }

# # Run the Firebase configuration function
# configure_firebase