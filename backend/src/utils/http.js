export class HttpError extends Error {
  constructor(status, message, details) {
    super(message);
    this.status = status;
    this.details = details;
  }
}

export const badRequest = (msg, details) => new HttpError(400, msg, details);
export const notFound = (msg = 'Tapılmadı') => new HttpError(404, msg);
export const conflict = (msg, details) => new HttpError(409, msg, details);

export function requireInt(value, name, { min, max } = {}) {
  const n = Number(value);
  if (!Number.isInteger(n)) throw badRequest(`${name} tam ədəd olmalıdır`);
  if (min !== undefined && n < min) throw badRequest(`${name} ${min}-dən kiçik ola bilməz`);
  if (max !== undefined && n > max) throw badRequest(`${name} ${max}-dən böyük ola bilməz`);
  return n;
}

export function requireDate(value, name = 'date') {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    throw badRequest(`${name} YYYY-MM-DD formatında olmalıdır`);
  }
  return value;
}

export function requireString(value, name, { max = 500, allowEmpty = false } = {}) {
  if (typeof value !== 'string') throw badRequest(`${name} tələb olunur`);
  const v = value.trim();
  if (!allowEmpty && !v) throw badRequest(`${name} boş ola bilməz`);
  if (v.length > max) throw badRequest(`${name} çox uzundur`);
  return v;
}
