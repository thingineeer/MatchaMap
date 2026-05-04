# MatchaMap Firebase Hosting

Apple App Site Association(AASA) + 정적 자원 호스팅 전용 디렉토리.

- **소유자**: `server-auth` (ADR-303 §4)
- **배포 명령**: `firebase deploy --only hosting --project MatchaMapAPP`
- **도메인**: `matchamap.app` (커스텀 도메인 등록 후 SSL 자동 발급) + `matchamapapp.web.app` (기본).

## 디렉토리

```
firebase-hosting/
├── firebase.json                      # Hosting 설정 + AASA Content-Type 헤더
├── public/
│   └── .well-known/
│       └── apple-app-site-association # Passkey + Universal Link AASA (JSON)
└── README.md
```

## AASA 빌드 타임 치환

`apple-app-site-association` 내 `__APPLE_TEAM_ID__` placeholder는 **배포 직전**에
실제 Team ID로 치환. 본 레포는 public이므로 Team ID는 vault에서 주입.

```sh
# Phase 3 server-functions가 작성할 deploy 스크립트 예시
TEAM_ID="$(cat ~/.env-vault/projects/matchamap-ios/apple/team_id.txt)"
sed -i.bak "s/__APPLE_TEAM_ID__/${TEAM_ID}/g" \
  firebase-hosting/public/.well-known/apple-app-site-association
firebase deploy --only hosting --project MatchaMapAPP
git checkout firebase-hosting/public/.well-known/apple-app-site-association
```

> 위 sed 후 git checkout으로 placeholder 복원 — Team ID가 레포에 커밋되지 않도록.
> CI(GitHub Actions) 환경에서는 Repository Secret `APPLE_TEAM_ID`로 주입.

## 검증

배포 후 다음 명령으로 응답 검증:

```sh
curl -I https://matchamap.app/.well-known/apple-app-site-association
# HTTP/2 200
# content-type: application/json
# cache-control: public, max-age=3600

curl -s https://matchamap.app/.well-known/apple-app-site-association | jq .
# 정상 JSON 반환 + appID에 실제 Team ID 포함
```

## 트러블슈팅

- **404**: `firebase deploy --only hosting` 후에도 404 → `public/` 디렉토리 위치 확인 (`firebase.json`의 `"public"` 경로 정합).
- **Content-Type text/plain**: `firebase.json` headers 블록의 `source` 패턴이 일치하는지 확인 (`.well-known/...` 경로 정확히).
- **Passkey 등록 실패 (iOS)**: AASA의 `webcredentials.apps`에 `<TEAM_ID>.th1ngjin.MatchaMap`이 정확히 포함되어 있어야 함. iOS 디바이스의 swcd 캐시 갱신 ~24h 소요 가능.
