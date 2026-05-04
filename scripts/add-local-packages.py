#!/usr/bin/env python3
"""LocalPackages 10개를 MatchaMap.xcodeproj/project.pbxproj에 등록한다.

Xcode 26+ 포맷(objectVersion 77)에 맞춰:
- XCLocalSwiftPackageReference 섹션 추가 (10건)
- XCSwiftPackageProductDependency 섹션 추가 (10건)
- PBXBuildFile 추가 (10건, Frameworks 링크용)
- PBXFrameworksBuildPhase.files 갱신
- PBXNativeTarget.packageProductDependencies 갱신
- PBXProject.packageReferences 추가

Idempotent: 이미 등록된 모듈은 스킵.
"""

from pathlib import Path
import re
import sys

PROJECT = Path(__file__).resolve().parent.parent / "MatchaMap.xcodeproj/project.pbxproj"

# (모듈 이름, 상대 경로)
MODULES = [
    ("Core", "LocalPackages/Core"),
    ("DesignSystem", "LocalPackages/DesignSystem"),
    ("Domain", "LocalPackages/Domain"),
    ("Data", "LocalPackages/Data"),
    ("FeatureMap", "LocalPackages/Feature/FeatureMap"),
    ("FeatureAuth", "LocalPackages/Feature/FeatureAuth"),
    ("FeatureStore", "LocalPackages/Feature/FeatureStore"),
    ("FeatureSocial", "LocalPackages/Feature/FeatureSocial"),
    ("FeatureCollection", "LocalPackages/Feature/FeatureCollection"),
    ("FeatureMonetize", "LocalPackages/Feature/FeatureMonetize"),
]

# 24-char hex ID 생성 (충돌 회피용 자체 prefix 71ADE2A* 사용 — 기존 71ADE2[5-6]xx와 분리)
def make_id(kind: str, idx: int) -> str:
    # kind: A=LocalPackageRef, B=ProductDep, C=BuildFile
    return f"71ADE2A{kind}{idx:02d}2FA87741002AF431"


def main() -> int:
    src = PROJECT.read_text()

    # 이미 적용되었는지 확인
    if "XCLocalSwiftPackageReference" in src:
        print("[skip] XCLocalSwiftPackageReference already present", file=sys.stderr)
        return 0

    # 1) PBXBuildFile section — 신규 추가 (10건)
    buildfile_section = "/* Begin PBXBuildFile section */\n"
    for i, (name, _) in enumerate(MODULES, 1):
        bf = make_id("C", i)
        pd = make_id("B", i)
        buildfile_section += f"\t\t{bf} /* {name} in Frameworks */ = {{isa = PBXBuildFile; productRef = {pd} /* {name} */; }};\n"
    buildfile_section += "/* End PBXBuildFile section */\n\n"

    src = src.replace(
        "/* Begin PBXFileReference section */",
        buildfile_section + "/* Begin PBXFileReference section */",
    )

    # 2) Frameworks 빌드 페이즈에 files 추가
    files_replacement = "files = (\n"
    for i, (name, _) in enumerate(MODULES, 1):
        bf = make_id("C", i)
        files_replacement += f"\t\t\t\t{bf} /* {name} in Frameworks */,\n"
    files_replacement += "\t\t\t);"

    # 정확히 PBXFrameworksBuildPhase 안의 빈 files 만 교체
    src = re.sub(
        r"(/\* Begin PBXFrameworksBuildPhase section \*/\s*\n\s*[A-F0-9]+ /\* Frameworks \*/ = \{\s*isa = PBXFrameworksBuildPhase;\s*buildActionMask = 2147483647;\s*)files = \(\s*\);",
        lambda m: m.group(1) + files_replacement,
        src,
        count=1,
    )

    # 3) PBXNativeTarget.packageProductDependencies 갱신 (빈 () → 10건)
    pkg_prod_deps = "packageProductDependencies = (\n"
    for i, (name, _) in enumerate(MODULES, 1):
        pd = make_id("B", i)
        pkg_prod_deps += f"\t\t\t\t{pd} /* {name} */,\n"
    pkg_prod_deps += "\t\t\t);"

    src = src.replace(
        "packageProductDependencies = (\n\t\t\t);",
        pkg_prod_deps,
    )

    # 4) PBXProject에 packageReferences 추가
    pkg_refs = "\t\t\tpackageReferences = (\n"
    for i, (name, _) in enumerate(MODULES, 1):
        lpr = make_id("A", i)
        pkg_refs += f"\t\t\t\t{lpr} /* XCLocalSwiftPackageReference \"{name}\" */,\n"
    pkg_refs += "\t\t\t);\n"

    # productRefGroup 라인 직전에 삽입
    src = re.sub(
        r"(\t\tproductRefGroup = [A-F0-9]+ /\* Products \*/;)",
        pkg_refs + r"\1",
        src,
        count=1,
    )

    # 5) XCLocalSwiftPackageReference + XCSwiftPackageProductDependency 섹션을 마지막에 추가
    xclocal = "/* Begin XCLocalSwiftPackageReference section */\n"
    for i, (name, path) in enumerate(MODULES, 1):
        lpr = make_id("A", i)
        xclocal += (
            f"\t\t{lpr} /* XCLocalSwiftPackageReference \"{path}\" */ = {{\n"
            f"\t\t\tisa = XCLocalSwiftPackageReference;\n"
            f"\t\t\trelativePath = {path};\n"
            f"\t\t}};\n"
        )
    xclocal += "/* End XCLocalSwiftPackageReference section */\n\n"

    xcprod = "/* Begin XCSwiftPackageProductDependency section */\n"
    for i, (name, _) in enumerate(MODULES, 1):
        pd = make_id("B", i)
        xcprod += (
            f"\t\t{pd} /* {name} */ = {{\n"
            f"\t\t\tisa = XCSwiftPackageProductDependency;\n"
            f"\t\t\tproductName = {name};\n"
            f"\t\t}};\n"
        )
    xcprod += "/* End XCSwiftPackageProductDependency section */\n"

    # XCConfigurationList section 끝 다음에 삽입
    src = src.replace(
        "/* End XCConfigurationList section */",
        "/* End XCConfigurationList section */\n\n" + xclocal + xcprod,
    )

    PROJECT.write_text(src)
    print(f"[ok] Registered {len(MODULES)} local packages in {PROJECT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
