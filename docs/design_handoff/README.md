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
1. **Home**（`Abenotech.dc.html`）— ヒーロー（うちの子語録のアプリ画面）、事業内容（3件）、実績（うちの子語録）、お問い合わせCTA、フッター（商標表記つき）

> **更新履歴（2026-11-03）**：ヒーロー右のプレースホルダーを「うちの子語録」の実画面モックに差し替え／実績セクションを Coming soon から「うちの子語録」の紹介カード＋スクリーンショット3枚に変更／H1 の改行制御を追加／フッターに Apple・Google の商標表記を追加／`assets/` を新設。Contact・Privacy は変更なし。
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
  - H1「モバイルとクラウドで、<br>アイデアを、動かす。」`font-size:clamp(28px,4.6vw,50px); line-height:1.3; font-weight:700; letter-spacing:-.02em; color:#0B0E16; margin:0 0 24px; word-break:keep-all`。
    - **改行制御**：「モバイルと」「クラウドで、」「アイデアを、」「動かす。」をそれぞれ `display:inline-block` の `<span>` で包み、文節の途中で折り返さないようにしている（「動か／す。」のような改行を防ぐ）。「、」の後の `<br>` は意図的な改行。
  - 段落：「アベノテックは、スマートフォンアプリの企画・開発から、AWSインフラの構築、Web開発までを一貫して支援する個人事業です。」`font-size:17px; line-height:1.9; color:#4B5262; max-width:520px; margin:0 0 36px`。
  - ボタン群 `display:flex; gap:14px`：
    - Primary「お問い合わせ →」→ Contact。`background:#1D4ED8; color:#fff; padding:15px 28px; border-radius:10px; font-size:15px; font-weight:600`。
    - Secondary「事業内容を見る」`#services`。`padding:15px 24px; border-radius:10px; border:1px solid #D3D7DF; color:#0F1320; font-weight:500`。
- 右カラム：**「うちの子語録」のプロダクトビジュアル**。枠全体が `#works` へのリンク（`<a>`）。
  - 枠：`height:clamp(340px,42vw,420px); border-radius:16px; border:1px solid #E5E7EB; overflow:hidden`、背景はアプリアイコンに合わせた水色グラデーション `linear-gradient(160deg,#C9ECF5 0%,#A8DFEE 55%,#99D9EA 100%)`。
  - スマホモック：中央上寄せ（`left:50%; top:34px; translateX(-50%)`）、`220×440px`、外枠 `#0F1320` / `border-radius:34px` / `padding:9px` / `box-shadow:0 24px 48px rgba(20,80,110,.25)`。画面部 `border-radius:26px`、中に `assets/shot-feed.jpg`（「みんなの投稿」画面）を `object-fit:cover; object-position:top`。下部は枠で見切れる。
  - アプリ情報チップ：左下（`left/bottom: clamp(16–20px, 4vw, 32px)`）、`background:rgba(255,255,255,.88); backdrop-filter:blur(8px); border-radius:16px; padding:10px 16px 10px 10px; box-shadow:0 8px 24px rgba(20,80,110,.16)`。アイコン `assets/kidsword-icon.png` 52px（radius 13px）＋「うちの子語録」（14px / 700）＋「iOS / Android で公開中」（11px / `#6B7280`）。
  - 右上ドット：`12px` `#F5913A`（アイコンの吹き出しに合わせたオレンジ、pulseDot 2s）。

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
- `padding:84px 40px`（左寄せ。旧版の `text-align:center` と Coming soon バッジは廃止）。
- kicker「WORKS」→ H2「実績」（34px / 700 / margin-bottom 40px）。Services と同じ見出しスタイル。
- **紹介カード**：`display:grid; grid-template-columns:repeat(auto-fit,minmax(280px,1fr)); border:1px solid #E5E7EB; border-radius:18px; overflow:hidden; background:#fff`。
  - 左パネル：水色グラデーション（ヒーローと同じ）、中央にアプリアイコン `assets/kidsword-icon.png`（`clamp(128px,17vw,160px)` 角、`border-radius:22%`、`box-shadow:0 18px 40px rgba(20,80,110,.25), 0 0 0 1px rgba(255,255,255,.6)`）。
  - 右パネル（`padding:clamp(28px,4vw,44px)`）：
    - メタ行：`MOBILE APP ・ 2026`（monospace 11px / `#9AA0AC`）＋ステータスピル「iOS / Android 公開中」（11.5px / 600 / 文字 `#047857` / 背景 `#ECFDF5` / radius 999px / 先頭に緑ドット `#10B981` 6px）。
    - H3「うちの子語録」（26px / 700）。
    - 説明：「子どもの言い間違いや可愛い言葉を記録して、家族やほかのユーザーと共有できるアプリ。企画・デザインからアプリ実装、AWSのバックエンド構築、ストア申請・リリースまでを一人で手掛けました。」（15px / line-height 1.9 / `#4B5262`）。
    - 技術タグ（monospace 11.5px / `#3B4252` / 背景 `#F3F4F6` / radius 6px / gap 8px）：React Native / Expo、TypeScript、AWS Lambda、DynamoDB、S3、Firebase Auth、Terraform。
    - ストアバッジ（gap 12px、**App Store → Google Play の順**、どちらも `height:44px` で揃える）：
      - App Store：`assets/appstore_jp.svg` → https://apps.apple.com/jp/app/%E3%81%86%E3%81%A1%E3%81%AE%E5%AD%90%E8%AA%9E%E9%8C%B2/id6806550328
      - Google Play：`assets/googleplay_jp.svg` → https://play.google.com/store/apps/details?id=work.makedara.kidsword
      - いずれも `target="_blank" rel="noopener"`。
    - テキストリンク「アプリサイトを見る →」→ https://kidsword.makedara.work（14px / 600 / `#1D4ED8`）。
- **スクリーンショット列**：カードの下（margin-top `clamp(28px,4vw,40px)`）。`display:grid; grid-template-columns:repeat(auto-fit,minmax(200px,1fr)); gap:clamp(20px,3vw,32px); padding:clamp(28px,4vw,44px); border-radius:18px; background:#FAF5EB; border:1px solid #EFE6D6`（アプリ本体のクリーム色に合わせた面）。
  - 各 `<figure>`：スマホ枠（`max-width:220px; border-radius:28px; background:#0F1320; padding:7px; box-shadow:0 14px 32px rgba(90,60,30,.16)`）＋画像（`aspect-ratio:600/1273; border-radius:22px; loading=lazy`）＋キャプション（13px / `#4B5262`、1行目は太字 `#0B0E16`）。
  - 1. `shot-detail.jpg`「子どもごとの記録」／エピソードや写真と一緒に残せる
  - 2. `shot-post.jpg`「かんたん投稿」／言い間違いと正しい言葉を入れるだけ
  - 3. `shot-mypage.jpg`「きょうだいにも対応」／お子さまごとに名前とアイコンを設定

**Contact CTA**
- コンテナ `padding:0 40px 84px`。中のバンド：`background:#0E2A6B; border-radius:18px; padding:56px; display:flex; justify-content:space-between; align-items:center; gap:24px; flex-wrap:wrap`。
- 左：kicker「CONTACT」（monospace / `#9DB4FF`）＋ H2「お問い合わせ」（30px / 700 / `#fff`）。※補足文は削除済み。
- 右：ボタン「問い合わせフォームへ →」→ Contact。`background:#fff; color:#0E2A6B; padding:16px 30px; border-radius:10px; font-weight:600`。

**Footer**
- `background:#fff; border-top:1px solid #E9EBEF`。内側 `max-width:1120px; padding:32px 40px; display:flex; justify-content:space-between; align-items:center; flex-wrap:wrap; gap:16px`。
- 左：`Abenotech`（700 / `#0B0E16`）。右：リンク「プライバシーポリシー」→ Privacy、「お問い合わせ」→ Contact、`© 2026 Abenotech`（すべて 13px / `#6B7280`）。
- **商標表記**（Home のみ、ストアバッジを使用しているため必須）：フッター行の下に `padding:0 40px 28px; font-size:11px; line-height:1.8; color:#9AA0AC` で
  「Apple、Apple ロゴ、App Store は、米国その他の国で登録された Apple Inc. の商標です。Google Play および Google Play ロゴは Google LLC の商標です。」

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
- **アニメーション**：ヒーロー右上のドットが `pulseDot`（opacity .3↔1 / scale 1↔1.25、ease-in-out、2s、infinite）。
- **外部リンク**：ストアバッジ・アプリサイトは新規タブ（`target="_blank" rel="noopener"`）。ヒーローのビジュアル全体は `#works` へのアンカー。
- **リンク hover**：`a:hover { opacity:.72; }`。
- **レスポンシブ**：実装済み。メディアクエリを使わず `clamp()`（フォントサイズ・余白）と `grid-template-columns: repeat(auto-fit, minmax(...))`／`flex-wrap` で幅に応じて滑らかに追従。ヒーローは `minmax(300px,1fr)` の auto-fit で狭幅時に2→1カラム、事業内容カードは `minmax(240px,1fr)` で3→2→1に自動段組み。ヘッダーnav・CTAバンド・フッターは `flex-wrap` で折り返す。左右パディングは `clamp(20px,5vw,40px)`。本番実装ではコードベースの流儀に合わせてメディアクエリへ置換しても、この intrinsic な方式を踏襲してもよい。

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
- うちの子語録（実績・ヒーロー用のアクセント）：水色グラデ `#C9ECF5 → #A8DFEE → #99D9EA`、オレンジ `#F5913A`、クリーム面 `#FAF5EB` / ボーダー `#EFE6D6`、公開中ピル `#ECFDF5` / `#047857` / `#10B981`、タグ背景 `#F3F4F6`

**Typography**
- 本文フォント：`IBM Plex Sans JP`（400/500/600/700）
- ラベル・数字：`IBM Plex Mono`（400/500）
- スケール：H1 最大50px（Contact/Privacy 38px）、H2 30–34px、H3 21px、本文 15–17px、補助 13–14px、モノラベル 11–13px。
- letter-spacing：見出し -.02em、モノkicker .18em、英語ラベル .06em。line-height 本文 1.85–1.9。

**Spacing**
- コンテナ最大幅：1120px（Contact 640px / Privacy 760px）。左右パディング 40px。
- セクション縦パディング：72–88px 系。カード内 32–40px。gap：カード22px、ボタン14px。

**Radius / Shadow**
- radius：ボタン 8–10px、カード 14–16px、CTAバンド 18px、ピル 999px、ドット 50%。
- shadow：モックでは強い影は不使用（sticky ヘッダーは blur 背景で表現）。

## Assets
画像は `assets/` に格納（Home のみ使用）。
- `kidsword-icon.png` — うちの子語録のアプリアイコン（512×512）
- `shot-feed.jpg` — 「みんなの投稿」画面（ヒーローのスマホモック用）
- `shot-detail.jpg` — 子どもごとの投稿一覧（写真付き投稿）
- `shot-post.jpg` — 新しい投稿の作成画面
- `shot-mypage.jpg` — マイページ（お子さま一覧）
  - スクリーンショットはいずれも 600×1273、上部のステータスバーをトリミング済み。
- `appstore_jp.svg` / `googleplay_jp.svg` — 公式ストアバッジ（日本語版）。**改変禁止**、高さ 40px 以上・周囲にバッジ高さの 1/4 以上の余白、App Store を先に配置、Google Play は他バッジと同等以上のサイズ（Apple / Google の各ガイドラインに準拠）。
- アイコン類は未使用（矢印は文字「→」、チェックは「✓」）。必要に応じてコードベースのアイコンライブラリに置換可。
- フォントは Google Fonts（IBM Plex Sans JP / IBM Plex Mono）。

## Files
- `Abenotech.dc.html` — ホーム
- `Contact.dc.html` — お問い合わせ
- `Privacy.dc.html` — プライバシーポリシー
- `assets/` — 画像・ストアバッジ（上記 Assets 参照）

（`.dc.html` は内製プレビュー形式。`<helmet>` 内にフォント読込・リセット・keyframes、本体はインラインスタイルのマークアップ、末尾にわずかなロジッククラスが入る。設計値の正はマークアップのインラインスタイルを参照のこと。）
