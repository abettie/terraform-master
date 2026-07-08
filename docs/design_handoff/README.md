# Handoff: Abenotech 事業紹介サイト

## Overview
アベノテック（Abenotech／個人事業主）の事業紹介Webサイト。日本語のみ・1ページ完結のランディングページと、独立した「お問い合わせ」「プライバシーポリシー」の計3ページで構成される。トーンは「モダンテック・ブルー系・信頼感」。

## About the Design Files
このバンドルに含まれる `.dc.html` ファイルは、**HTMLで作成したデザインリファレンス（プロトタイプ）** です。見た目と挙動の意図を示すもので、そのまま本番コードとして流用する前提のものではありません。

タスクは、これらのHTMLデザインを**ターゲットとなるコードベースの既存環境（React / Next.js / Vue / 静的サイトジェネレータ等）の確立されたパターン・ライブラリを使って再現すること**です。環境がまだ存在しない場合は、プロジェクトに最適なフレームワークを選定して実装してください（例：静的な事業サイトであれば Next.js / Astro などが好適）。

なお `.dc.html` は内製のプレビュー用フォーマットです。ロジックはごく僅か（お問い合わせフォームの送信完了トグルのみ）なので、マークアップとインラインスタイルを設計仕様として読み取ってください。

## Fidelity
**High-fidelity (hifi)** — 最終的な配色・タイポグラフィ・余白・インタラクションを含むピクセル準拠のモックアップです。UIは既存ライブラリ・パターンを使って忠実に再現してください。

## サイト構成 / ページ
1. **Home**（`Abenotech.dc.html`）— ヒーロー、事業内容（3件）、実績（Coming soon）、お問い合わせCTA、フッター
2. **Contact**（`Contact.dc.html`）— お問い合わせフォーム（メールアドレス＋内容）。送信は仮動作（完了メッセージ表示）
3. **Privacy**（`Privacy.dc.html`）— プライバシーポリシー（8項目）

ページ間はヘッダー／フッターのリンクで相互遷移。ホームのヘッダーCTAとヒーローCTAから Contact へ、フッターから Privacy／Contact へ。

---

## Screens / Views

### 1. Home（`Abenotech.dc.html`）

**Purpose**: 事業内容を伝え、問い合わせへ誘導する。

**Layout**（全体）
- 背景：`#F6F7F9`。本文最大幅コンテナ `max-width: 1120px; margin: 0 auto; padding: 0 40px`。
- 縦順：sticky ヘッダー → ヒーロー → 事業内容 → 実績 → お問い合わせCTA → フッター。

**Header（sticky）**
- `position: sticky; top: 0; z-index: 20`、背景 `rgba(246,247,249,.85)` + `backdrop-filter: blur(10px)`、下線 `1px solid #E9EBEF`。
- 内側：`max-width:1120px; padding: 20px 40px`、`display:flex; justify-content:space-between; align-items:center`。
- 左：ロゴ。`Abenotech`（20px / 700 / letter-spacing:-.01em / `#0F1320`）＋ 隣に `アベノテック`（12px / `#8A8F98`、baseline揃え、gap 10px）。ホームへリンク。
- 右：nav。`display:flex; gap:30px; font-size:14px`。リンク「事業内容」`#services`、「実績」`#works`（色 `#3B4252`）、CTAボタン「お問い合わせ」→ Contact（背景 `#1D4ED8`／文字 `#fff`／`padding:9px 18px`／`border-radius:8px`／weight 600）。

**Hero**
- `padding: 88px 40px 76px`、`display:grid; grid-template-columns: 1.1fr .9fr; gap: 48px; align-items:center`。
- 左カラム：
  - H1「モバイルとクラウドで、<br>アイデアを、動かす。」`font-size:54px; line-height:1.2; font-weight:700; letter-spacing:-.02em; color:#0B0E16; margin:0 0 24px`。
  - 段落：「アベノテックは、スマートフォンアプリの企画・開発から、AWSインフラの構築、Web開発までを一貫して支援する個人事業です。」`font-size:17px; line-height:1.9; color:#4B5262; max-width:520px; margin:0 0 36px`。
  - ボタン群 `display:flex; gap:14px`：
    - Primary「お問い合わせ →」→ Contact。`background:#1D4ED8; color:#fff; padding:15px 28px; border-radius:10px; font-size:15px; font-weight:600`。
    - Secondary「事業内容を見る」`#services`。`padding:15px 24px; border-radius:10px; border:1px solid #D3D7DF; color:#0F1320; font-weight:500`。
- 右カラム：プレースホルダー画像枠（**実プロダクト画像を差し込む箇所**）。`height:400px; border-radius:16px; border:1px solid #E5E7EB`、背景はストライプ `repeating-linear-gradient(135deg,#EEF1F6 0 14px,#E6EAF1 14px 28px)`、中央にモノスペースのラベル `product / UI shot`（12px / `#9AA0AC`）。右上に青いドット `12px` `#1D4ED8`（pulseDotアニメーション）。

**Services（`#services`）**
- セクション背景 `#fff`、上下 `1px solid #E9EBEF`、内側 `padding:72px 40px`。
- 見出し行：`display:flex; justify-content:space-between; align-items:baseline; margin-bottom:44px`。左に kicker「SERVICES」（monospace 12px / letter-spacing .18em / `#1D4ED8`）＋ H2「事業内容」（34px / 700 / `#0B0E16`）。※右側のリード文は削除済み（無し）。
- カード3枚：`display:grid; grid-template-columns:repeat(3,1fr); gap:22px`。各カード `border:1px solid #E5E7EB; border-radius:14px; padding:32px; background:#FBFCFD`。
  - 番号（monospace 13px / `#1D4ED8` / margin-bottom 24px）
  - タイトル（21px / 700 / `#0B0E16`）
  - 英語ラベル（monospace 11px / letter-spacing .06em / `#9AA0AC` / margin-bottom 16px）
  - 説明（14px / line-height 1.85 / `#4B5262`）
  - **01 アプリ開発** / `MOBILE APP DEV` / 「Android・iPhoneアプリの企画・開発・運営。ネイティブアプリを一貫して手掛けます。」
  - **02 AWSインフラ構築** / `AWS INFRASTRUCTURE` / 「AWS上でのインフラ構築を支援。スケーラブルで安定した基盤を設計します。」
  - **03 Web開発** / `WEB DEVELOPMENT` / 「Webアプリケーションの開発支援。モダンな技術で使いやすいプロダクトを。」

**Works（`#works`）**
- `padding:84px 40px; text-align:center`。
- kicker「WORKS」→ H2「実績」（32px / 700）。
- バッジ：`display:inline-flex; align-items:center; gap:12px; padding:18px 34px; border:1px dashed #C4C9D2; border-radius:12px; background:#fff`。青ドット `8px`（pulseDot）＋「Coming soon」（18px / 600 / `#0B0E16`）。
- 補足：「実績は現在準備中です。近日公開予定。」（14px / `#6B7280` / margin-top 20px）。

**Contact CTA**
- コンテナ `padding:0 40px 84px`。中のバンド：`background:#0E2A6B; border-radius:18px; padding:56px; display:flex; justify-content:space-between; align-items:center; gap:24px; flex-wrap:wrap`。
- 左：kicker「CONTACT」（monospace / `#9DB4FF`）＋ H2「お問い合わせ」（30px / 700 / `#fff`）。※補足文は削除済み。
- 右：ボタン「問い合わせフォームへ →」→ Contact。`background:#fff; color:#0E2A6B; padding:16px 30px; border-radius:10px; font-weight:600`。

**Footer**
- `background:#fff; border-top:1px solid #E9EBEF`。内側 `max-width:1120px; padding:32px 40px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:16px`。
- 左：`Abenotech`（700 / `#0B0E16`）。右：リンク「プライバシーポリシー」→ Privacy、「お問い合わせ」→ Contact、`© 2026 Abenotech`（すべて 13px / `#6B7280`）。

---

### 2. Contact（`Contact.dc.html`）

**Purpose**: メールアドレスと問い合わせ内容を送信する。

**Layout**
- ページ全体 `display:flex; flex-direction:column; min-height:100vh`（フッター最下部固定のため）。背景 `#F6F7F9`。
- ヘッダー：ホームと同構成だが右側は「← ホームに戻る」リンク（14px / `#3B4252`）のみ。
- main：`flex:1; max-width:640px; margin:0 auto; padding:72px 40px 96px`。

**Contents**
- kicker「CONTACT」→ H1「お問い合わせ」（38px / 700 / letter-spacing -.02em / `#0B0E16`）。※説明文は削除済み（H1の下は直接フォーム、margin 44px）。
- フォームカード：`background:#fff; border:1px solid #E5E7EB; border-radius:16px; padding:40px`。
  - フィールド「メールアドレス *」：label（14px / 600 / `#0B0E16` / margin-bottom 10px、`*` は `#1D4ED8`）。`input[type=email] required`、placeholder `you@example.com`。`width:100%; padding:14px 16px; border:1px solid #D3D7DF; border-radius:10px; font-size:15px; background:#FBFCFD`。margin-bottom 28px。
  - フィールド「お問い合わせ内容 *」：`textarea required rows=7`、placeholder「ご相談内容をご記入ください。」同スタイル＋`line-height:1.8; resize:vertical`。margin-bottom 32px。
  - 送信行：`display:flex; align-items:center; gap:16px; flex-wrap:wrap`。ボタン「送信する →」（`background:#1D4ED8; color:#fff; padding:15px 32px; border-radius:10px; weight 600`）＋ 注記「送信をもってプライバシーポリシーに同意したものとみなします。」（13px / `#8A8F98`、「プライバシーポリシー」は Privacy へのリンク）。
- **フォーカス状態**（CSS）：`input:focus, textarea:focus { outline:none; border-color:#1D4ED8; box-shadow:0 0 0 3px rgba(29,78,216,.12); }`。placeholder色 `#9AA0AC`。
- **送信完了状態**（下記 State 参照）：カードが完了メッセージに差し替わる。丸アイコン `56px`・背景 `#EAF0FF`・文字 `#1D4ED8`・チェック「✓」26px、H2「送信が完了しました」（22px / 700）、本文「お問い合わせありがとうございます。内容を確認のうえ、ご入力いただいたメールアドレスへ折り返しご連絡いたします。」、ボタン「続けて問い合わせる」（青）。中央寄せ。
- フッター：ホームと同一（プライバシーポリシー／© のみ）。

---

### 3. Privacy（`Privacy.dc.html`）

**Purpose**: 個人情報の取り扱い方針を掲示する。

**Layout**
- ヘッダー／フッターは Contact と同一。main：`flex:1; max-width:760px; margin:0 auto; padding:72px 40px 96px`。
- kicker「PRIVACY POLICY」→ H1「プライバシーポリシー」（38px / 700）。
- 導入文（15px / line-height 1.9 / `#4B5262`）＋ 「最終改定日：2026年7月8日」（monospace 12px / `#9AA0AC`、margin-bottom 48px）。
- 本文カード：`background:#fff; border:1px solid #E5E7EB; border-radius:16px; padding:8px 40px`。各項目は `<section>`、`padding:32px 0`、項目間に `border-bottom:1px solid #EEF0F3`（最終項目は無し）。
- 各 H2：`display:flex; align-items:baseline; gap:14px; font-size:19px; font-weight:700; color:#0B0E16`。先頭に番号（monospace 13px / `#1D4ED8`）。本文 15px / line-height 1.9 / `#4B5262`。
- 項目：01 事業者情報 / 02 取得する個人情報 / 03 利用目的 / 04 第三者提供 / 05 安全管理措置 / 06 開示・訂正・削除 / 07 改定について / 08 お問い合わせ窓口（本文内に Contact へのリンク）。本文全文は `Privacy.dc.html` を参照。

---

## Interactions & Behavior
- **ナビゲーション**：`<a>` による通常遷移。ホーム内リンクは `#services` / `#works` へのアンカースクロール。ページ間は各 `.dc.html`（実装時はルーティングパス）へ。
- **お問い合わせフォーム送信（仮動作）**：`onSubmit` で `preventDefault()` し、送信完了ビューへ切り替えるのみ。**実際のメール送信は未実装**。本番ではメール送信API（例：フォームバックエンド、SES、メール送信サービス等）との連携が必要。
- **フォーカス**：入力欄フォーカスで青ボーダー＋青フォーカスリング。
- **アニメーション**：ヒーロー右のドット、Works のドットが `pulseDot`（opacity .3↔1 / scale 1↔1.25、ease-in-out、2s・1.5s、infinite）。
- **リンク hover**：`a:hover { opacity:.72; }`。
- **レスポンシブ**：現状のモックはデスクトップ幅前提。ヒーロー／事業内容のグリッドと最大幅コンテナはモバイルで1カラムに折り返す実装を推奨（コンテナ幅・グリッド列をブレークポイントで切替）。

## State Management
- Contact ページのみ状態を持つ：`sent: boolean`（初期 false）。
  - `submit`：`preventDefault()` → `sent = true`（完了ビュー表示）
  - `reset`：「続けて問い合わせる」で `sent = false`（フォームへ戻す）
- 他ページは状態なし。

## Design Tokens
**Colors**
- 背景（ページ）：`#F6F7F9`
- 背景（面・カード）：`#FFFFFF` / カード内 `#FBFCFD`
- テキスト濃（見出し）：`#0B0E16` / `#0F1320`
- テキスト本文：`#4B5262`
- テキスト補助：`#6B7280` / `#8A8F98`
- モノラベル：`#9AA0AC`
- プライマリ（ブルー）：`#1D4ED8`
- ダークネイビー（CTAバンド）：`#0E2A6B`、その上のkicker `#9DB4FF`、本文 `#C4D2FF`
- ボーダー：`#E9EBEF` / `#E5E7EB` / `#D3D7DF`（入力）/ `#EEF0F3`（区切り）/ `#C4C9D2`（dashed）
- フォーカスリング：`rgba(29,78,216,.12)`

**Typography**
- 本文フォント：`IBM Plex Sans JP`（400/500/600/700）
- ラベル・数字：`IBM Plex Mono`（400/500）
- スケール：H1 54px（Contact/Privacy 38px）、H2 30–34px、H3 21px、本文 15–17px、補助 13–14px、モノラベル 11–13px。
- letter-spacing：見出し -.02em、モノkicker .18em、英語ラベル .06em。line-height 本文 1.85–1.9。

**Spacing**
- コンテナ最大幅：1120px（Contact 640px / Privacy 760px）。左右パディング 40px。
- セクション縦パディング：72–88px 系。カード内 32–40px。gap：カード22px、ボタン14px。

**Radius / Shadow**
- radius：ボタン 8–10px、カード 14–16px、CTAバンド 18px、ピル 999px、ドット 50%。
- shadow：モックでは強い影は不使用（sticky ヘッダーは blur 背景で表現）。

## Assets
- 画像アセットは未使用。**ヒーロー右の枠は実プロダクト/UI画像を差し込むプレースホルダー**（ストライプ背景＋`product / UI shot` ラベル）。実画像が用意でき次第、`object-fit:cover` で差し込む想定。
- アイコン類は未使用（矢印は文字「→」、チェックは「✓」）。必要に応じてコードベースのアイコンライブラリに置換可。
- フォントは Google Fonts（IBM Plex Sans JP / IBM Plex Mono）。

## Files
- `Abenotech.dc.html` — ホーム
- `Contact.dc.html` — お問い合わせ
- `Privacy.dc.html` — プライバシーポリシー

（`.dc.html` は内製プレビュー形式。`<helmet>` 内にフォント読込・リセット・keyframes、本体はインラインスタイルのマークアップ、末尾にわずかなロジッククラスが入る。設計値の正はマークアップのインラインスタイルを参照のこと。）
