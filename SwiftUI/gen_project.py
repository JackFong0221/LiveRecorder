#!/usr/bin/env python3
"""Generate a minimal xcodeproj for the LiveRecorder SwiftUI app."""
import os, uuid, json, shutil

PROJ_DIR = os.path.dirname(os.path.abspath(__file__))
SWIFT_DIR = os.path.join(PROJ_DIR, "LiveRecorder")
XCODEPROJ = os.path.join(SWIFT_DIR, "LiveRecorder.xcodeproj")
os.makedirs(XCODEPROJ, exist_ok=True)

def uid():
    return uuid.uuid4().hex[:24].upper()

# Objects
PJ_ID      = uid()
TG_ID      = uid()
GRP        = uid()
SRC_GRP    = uid()
MDL_GRP    = uid()
SVC_GRP    = uid()
VWS_GRP    = uid()
PROD_GRP   = uid()
PLIST_REF  = uid()
PROD_REF   = uid()
PHASE_SRC  = uid()
PHASE_CP   = uid()
CFG_DBG    = uid()
CFG_REL    = uid()
CFG_DBG_T  = uid()
CFG_REL_T  = uid()
CFG_LIST   = uid()
CFG_LIST_T = uid()

SRC_FILES = [
    "LiveRecorderApp",
    "Models/Recording",
    "Services/APIClient",
    "Services/PythonManager",
    "Views/AddRecordingView",
    "Views/RecordingRowView",
    "Views/RecordingListView",
    "Views/StorageView",
    "Views/SettingsView",
]

# File refs & build files
file_refs  = {}
build_refs = {}
for f in SRC_FILES:
    file_refs[f]  = uid()
    build_refs[f] = uid()

pbxproj = f'''// !$*UTF8*$!
{{
    archiveVersion = 1;
    classes = {{}};
    objectVersion = 56;
    objects = {{

/* Begin PBXBuildFile section */
{
    '\n'.join(f'\t\t{build_refs[f]} /* {f.split("/")[-1]}.swift in Sources */ = {{isa = PBXBuildFile; fileRef = {file_refs[f]} /* {f.split("/")[-1]}.swift */; }};'
    for f in SRC_FILES)
}
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
{
    '\n'.join(f'\t\t{file_refs[f]} /* {f.split("/")[-1]}.swift */ = {{isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = "{f}.swift"; sourceTree = "<group>"; }};'
    for f in SRC_FILES)
}
\t\t{PLIST_REF} /* Info.plist */ = {{isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = "Info.plist"; sourceTree = "<group>"; }};
/* End PBXFileReference section */

/* Begin PBXGroup section */
\t\t{GRP} = {{isa = PBXGroup; children = ({SRC_GRP} /* LiveRecorder */,{PROD_GRP} /* Products */,); sourceTree = "<group>"; }};
\t\t{SRC_GRP} /* LiveRecorder */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{' | {file_refs[f]} /* {f.split("/")[-1]}.swift */'.join('LiveRecorderApp' if f == 'LiveRecorderApp' else '' for f in SRC_FILES if '/' not in f)}
{' | '.join(f'\t\t\t\t{file_refs[f]} /* {f.split("/")[-1]}.swift */,' for f in SRC_FILES if '/' not in f)}
\t\t\t\t{MDL_GRP} /* Models */,
\t\t\t\t{SVC_GRP} /* Services */,
\t\t\t\t{VWS_GRP} /* Views */,
\t\t\t\t{PLIST_REF} /* Info.plist */,
\t\t\t);
\t\t\tpath = "";
\t\t\tsourceTree = "<group>";
\t\t}};
\t\t{MDL_GRP} /* Models */ = {{isa = PBXGroup; children = ({', '.join(f'{file_refs[f]}' for f in SRC_FILES if f.startswith('Models/'))}); path = Models; sourceTree = "<group>"; }};
\t\t{SVC_GRP} /* Services */ = {{isa = PBXGroup; children = ({', '.join(f'{file_refs[f]}' for f in SRC_FILES if f.startswith('Services/'))}); path = Services; sourceTree = "<group>"; }};
\t\t{VWS_GRP} /* Views */ = {{isa = PBXGroup; children = ({', '.join(f'{file_refs[f]}' for f in SRC_FILES if f.startswith('Views/'))}); path = Views; sourceTree = "<group>"; }};
\t\t{PROD_GRP} /* Products */ = {{isa = PBXGroup; children = ({PROD_REF} /* LiveRecorder.app */,); name = Products; sourceTree = "<group>"; }};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
\t\t{TG_ID} /* LiveRecorder */ = {{
\t\t\tisa = PBXNativeTarget;
\t\t\tbuildConfigurationList = {CFG_LIST_T};
\t\t\tbuildPhases = ({PHASE_SRC} /* Sources */,{PHASE_CP} /* Copy Python Backend */,);
\t\t\tbuildRules = ();
\t\t\tdependencies = ();
\t\t\tname = LiveRecorder;
\t\t\tproductName = LiveRecorder;
\t\t\tproductReference = {PROD_REF};
\t\t\tproductType = "com.apple.product-type.application";
\t\t}};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
\t\t{GRP} /* Project object */ = {{
\t\t\tisa = PBXProject;
\t\t\tattributes = {{BuildIndependentTargetsInParallel = 1; LastSwiftUpdateCheck = 1700; LastUpgradeCheck = 1700; TargetAttributes = {{{TG_ID} = {{CreatedOnToolsVersion = 16.0;}};}};}};
\t\t\tbuildConfigurationList = {CFG_LIST};
\t\t\tcompatibilityVersion = "Xcode 15.0";
\t\t\tdevelopmentRegion = "zh-Hans";
\t\t\thasScannedForEncodings = 0;
\t\t\tknownRegions = (en, "zh-Hans", Base);
\t\t\tmainGroup = {GRP};
\t\t\tproductRefGroup = {PROD_GRP};
\t\t\tprojectDirPath = "";
\t\t\tprojectRoot = "";
\t\t\ttargets = ({TG_ID});
\t\t}};
/* End PBXProject section */

/* Begin PBXShellScriptBuildPhase section */
\t\t{PHASE_CP} /* Copy Python Backend */ = {{
\t\t\tisa = PBXShellScriptBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = ();
\t\t\tinputPaths = ();
\t\t\tname = "Copy Python Backend";
\t\t\toutputPaths = ();
\t\t\trunOnlyForDeploymentPostprocessing = 1;
\t\t\tshellPath = /bin/bash;
\t\t\tshellScript = "PY_SRC=\\"${{PROJECT_DIR}}/../../python_backend\\"\\nPY_DST=\\"${{BUILT_PRODUCTS_DIR}}/${{PRODUCT_NAME}}.app/Contents/Resources/python_backend\\"\\nif [ -d \\"$PY_SRC\\" ]; then\\n  rsync -a --delete --exclude='__pycache__' --exclude='*.pyc' --exclude='config' --exclude='downloads' \\"$PY_SRC/\\" \\"$PY_DST/\\"\\n  echo \\"Copied python_backend\\"\\nfi\\n";
\t\t}};
/* End PBXShellScriptBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
\t\t{PHASE_SRC} /* Sources */ = {{
\t\t\tisa = PBXSourcesBuildPhase;
\t\t\tbuildActionMask = 2147483647;
\t\t\tfiles = (
{' | '.join(f'\t\t\t\t{build_refs[f]} /* {f.split("/")[-1]}.swift in Sources */,' for f in SRC_FILES)}
\t\t\t);
\t\t\trunOnlyForDeploymentPostprocessing = 0;
\t\t}};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
\t\t{CFG_DBG} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ANALYZER_NONNULL = YES; CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES; DEBUG_INFORMATION_FORMAT = dwarf; ENABLE_STRICT_OBJC_MSGSEND = YES; ENABLE_TESTABILITY = YES; GCC_OPTIMIZATION_LEVEL = 0; MACOSX_DEPLOYMENT_TARGET = 14.0; MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE; ONLY_ACTIVE_ARCH = YES; SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG; SWIFT_OPTIMIZATION_LEVEL = "-Onone"; }};
\t\t\tname = Debug;
\t\t}};
\t\t{CFG_REL} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{ALWAYS_SEARCH_USER_PATHS = NO; CLANG_ANALYZER_NONNULL = YES; CLANG_ENABLE_MODULES = YES; CLANG_ENABLE_OBJC_ARC = YES; DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym"; ENABLE_NS_ASSERTIONS = NO; ENABLE_STRICT_OBJC_MSGSEND = YES; GCC_OPTIMIZATION_LEVEL = s; MACOSX_DEPLOYMENT_TARGET = 14.0; MTL_ENABLE_DEBUG_INFO = NO; SWIFT_COMPILATION_MODE = wholemodule; SWIFT_OPTIMIZATION_LEVEL = "-O"; }};
\t\t\tname = Release;
\t\t}};
\t\t{CFG_DBG_T} /* Debug */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_FILE = Info.plist; INFOPLIST_KEY_LSUIElement = YES; LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks"); MARKETING_VERSION = 0.1.0; PRODUCT_BUNDLE_IDENTIFIER = com.liverecorder.app; PRODUCT_NAME = "$(TARGET_NAME)"; SWIFT_EMIT_LOC_STRINGS = YES; SWIFT_VERSION = 5.0; }};
\t\t\tname = Debug;
\t\t}};
\t\t{CFG_REL_T} /* Release */ = {{
\t\t\tisa = XCBuildConfiguration;
\t\t\tbuildSettings = {{CODE_SIGN_STYLE = Automatic; CURRENT_PROJECT_VERSION = 1; GENERATE_INFOPLIST_FILE = YES; INFOPLIST_FILE = Info.plist; INFOPLIST_KEY_LSUIElement = YES; LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/../Frameworks"); MARKETING_VERSION = 0.1.0; PRODUCT_BUNDLE_IDENTIFIER = com.liverecorder.app; PRODUCT_NAME = "$(TARGET_NAME)"; SWIFT_EMIT_LOC_STRINGS = YES; SWIFT_VERSION = 5.0; }};
\t\t\tname = Release;
\t\t}};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
\t\t{CFG_LIST} = {{isa = XCConfigurationList; buildConfigurations = ({CFG_DBG},{CFG_REL},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};
\t\t{CFG_LIST_T} = {{isa = XCConfigurationList; buildConfigurations = ({CFG_DBG_T},{CFG_REL_T},); defaultConfigurationIsVisible = 0; defaultConfigurationName = Release; }};
/* End XCConfigurationList section */
\t}};
\trootObject = {GRP} /* Project object */;
}}
'''

pbxproj_path = os.path.join(XCODEPROJ, "project.pbxproj")
with open(pbxproj_path, "w") as f:
    f.write(pbxproj)

print(f"Created: {pbxproj_path}")
print(f"Open with: open {XCODEPROJ}")
