#!/usr/bin/env bash
# Generate Xcode project for LiveRecorder menu bar app
set -e

PROJ_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SWIFT_DIR="$PROJ_ROOT/SwiftUI/LiveRecorder"
XCODEPROJ="$SWIFT_DIR/LiveRecorder.xcodeproj"

echo "==> Generating Xcode project..."
mkdir -p "$XCODEPROJ"

SOURCE_FILES=(
  "LiveRecorderApp"
  "Models/Recording"
  "Services/APIClient"
  "Services/PythonManager"
  "Views/AddRecordingView"
  "Views/RecordingRowView"
  "Views/RecordingListView"
  "Views/StorageView"
  "Views/SettingsView"
)

# ── Generate UUIDs ──
build_uuid() { uuidgen | tr '[:lower:]' '[:upper:]' | tr -d '-' | head -c24; }
PJ_ID=$(build_uuid)
TG_ID=$(build_uuid)
GRP=$(build_uuid)
SRC_GRP=$(build_uuid)
MDL_GRP=$(build_uuid)
SVC_GRP=$(build_uuid)
VWS_GRP=$(build_uuid)
PLIST_REF=$(build_uuid)
PROD_REF=$(build_uuid)
BLD_PHASE_SRC=$(build_uuid)
BLD_PHASE_CP=$(build_uuid)
CFG_DBG=$(build_uuid)
CFG_REL=$(build_uuid)
CFG_DBG_LIST=$(build_uuid)
CFG_REL_LIST=$(build_uuid)

# ── Generate file references ──
declare -A FILE_REFS FILE_BUILDS
for f in "${SOURCE_FILES[@]}"; do
  FILE_REFS[$f]=$(build_uuid)
  FILE_BUILDS[$f]=$(build_uuid)
done

# Build file references section
FILE_REFS_ENTRIES=""
FILE_GROUP_ENTRIES=""
MODEL_GROUP_ENTRIES=""
SERVICE_GROUP_ENTRIES=""
VIEWS_GROUP_ENTRIES=""
BUILD_FILES=""

for f in "${SOURCE_FILES[@]}"; do
  name=$(basename "$f").swift
  path="$f.swift"
  ref="${FILE_REFS[$f]}"
  build="${FILE_BUILDS[$f]}"
  dir=$(dirname "$f")

  # File reference entry
  FILE_REFS_ENTRIES+="		$ref /* $name */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = \"$name\"; sourceTree = \"<group>\"; };
"

  # Build file entry
  BUILD_FILES+="		$build /* $name in Sources */ = {isa = PBXBuildFile; fileRef = $ref /* $name */; };
"

  # Group assignment
  if [[ "$dir" == "Models" ]]; then
    MODEL_GROUP_ENTRIES+="				$ref /* $name */,
"
  elif [[ "$dir" == "Services" ]]; then
    SERVICE_GROUP_ENTRIES+="				$ref /* $name */,
"
  elif [[ "$dir" == "Views" ]]; then
    VIEWS_GROUP_ENTRIES+="				$ref /* $name */,
"
  else
    FILE_GROUP_ENTRIES+="				$ref /* $name */,
"
  fi
done

# Plist file ref
cat > "$XCODEPROJ/project.pbxproj" <<XEOF
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
$BUILD_FILES
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
$FILE_REFS_ENTRIES
		$PLIST_REF /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = \"<group>\"; };
/* End PBXFileReference section */

/* Begin PBXGroup section */
		$GRP = {
			isa = PBXGroup;
			children = (
				$SRC_GRP /* LiveRecorder */,
				$PJ_ID /* Products */,
			);
			sourceTree = "<group>";
		};
		$SRC_GRP /* LiveRecorder */ = {
			isa = PBXGroup;
			children = (
$FILE_GROUP_ENTRIES
				$MDL_GRP /* Models */,
				$SVC_GRP /* Services */,
				$VWS_GRP /* Views */,
				$PLIST_REF /* Info.plist */,
			);
			path = "";
			sourceTree = "<group>";
		};
		$MDL_GRP /* Models */ = {
			isa = PBXGroup;
			children = (
$MODEL_GROUP_ENTRIES
			);
			path = Models;
			sourceTree = "<group>";
		};
		$SVC_GRP /* Services */ = {
			isa = PBXGroup;
			children = (
$SERVICE_GROUP_ENTRIES
			);
			path = Services;
			sourceTree = "<group>";
		};
		$VWS_GRP /* Views */ = {
			isa = PBXGroup;
			children = (
$VIEWS_GROUP_ENTRIES
			);
			path = Views;
			sourceTree = "<group>";
		};
		$PJ_ID /* Products */ = {
			isa = PBXGroup;
			children = (
				$PROD_REF /* LiveRecorder.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		$TG_ID /* LiveRecorder */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = $CFG_DBG_LIST /* Build configuration list for PBXNativeTarget "LiveRecorder" */;
			buildPhases = (
				$BLD_PHASE_SRC /* Sources */,
				$BLD_PHASE_CP /* Copy Python Backend */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = LiveRecorder;
			productName = LiveRecorder;
			productReference = $PROD_REF /* LiveRecorder.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		$GRP /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1700;
				LastUpgradeCheck = 1700;
				TargetAttributes = {
					$TG_ID = { CreatedOnToolsVersion = 16.0; };
				};
			};
			buildConfigurationList = $CFG_DBG /* Build configuration list for PBXProject "LiveRecorder" */;
			compatibilityVersion = "Xcode 15.0";
			developmentRegion = "zh-Hans";
			hasScannedForEncodings = 0;
			knownRegions = ( en, "zh-Hans", Base );
			mainGroup = $GRP;
			productRefGroup = $PJ_ID /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				$TG_ID /* LiveRecorder */,
			);
		};
/* End PBXProject section */

/* Begin PBXShellScriptBuildPhase section */
		$BLD_PHASE_CP /* Copy Python Backend */ = {
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
			name = "Copy Python Backend";
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 1;
			shellPath = /bin/bash;
			shellScript = "# Copy python_backend into .app Resources\\nPY_SRC=\"\\\${PROJECT_DIR}/../../python_backend\"\\nPY_DST=\"\\\${BUILT_PRODUCTS_DIR}/\\\${PRODUCT_NAME}.app/Contents/Resources/python_backend\"\\nif [ -d \"\\\$PY_SRC\" ]; then\\n  rsync -a --delete --exclude='__pycache__' --exclude='*.pyc' --exclude='config' --exclude='downloads' \"\\\$PY_SRC/\" \"\\\$PY_DST/\"\\n  echo \"Copied python_backend to Resources\"\\nfi\\n";
		};
/* End PBXShellScriptBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		$BLD_PHASE_SRC /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
$(
  for f in "${SOURCE_FILES[@]}"; do
    name=$(basename "$f").swift
    build="${FILE_BUILDS[$f]}"
    echo "				$build /* $name in Sources */,"
  done
)
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		$CFG_DBG /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				IPHONEOS_DEPLOYMENT_TARGET = 26.0;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		$CFG_REL /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_OPTIMIZATION_LEVEL = s;
				IPHONEOS_DEPLOYMENT_TARGET = 26.0;
				MACOSX_DEPLOYMENT_TARGET = 13.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
			};
			name = Release;
		};
		$CFG_DBG_LIST /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = Info.plist;
				INFOPLIST_KEY_LSUIElement = YES;
				INFOPLIST_KEY_NSHumanReadableCopyright = "";
				LD_RUNPATH_SEARCH_PATHS = ( "\$(inherited)", "@executable_path/../Frameworks" );
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.liverecorder.app;
				PRODUCT_NAME = "\$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			};
			name = Debug;
		};
		$CFG_REL_LIST /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				COMBINE_HIDPI_IMAGES = YES;
				CURRENT_PROJECT_VERSION = 1;
				GENERATE_INFOPLIST_FILE = YES;
				INFOPLIST_FILE = Info.plist;
				INFOPLIST_KEY_LSUIElement = YES;
				INFOPLIST_KEY_NSHumanReadableCopyright = "";
				LD_RUNPATH_SEARCH_PATHS = ( "\$(inherited)", "@executable_path/../Frameworks" );
				MARKETING_VERSION = 0.1.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.liverecorder.app;
				PRODUCT_NAME = "\$(TARGET_NAME)";
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		$CFG_DBG /* Build configuration list for PBXProject "LiveRecorder" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				$CFG_DBG /* Debug */,
				$CFG_REL /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		$CFG_DBG_LIST /* Build configuration list for PBXNativeTarget "LiveRecorder" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				$CFG_DBG_LIST /* Debug */,
				$CFG_REL_LIST /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = $GRP /* Project object */;
}
XEOF

echo "==> Project created at $XCODEPROJ"
echo "==> Open with: open $XCODEPROJ"
