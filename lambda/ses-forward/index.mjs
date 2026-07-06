// SES Inbound（メール受信）で S3 に保存された生メールを読み、宛先を運営の Gmail へ
// 付け替えて SES で再送信（転送）する。AWS 公式パターン
// 「Forward Incoming Email to an External Destination」に準拠する。
//
// nodejs22.x に同梱の AWS SDK v3 を使い、依存追加なし（自己完結の ESM）。
//
// 再送信時のポイント:
// - From は必ず検証済み identity（CONTACT_MAIL_FROM = noreply@<domain>）に書き換える。
//   SES は送信元 From を検証済みアドレスに限定するため、元 From のままでは送れない。
// - 元の差出人は Reply-To に退避する（Gmail から返信すると相手本人に届く）。
// - Return-Path / DKIM-Signature 等、再送で不整合になるヘッダは除去する。
// - 本文・添付（multipart）はトップレベルヘッダのみ触るため保持される。
// - バイト列は latin1（1:1 マッピング）で文字列化してヘッダのみ書き換え、そのまま
//   バイト列へ戻すことで、base64/8bit を含む添付を壊さない。

import { GetObjectCommand, S3Client } from '@aws-sdk/client-s3';
import { SESClient, SendRawEmailCommand } from '@aws-sdk/client-ses';

const s3 = new S3Client({ region: process.env.AWS_REGION });
const ses = new SESClient({ region: process.env.AWS_REGION });

// 再送信時に取り除くヘッダ（小文字で比較）。元メールの認証・経路情報は転送後に無効。
const HEADERS_TO_STRIP = new Set([
  'return-path',
  'sender',
  'message-id',
  'dkim-signature',
  'authentication-results',
  'received-spf',
  'received',
  'arc-authentication-results',
  'arc-message-signature',
  'arc-seal',
]);

// ヘッダブロックと本文を最初の空行で分割する。CRLF / LF のどちらにも対応する。
function splitHeadersAndBody(raw) {
  const crlf = raw.indexOf('\r\n\r\n');
  if (crlf !== -1) {
    return { headerBlock: raw.slice(0, crlf), body: raw.slice(crlf + 4), eol: '\r\n' };
  }
  const lf = raw.indexOf('\n\n');
  if (lf !== -1) {
    return { headerBlock: raw.slice(0, lf), body: raw.slice(lf + 2), eol: '\n' };
  }
  return { headerBlock: raw, body: '', eol: '\r\n' };
}

// 折り返し（先頭が空白の継続行）を 1 エントリにまとめてヘッダを列挙する。
function parseHeaderEntries(headerBlock, eol) {
  const entries = [];
  for (const line of headerBlock.split(/\r?\n/)) {
    if (/^[ \t]/.test(line) && entries.length > 0) {
      entries[entries.length - 1] += eol + line;
    } else {
      entries.push(line);
    }
  }
  return entries.filter((e) => e.trim() !== '');
}

function headerName(entry) {
  const colon = entry.indexOf(':');
  return colon === -1 ? '' : entry.slice(0, colon).trim().toLowerCase();
}

// 生メール（latin1 文字列）のヘッダを転送用に書き換えて返す。
export function rewriteForForwarding(raw, fromAddress) {
  const { headerBlock, body, eol } = splitHeadersAndBody(raw);
  const entries = parseHeaderEntries(headerBlock, eol);

  let originalFrom;
  let hasReplyTo = false;
  const kept = [];

  for (const entry of entries) {
    const name = headerName(entry);
    if (name === 'from') {
      // 折り返しを 1 行に畳んで元 From を退避しつつ、From 自体は差し替える。
      originalFrom = entry
        .slice(entry.indexOf(':') + 1)
        .replace(/\r?\n[ \t]+/g, ' ')
        .trim();
      kept.push(`From: contact <${fromAddress}>`);
      continue;
    }
    if (name === 'reply-to') {
      hasReplyTo = true;
      kept.push(entry);
      continue;
    }
    if (HEADERS_TO_STRIP.has(name)) {
      continue;
    }
    kept.push(entry);
  }

  // 元メールに Reply-To が無ければ、元差出人を Reply-To に設定する。
  if (!hasReplyTo && originalFrom) {
    kept.unshift(`Reply-To: ${originalFrom}`);
  }

  return kept.join(eol) + eol + eol + body;
}

// messageId をキーに S3 から生メールを取得し、転送用に書き換えて SES で再送信する。
async function forwardInboundEmail(messageId) {
  const bucket = process.env.SES_INBOUND_BUCKET;
  const prefix = process.env.SES_INBOUND_PREFIX ?? '';
  const fromAddress = process.env.CONTACT_MAIL_FROM;
  const forwardTo = process.env.CONTACT_FORWARD_TO;

  if (!bucket) throw new Error('SES_INBOUND_BUCKET is not set');
  if (!fromAddress) throw new Error('CONTACT_MAIL_FROM is not set');
  if (!forwardTo) throw new Error('CONTACT_FORWARD_TO is not set');

  const key = `${prefix}${messageId}`;

  const object = await s3.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
  if (!object.Body) {
    throw new Error(`Inbound email object has empty body: s3://${bucket}/${key}`);
  }
  const bytes = await object.Body.transformToByteArray();
  // latin1 は 1 バイト = 1 コードポイントで往復可能。添付のバイト列を壊さない。
  const raw = Buffer.from(bytes).toString('latin1');

  const forwarded = rewriteForForwarding(raw, fromAddress);

  await ses.send(
    new SendRawEmailCommand({
      Source: fromAddress,
      Destinations: [forwardTo],
      RawMessage: { Data: Buffer.from(forwarded, 'latin1') },
    }),
  );

  console.info(JSON.stringify({ msg: 'forwarded inbound email', messageId, key, forwardTo }));
}

// SES Inbound の受信ルール（LambdaAction）から起動される転送ハンドラ。
// 受信ルールは事前に S3Action で生メールを s3://<bucket>/<prefix><messageId> に保存済み。
export const handler = async (event) => {
  for (const record of event.Records) {
    const messageId = record.ses.mail.messageId;
    try {
      await forwardInboundEmail(messageId);
    } catch (err) {
      // throw して非同期起動のリトライ／失敗として扱う（原因調査は CloudWatch Logs で行う）。
      console.error(JSON.stringify({ msg: 'failed to forward inbound email', messageId, err: String(err) }));
      throw err;
    }
  }
};
