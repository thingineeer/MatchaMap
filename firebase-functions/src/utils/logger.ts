import { logger } from 'firebase-functions/v2';

/**
 * Cloud Logging structured log 헬퍼.
 * - jsonPayload로 검색/필터링이 용이하도록 한정된 키만 사용.
 * - PII(이메일/이름/IP) 절대 금지. uid는 hash로 발급된 Firebase Auth uid만 허용.
 */
export interface LogContext {
  fn: string;
  uid?: string;
  storeId?: string;
  reviewId?: string;
  err?: unknown;
  [key: string]: unknown;
}

export function logInfo(message: string, ctx: LogContext): void {
  logger.info(message, sanitize(ctx));
}

export function logWarn(message: string, ctx: LogContext): void {
  logger.warn(message, sanitize(ctx));
}

export function logError(message: string, ctx: LogContext): void {
  logger.error(message, sanitize(ctx));
}

function sanitize(ctx: LogContext): Record<string, unknown> {
  const { err, ...rest } = ctx;
  if (err instanceof Error) {
    return { ...rest, errName: err.name, errMessage: err.message, errStack: err.stack };
  }
  if (err !== undefined) {
    return { ...rest, errSerialized: JSON.stringify(err) };
  }
  return rest;
}
