/**
 * 모든 함수의 기본 리전. ADR-301 § 리전 결정 — `asia-northeast3` (Seoul) 강제.
 * 글로벌 read replica는 v1.2.0 트리거(ADR-304) 발화 시 재논의.
 */
export const DEFAULT_REGION = 'asia-northeast3' as const;

/** 콜러블 함수 디폴트 옵션. App Check + Auth 강제 + 30s 타임아웃. */
export const CALLABLE_DEFAULTS = {
  region: DEFAULT_REGION,
  enforceAppCheck: true,
  timeoutSeconds: 30,
  memory: '256MiB' as const,
};

/** 백그라운드 트리거 디폴트 옵션. */
export const BACKGROUND_DEFAULTS = {
  region: DEFAULT_REGION,
  timeoutSeconds: 540,
  memory: '512MiB' as const,
  retry: false,
};
