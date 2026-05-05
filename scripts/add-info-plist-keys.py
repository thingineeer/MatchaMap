#!/usr/bin/env python3
"""GENERATE_INFOPLIST_FILE=YES 환경에서 권한 사용 이유 + GADApplicationIdentifier를
project.pbxproj target buildSettings에 INFOPLIST_KEY_* 형태로 주입한다.

옵션 1 채택 — feedback-info-plist-conflict.md.

Idempotent: 같은 키가 이미 있으면 덮어쓰기.
"""

from pathlib import Path
import re
import sys

PROJECT = Path(__file__).resolve().parent.parent / "MatchaMap.xcodeproj/project.pbxproj"

# (key, value) — Xcode pbxproj 안에서는 쉼표/세미콜론/줄바꿈 escape 불필요한 평문.
KEYS = [
    ("INFOPLIST_KEY_NSLocationWhenInUseUsageDescription",
     "주변 말차 카페를 지도에 표시하고 길찾기를 제공하기 위해 사용됩니다."),
    ("INFOPLIST_KEY_NSPhotoLibraryUsageDescription",
     "리뷰와 도감에 첨부할 사진을 선택하기 위해 사용됩니다."),
    ("INFOPLIST_KEY_NSPhotoLibraryAddUsageDescription",
     "저장하신 매장 사진을 사진 보관함에 보관하기 위해 사용됩니다."),
    ("INFOPLIST_KEY_NSCameraUsageDescription",
     "리뷰와 도감에 추가할 매장 사진을 촬영하기 위해 사용됩니다."),
    ("INFOPLIST_KEY_NSUserTrackingUsageDescription",
     "나에게 더 잘 맞는 광고를 보여드리기 위해 사용됩니다. 거부하셔도 앱은 정상 동작합니다."),
    # AdMob — Configs/Shared.xcconfig에서 ADMOB_APP_ID_IOS=... 주입 후 빌드 타임 치환.
    # xcconfig 미연결 시 fallback test ID(Google 공식 sample).
    ("INFOPLIST_KEY_GADApplicationIdentifier",
     "ca-app-pub-3940256099942544~1458002511"),
]

# 두 target build config block (Debug + Release) — 71ADE260, 71ADE261.
TARGET_CONFIG_IDS = ("71ADE2602FA87741002AF431", "71ADE2612FA87741002AF431")


def upsert_keys_in_block(block: str, keys: list[tuple[str, str]]) -> str:
    """주어진 buildSettings 블록 안에 keys를 upsert."""
    out = block
    # buildSettings = { ... }; 블록의 인덴테이션은 \t\t\t\t (4 탭).
    indent = "\t\t\t\t"
    for k, v in keys:
        # 값에 쉼표/세미콜론/공백/콜론 포함 시 quote 필요. 한글 문자열은 무조건 quote.
        needs_quote = any(c in v for c in ' ;,:."')
        # 한글/비ASCII는 항상 quote.
        if not v.isascii():
            needs_quote = True
        # double-quote escape: " → \"
        v_quoted = v.replace('"', '\\"')
        line_value = f'"{v_quoted}"' if needs_quote else v
        new_line = f"{indent}{k} = {line_value};"

        # 기존 라인 패턴: 인덴트 + key + " = " + 임의값 + ";"
        existing = re.compile(rf"^{re.escape(indent)}{re.escape(k)}\s*=\s*[^;]+;\s*$", re.MULTILINE)
        if existing.search(out):
            out = existing.sub(new_line, out)
        else:
            # 블록 끝 `\t\t\t};` 직전에 추가.
            out = re.sub(
                r"(\t\t\t\};)$",
                new_line + "\n" + r"\1",
                out,
                count=1,
                flags=re.MULTILINE,
            )
    return out


def main() -> int:
    src = PROJECT.read_text()
    original = src

    for cid in TARGET_CONFIG_IDS:
        # cid /* Debug|Release */ = {  isa = XCBuildConfiguration;  buildSettings = { ... };  name = ...; };
        pattern = re.compile(
            rf"(\t\t{cid} /\* (?:Debug|Release) \*/ = \{{\n"
            rf"\t\t\tisa = XCBuildConfiguration;\n"
            rf"\t\t\tbuildSettings = \{{\n)"
            rf"((?:[^\}}].*?\n)*?)"
            rf"(\t\t\t\}};\n"
            rf"\t\t\tname = (?:Debug|Release);\n"
            rf"\t\t\}};)",
            re.DOTALL,
        )
        m = pattern.search(src)
        if not m:
            print(f"[error] cannot locate config {cid}", file=sys.stderr)
            return 1
        head, body, tail = m.group(1), m.group(2), m.group(3)
        # body + tail를 합쳐서 upsert. tail의 `\t\t\t};` 라인이 블록 끝.
        block_body_with_tail = body + tail
        new_block = upsert_keys_in_block(block_body_with_tail, KEYS)
        src = src.replace(head + body + tail, head + new_block, 1)

    if src == original:
        print("[noop] no changes")
        return 0

    PROJECT.write_text(src)
    print(f"[ok] upserted {len(KEYS)} INFOPLIST_KEY_* keys into 2 target configs")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
