// Abenotech 事業紹介サイトの問い合わせ API。
// API Gateway HTTP API（POST /contact）から起動され、次を行う:
//   1. リクエストボディ {email, message, turnstileToken} を検証
//   2. Cloudflare Turnstile のサーバ側検証（siteverify）で Bot を弾く
//   3. SES で運営宛（contact@）へ通知メールを送信（Reply-To に問い合わせ者を設定）
//
// nodejs22.x 同梱の AWS SDK v3 を使い、依存追加なしの自己完結 ESM（lambda/ses-forward と同方針）。
//
// メール到達フロー（既存資産の再利用）:
//   From = noreply@<domain>（検証済み）/ To = contact@<domain>（検証済み identity）。
//   contact@ 宛は既存 SES 受信ルール（ses-inbound.tf）が S3 保存 → 転送 Lambda → 運営 Gmail。
//   Reply-To に問い合わせ者を入れておくことで、Gmail からの返信が本人に届く（既存 SMTP 返信構成）。

import { SESv2Client, SendEmailCommand } from '@aws-sdk/client-sesv2';
import { GetParameterCommand, SSMClient } from '@aws-sdk/client-ssm';

const SITEVERIFY_URL = 'https://challenges.cloudflare.com/turnstile/v0/siteverify';

const ses = new SESv2Client({ region: process.env.AWS_REGION });
const ssm = new SSMClient({ region: process.env.AWS_REGION });

// 許可オリジン（CORS レスポンスヘッダ用）。サイトは複数ホスト名で配信するためリストで受け取る。
const ALLOW_ORIGINS = (process.env.ALLOW_ORIGINS ?? '')
  .split(',')
  .map((s) => s.trim())
  .filter(Boolean);

// Turnstile シークレットはモジュールスコープでキャッシュ（コールドスタート後 1 回だけ取得）。
let secretPromise = null;

function getTurnstileSecret() {
  if (!secretPromise) {
    secretPromise = (async () => {
      try {
        const name = process.env.TURNSTILE_SECRET_SSM_NAME;
        const res = await ssm.send(new GetParameterCommand({ Name: name, WithDecryption: true }));
        const value = res.Parameter?.Value;
        if (!value) {
          throw new Error(`SSM parameter is empty: ${name}`);
        }
        return value;
      } catch (e) {
        secretPromise = null; // 失敗はキャッシュしない（次回リトライ可能に）。
        throw e;
      }
    })();
  }
  return secretPromise;
}

// Cloudflare siteverify にトークンを送り、成功なら true。トークン不正・期限切れ等は false。
// ネットワーク断・SSM 取得失敗などの想定外は throw（呼び出し側で 500）。
async function verifyTurnstileToken(token, remoteIp) {
  const secret = await getTurnstileSecret();

  const params = new URLSearchParams();
  params.set('secret', secret);
  params.set('response', token);
  if (remoteIp) {
    params.set('remoteip', remoteIp);
  }

  const res = await fetch(SITEVERIFY_URL, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body: params.toString(),
  });

  const data = await res.json();
  if (data.success !== true) {
    console.warn('turnstile verification failed', JSON.stringify(data['error-codes'] ?? []));
    return false;
  }
  return true;
}

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function corsHeaders(allowOrigin) {
  return {
    'content-type': 'application/json',
    'access-control-allow-origin': allowOrigin,
    'access-control-allow-methods': 'POST,OPTIONS',
    'access-control-allow-headers': 'content-type',
    // オリジンによって応答ヘッダが変わることを中間キャッシュに伝える。
    vary: 'Origin',
  };
}

// リクエストの Origin が許可リストにあればエコーバックする。
// 未知・欠落の場合は先頭の許可オリジンを返し、ブラウザ側で弾かせる。
// HTTP API（payload format 2.0）はヘッダ名を小文字へ正規化するため origin 固定で参照してよい。
function resolveAllowOrigin(event) {
  const origin = event?.headers?.origin;
  return ALLOW_ORIGINS.includes(origin) ? origin : ALLOW_ORIGINS[0];
}

// 許可オリジンを束ねたレスポンス生成関数を返す。
function responder(allowOrigin) {
  return (statusCode, body) => ({
    statusCode,
    headers: corsHeaders(allowOrigin),
    body: JSON.stringify(body),
  });
}

export const handler = async (event) => {
  const response = responder(resolveAllowOrigin(event));

  // CORS プリフライト（HTTP API の CORS 設定が主だが保険として応答）。
  const method = event?.requestContext?.http?.method;
  if (method === 'OPTIONS') {
    return response(204, {});
  }

  let body;
  try {
    body = JSON.parse(event?.body ?? '{}');
  } catch {
    return response(400, { ok: false, error: 'invalid JSON body' });
  }

  const email = typeof body.email === 'string' ? body.email.trim() : '';
  const message = typeof body.message === 'string' ? body.message.trim() : '';
  const turnstileToken = typeof body.turnstileToken === 'string' ? body.turnstileToken : '';

  if (!EMAIL_RE.test(email) || email.length > 254) {
    return response(400, { ok: false, error: 'invalid email' });
  }
  if (message.length < 10 || message.length > 2000) {
    return response(400, { ok: false, error: 'invalid message' });
  }
  if (!turnstileToken) {
    return response(400, { ok: false, error: 'missing turnstile token' });
  }

  const sourceIp = event?.requestContext?.http?.sourceIp;
  const verified = await verifyTurnstileToken(turnstileToken, sourceIp);
  if (!verified) {
    return response(400, { ok: false, error: 'turnstile verification failed' });
  }

  const from = process.env.CONTACT_MAIL_FROM;
  const to = process.env.CONTACT_MAIL_TO;
  const subject = process.env.CONTACT_MAIL_SUBJECT;

  const text = [
    'お問い合わせ内容:',
    message,
  ].join('\n');

  await ses.send(
    new SendEmailCommand({
      FromEmailAddress: from,
      Destination: { ToAddresses: [to] },
      ReplyToAddresses: [email],
      Content: {
        Simple: {
          Subject: { Data: subject, Charset: 'UTF-8' },
          Body: { Text: { Data: text, Charset: 'UTF-8' } },
        },
      },
    })
  );

  return response(200, { ok: true });
};
