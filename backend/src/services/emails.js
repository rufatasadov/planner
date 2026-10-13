// Email texts in az / en / ru. Each builder returns { subject, html, text } for sendMail().

const T = {
  az: {
    hello: (name) => `Salam, ${name}!`,
    footer: 'Bu məktubu siz OneLinePlanner hesabı ilə bağlı aldınız. Əgər bu siz deyildinizsə, məktubu nəzərə almayın.',
    verify: {
      subject: 'Email ünvanınızı təsdiqləyin',
      text: 'OneLinePlanner-də qeydiyyat üçün təşəkkürlər. Email ünvanınızı təsdiqləmək üçün düyməyə klikləyin.',
      button: 'Emaili təsdiqlə',
      expires: 'Link 3 gün etibarlıdır.',
    },
    reset: {
      subject: 'Şifrənin bərpası',
      text: 'Şifrəni bərpa etmək üçün sorğu aldıq. Yeni şifrə təyin etmək üçün düyməyə klikləyin.',
      button: 'Yeni şifrə təyin et',
      expires: 'Link 1 saat etibarlıdır. Sorğunu siz göndərməmisinizsə, şifrəniz dəyişməyəcək.',
    },
  },
  en: {
    hello: (name) => `Hi ${name},`,
    footer: 'You received this email because of your OneLinePlanner account. If this was not you, just ignore it.',
    verify: {
      subject: 'Confirm your email address',
      text: 'Thanks for signing up for OneLinePlanner. Click the button to confirm your email address.',
      button: 'Confirm email',
      expires: 'The link is valid for 3 days.',
    },
    reset: {
      subject: 'Reset your password',
      text: 'We received a request to reset your password. Click the button to choose a new one.',
      button: 'Set a new password',
      expires: 'The link is valid for 1 hour. If you did not request this, your password will not change.',
    },
  },
  ru: {
    hello: (name) => `Здравствуйте, ${name}!`,
    footer: 'Вы получили это письмо из-за аккаунта OneLinePlanner. Если это были не вы, просто проигнорируйте его.',
    verify: {
      subject: 'Подтвердите email',
      text: 'Спасибо за регистрацию в OneLinePlanner. Нажмите кнопку, чтобы подтвердить адрес почты.',
      button: 'Подтвердить email',
      expires: 'Ссылка действительна 3 дня.',
    },
    reset: {
      subject: 'Восстановление пароля',
      text: 'Мы получили запрос на сброс пароля. Нажмите кнопку, чтобы задать новый пароль.',
      button: 'Задать новый пароль',
      expires: 'Ссылка действительна 1 час. Если вы не отправляли запрос, пароль не изменится.',
    },
  },
};

const esc = (s) =>
  String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);

function layout(lang, name, m, link) {
  const t = T[lang] ?? T.en;
  const html = `<!doctype html><html><body style="margin:0;background:#f4f4f7;font-family:-apple-system,Segoe UI,Roboto,Arial,sans-serif;color:#1f2937">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0"><tr><td align="center" style="padding:32px 16px">
<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:520px;background:#fff;border-radius:14px;padding:32px">
<tr><td style="font-size:20px;font-weight:700;padding-bottom:20px">OneLine<span style="color:#8b5cf6">Planner</span></td></tr>
<tr><td style="font-size:16px;padding-bottom:8px">${esc(t.hello(name))}</td></tr>
<tr><td style="font-size:15px;line-height:1.55;padding-bottom:24px">${esc(m.text)}</td></tr>
<tr><td style="padding-bottom:24px"><a href="${esc(link)}" style="display:inline-block;background:#6366f1;color:#fff;text-decoration:none;font-weight:600;padding:12px 22px;border-radius:10px">${esc(m.button)}</a></td></tr>
<tr><td style="font-size:13px;color:#6b7280;line-height:1.5;padding-bottom:8px">${esc(m.expires)}</td></tr>
<tr><td style="font-size:12px;color:#9ca3af;line-height:1.5;word-break:break-all;padding-bottom:16px">${esc(link)}</td></tr>
<tr><td style="font-size:12px;color:#9ca3af;line-height:1.5;border-top:1px solid #eee;padding-top:16px">${esc(t.footer)}</td></tr>
</table></td></tr></table></body></html>`;
  const text = `${t.hello(name)}\n\n${m.text}\n\n${link}\n\n${m.expires}\n\n${t.footer}`;
  return { subject: m.subject, html, text };
}

export const verifyEmailMail = (lang, name, link) => layout(lang, name, (T[lang] ?? T.en).verify, link);
export const resetPasswordMail = (lang, name, link) => layout(lang, name, (T[lang] ?? T.en).reset, link);
