#!/usr/bin/env python3
"""Firebase iOS SDK SPM dependency를 MatchaMap.xcodeproj/project.pbxproj에 추가.

Xcode 26+ 포맷(objectVersion 77):
- XCRemoteSwiftPackageReference 1건 (firebase-ios-sdk)
- XCSwiftPackageProductDependency N건 (FirebaseCore/Auth/Firestore/Storage/AppCheck/Messaging/Analytics/Crashlytics)
- PBXBuildFile N건 (Frameworks 링크용)
- PBXFrameworksBuildPhase.files에 N건 추가
- PBXNativeTarget.packageProductDependencies에 N건 추가
- PBXProject.packageReferences에 1건 추가

Idempotent — 이미 있으면 noop.
"""

from pathlib import Path
import re
import sys

PROJECT = Path(__file__).resolve().parent.parent / "MatchaMap.xcodeproj/project.pbxproj"

REMOTE_URL = "https://github.com/firebase/firebase-ios-sdk"
REMOTE_MIN_VERSION = "11.0.0"

PRODUCTS = [
    "FirebaseCore",
    "FirebaseAuth",
    "FirebaseFirestore",
    "FirebaseStorage",
    "FirebaseAppCheck",
    "FirebaseMessaging",
    "FirebaseAnalytics",
    "FirebaseCrashlytics",
]

# 자체 24-char hex prefix — 71ADE2F* 영역 (LocalPackages는 71ADE2A*)
PKG_REF_ID = "71ADE2F0012FA87741002AF431"


def make_id(kind: str, idx: int) -> str:
    # kind: P=ProductDep, B=BuildFile
    return f"71ADE2F{kind}{idx:02d}2FA87741002AF431"


def main() -> int:
    src = PROJECT.read_text()
    if "firebase-ios-sdk" in src:
        print("[noop] firebase-ios-sdk already registered")
        return 0

    # 1) PBXBuildFile section — Firebase 산출물 N건 추가.
    bf_lines = []
    for i, prod in enumerate(PRODUCTS, 1):
        bf = make_id("B", i)
        pd = make_id("P", i)
        bf_lines.append(
            f"\t\t{bf} /* {prod} in Frameworks */ = {{isa = PBXBuildFile; productRef = {pd} /* {prod} */; }};"
        )
    bf_block = "\n".join(bf_lines) + "\n"

    src = src.replace(
        "/* End PBXBuildFile section */",
        bf_block + "/* End PBXBuildFile section */",
    )

    # 2) PBXFrameworksBuildPhase.files — 기존 ); 직전에 N건 삽입.
    files_inserts = "".join(
        f"\t\t\t\t{make_id('B', i)} /* {prod} in Frameworks */,\n"
        for i, prod in enumerate(PRODUCTS, 1)
    )
    src = re.sub(
        r"(71ADE2AC102FA87741002AF431 /\* FeatureMonetize in Frameworks \*/,\n)(\t\t\t\);)",
        r"\1" + files_inserts + r"\2",
        src,
        count=1,
    )

    # 3) PBXNativeTarget.packageProductDependencies — 기존 ); 직전에 N건 삽입.
    pp_inserts = "".join(
        f"\t\t\t\t{make_id('P', i)} /* {prod} */,\n"
        for i, prod in enumerate(PRODUCTS, 1)
    )
    src = re.sub(
        r"(71ADE2AB102FA87741002AF431 /\* FeatureMonetize \*/,\n)(\t\t\t\);)",
        r"\1" + pp_inserts + r"\2",
        src,
        count=1,
    )

    # 4) PBXProject.packageReferences — 기존 ); 직전에 1건 삽입.
    pkg_ref_line = (
        f"\t\t\t\t{PKG_REF_ID} /* XCRemoteSwiftPackageReference \"firebase-ios-sdk\" */,\n"
    )
    src = re.sub(
        r"(71ADE2AA102FA87741002AF431 /\* XCLocalSwiftPackageReference \"LocalPackages/Feature/FeatureMonetize\" \*/,\n)(\t\t\t\);)",
        r"\1" + pkg_ref_line + r"\2",
        src,
        count=1,
    )

    # 5) XCRemoteSwiftPackageReference 섹션 — XCLocalSwiftPackageReference 섹션 종료 직후에 신규 추가.
    remote_block = (
        "/* Begin XCRemoteSwiftPackageReference section */\n"
        f"\t\t{PKG_REF_ID} /* XCRemoteSwiftPackageReference \"firebase-ios-sdk\" */ = {{\n"
        f"\t\t\tisa = XCRemoteSwiftPackageReference;\n"
        f"\t\t\trepositoryURL = \"{REMOTE_URL}\";\n"
        f"\t\t\trequirement = {{\n"
        f"\t\t\t\tkind = upToNextMajorVersion;\n"
        f"\t\t\t\tminimumVersion = {REMOTE_MIN_VERSION};\n"
        f"\t\t\t}};\n"
        f"\t\t}};\n"
        "/* End XCRemoteSwiftPackageReference section */\n\n"
    )
    src = src.replace(
        "/* End XCLocalSwiftPackageReference section */\n",
        "/* End XCLocalSwiftPackageReference section */\n\n" + remote_block,
    )

    # 6) XCSwiftPackageProductDependency 섹션에 신규 N건 추가 (기존 섹션 끝 직전).
    prod_lines = []
    for i, prod in enumerate(PRODUCTS, 1):
        pd = make_id("P", i)
        prod_lines.append(
            f"\t\t{pd} /* {prod} */ = {{\n"
            f"\t\t\tisa = XCSwiftPackageProductDependency;\n"
            f"\t\t\tpackage = {PKG_REF_ID} /* XCRemoteSwiftPackageReference \"firebase-ios-sdk\" */;\n"
            f"\t\t\tproductName = {prod};\n"
            f"\t\t}};"
        )
    prod_block = "\n".join(prod_lines) + "\n"
    src = src.replace(
        "/* End XCSwiftPackageProductDependency section */",
        prod_block + "/* End XCSwiftPackageProductDependency section */",
    )

    PROJECT.write_text(src)
    print(f"[ok] registered firebase-ios-sdk + {len(PRODUCTS)} products")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
