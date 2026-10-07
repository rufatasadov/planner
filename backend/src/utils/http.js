// `key` is a message key from i18n.js; it is translated by the error handler using Accept-Language.
export class HttpError extends Error {
  constructor(status, key, params = {}, details) {
    super(key);
    this.status = status;
    this.key = key;
    this.params = params;
    this.details = details;
  }
}

export const badRequest = (key, params, details) => new HttpError(400, key, params, details);
export const unauthorized = (key = 'auth.required') => new HttpError(401, key);
export const notFound = (key = 'common.notFound') => new HttpError(404, key);
export const conflict = (key, params, details) => new HttpError(409, key, params, details);

export function requireInt(value, name, { min, max } = {}) {
  const n = Number(value);
  if (!Number.isInteger(n)) throw badRequest('validation.int', { name });
  if (min !== undefined && n < min) throw badRequest('validation.min', { name, min });
  if (max !== undefined && n > max) throw badRequest('validation.max', { name, max });
  return n;
}

export function requireDate(value, name = 'date') {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw badRequest('validation.date', { name });
  }
  return value;
}

export function requireString(value, name, { max = 500, allowEmpty = false } = {}) {
  if (typeof value !== 'string') throw badRequest('validation.required', { name });
  const v = value.trim();
  if (!allowEmpty && !v) throw badRequest('validation.empty', { name });
  if (v.length > max) throw badRequest('validation.tooLong', { name });
  return v;
}

export function requireOneOf(value, name, values) {
  if (!values.includes(value)) throw badRequest('validation.oneOf', { name, values: values.join(', ') });
  return value;
}
