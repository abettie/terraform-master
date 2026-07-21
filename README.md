# master

## 概要

AWS Organizationのマスターアカウント用のTerraformソースです。

## 参考情報

AWS OrganizationsとIAM Identity Centerの詳細については、以下のドキュメントを参照してください。

- [AWS OrganizationsとIAM Identity Centerの詳細解説](docs/aws-organizations-iam-identity-center.md) - 概念の詳細説明

## セットアップ

Terraformを実行するために、ローカル環境に必要なツールをインストールし、AWS接続を設定します。

### AWS CLIのインストール

AWS CLIをインストールしてください。

- [AWS CLI インストールガイド](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### Terraformのインストール

Terraformをインストールしてください。

- [Terraform インストールガイド](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Terraform利用のためのAWSログイン

TerraformでAWSリソースを管理するためには、AWSへのログイン設定が必要です。詳細な手順については、以下のドキュメントを参照してください。

- [AWSログイン設定](docs/aws-login.md)

## 使い方

### 重要: Identity Centerの手動有効化について

IAM Identity Center (旧AWS SSO) の有効化はTerraformでは実行できないため、AWSコンソールから手動で有効化する必要があります。

#### 実行手順

1. **organizations.tfの実行**
   ```bash
   aws sso login --profile master
   export AWS_PROFILE=master && terraform init
   export AWS_PROFILE=master && terraform apply -target=aws_organizations_organization.main
   ```

2. **Identity Centerの手動有効化**
   - AWSコンソールにログイン
   - IAM Identity Centerサービスに移動
   - 「有効化」ボタンをクリックしてIdentity Centerを有効化
   - 有効化が完了するまで数分待機

3. **terraform.tfvarsの準備**
   - サンプルファイルをコピーして設定ファイルを作成:
     ```bash
     cp terraform.tfvars.example terraform.tfvars
     ```
   - `terraform.tfvars`を編集してpioneerユーザーのメールアドレスを設定:
     ```hcl
     pioneer_email = "your-email@yourdomain.com"
     ```
   - このファイルは`.gitignore`に含まれているため、git管理外となります

4. **残りのTerraform リソースの適用**
   ```bash
   aws sso login --profile master
   export AWS_PROFILE=master && terraform apply
   ```

5. **ユーザーのメールアドレス検証**
   - Terraformでユーザーを作成した後、そのユーザーでログインするにはメールアドレスの検証が必要です
   - AWSコンソールでIAM Identity Centerに移動
   - 「ユーザー」メニューからpioneerユーザーを選択
   - 「メールアドレスの検証を送信」をクリック
   - ユーザーが受信したメールから検証リンクをクリックして検証を完了
   - 検証完了後、パスワード設定の案内メールが送信されます

6. **パスワードリセット手順（ワンタイムパスワード方式）**
   - ユーザーがパスワードを忘れた場合や、パスワードを再設定する必要がある場合は、以下の手順でワンタイムパスワードを使用したリセットを行います
   - AWSコンソールでIAM Identity Centerに移動
   - 「ユーザー」メニューから対象のユーザーを選択
   - 「アクション」ボタンをクリックし、「ワンタイムパスワードを送信」を選択
   - ユーザーのメールアドレスにワンタイムパスワードが送信されます
   - ユーザーはIAM Identity Centerのログインページでユーザー名とワンタイムパスワードを入力してログイン
   - ログイン後、新しいパスワードの設定画面が表示されるので、新しいパスワードを設定して完了

### 重要: master.makedara.work のメール受信/送信設定について

`master.makedara.work` ドメインの問い合わせメール（`contact@master.makedara.work`）を
SES で受信し、`abechinoid+master@gmail.com` へ転送、Gmail の「他のアドレスから送信」で
`contact@` として返信できるようにする構成です。Route53 ホストゾーンの作成・親ドメインへの
NS 委任・SES サンドボックス解除・Gmail 設定は Terraform 管理外のため、以下を手動で実施します。

#### 実行手順

1. **Route53 ホストゾーンを手動作成**
   - マスターアカウントのコンソールで `makedara.work`（apex）と `master.makedara.work` の
     public hosted zone をそれぞれ作成
   - 払い出された Zone ID を `terraform.tfvars` の `makedara_zone_id` /
     `master_makedara_zone_id` に設定

2. **レジストラから apex へ NS 委任**
   - お名前ドットコムのネームサーバー設定を、`makedara.work` ゾーンの NS 4 本に変更する
   - `master.makedara.work` への委任は Terraform が `makedara.work` ゾーン内に NS レコード
     （`aws_route53_record.master_delegation`）として作成するため、レジストラ側の設定は不要

3. **terraform apply（ユーザーが実行）**
   ```bash
   aws sso login --profile master
   export AWS_PROFILE=master && terraform apply
   ```
   - SES identity・DKIM/MX/SPF/DMARC・受信用 S3・転送 Lambda・SMTP user が作成されます

4. **DKIM 検証待ち**
   - SES コンソールで identity が Verified になるまで待機（DNS 伝播後）

5. **SES サンドボックス解除申請**
   - 任意宛先（Gmail 転送・任意宛の返信）へ送るため、コンソール/サポートから
     プロダクションアクセスを申請する

6. **Gmail の「他のアドレスから送信」設定**
   - 設定 → アカウント → 「他のメールアドレスを追加」→ `contact@master.makedara.work`
   - SMTP サーバー: `email-smtp.ap-northeast-1.amazonaws.com`、ポート 587（TLS）
   - ユーザー名/パスワード:
     ```bash
     terraform output -raw ses_smtp_username
     terraform output -raw ses_smtp_password
     ```

7. **疎通確認**
   - `contact@master.makedara.work` にテスト送信 → Gmail に転送されること
   - Gmail から返信 → 元送信者に `contact@` 名義で届くことを確認

### 重要: Abenotech 事業紹介サイト（makedara.work / master.makedara.work）について

`https://makedara.work/` と `https://master.makedara.work/` の両方（同一 CloudFront
distribution・同一コンテンツ）で事業紹介サイト（静的 3 ページ）を配信し、問い合わせ
フォームは Cloudflare Turnstile で Bot を弾いたうえで SES メール通知します。配信は
CloudFront + S3（OAC）、問い合わせ API は API Gateway + Lambda 構成です。
静的コンテンツ（`web/` 配下）は Terraform では管理せず、`scripts/deploy-pages.sh` で配置します。
Turnstile ウィジェットの作成・シークレット投入・HTML への値埋め込みは手動で実施します。

#### 実行手順

1. **Cloudflare Turnstile ウィジェットを作成**
   - Cloudflare ダッシュボード → Turnstile で `master.makedara.work` 用ウィジェットを追加
   - 払い出された **Site Key**（公開値）と **Secret Key**（機密値）を控える
   - 既存ウィジェット（旧 `pages.master.makedara.work`）を流用する場合は、許可ホスト名に
     `master.makedara.work` を追加する。Site Key を変えないなら手順3・4 の差し替えは不要
   - サイトは 2 ホスト名で配信するため、許可ホスト名に **`makedara.work` も必ず追加**する
     （未追加だと apex 経由のフォーム送信で Turnstile が失敗する）

2. **terraform apply（ユーザーが実行）**
   ```bash
   aws sso login --profile master
   export AWS_PROFILE=master && terraform apply
   ```
   - 配信用 S3・CloudFront・ACM 証明書（us-east-1・DNS 検証は Route53 で自動）・
     問い合わせ API（API Gateway + Lambda）・Turnstile シークレット用 SSM パラメータが作成されます
   - ACM は DNS 検証完了まで apply が待機します（数分）

3. **Turnstile シークレットを SSM に投入**
   ```bash
   export AWS_PROFILE=master
   aws ssm put-parameter \
     --name /master/turnstile/secret-key \
     --type SecureString --overwrite \
     --value '<Cloudflare の Secret Key>'
   ```

4. **HTML にサイト固有値を埋め込む**
   - `web/contact.html` の `__TURNSTILE_SITE_KEY__` を手順1の Site Key に置換
   - `web/contact.html` の `__API_BASE__` を API エンドポイントに置換:
     ```bash
     terraform output -raw contact_api_endpoint
     ```

5. **静的コンテンツをデプロイ**
   ```bash
   export AWS_PROFILE=master && ./scripts/deploy-pages.sh
   ```
   - `web/` を配信バケットへ同期し、CloudFront キャッシュを無効化します

6. **疎通確認**
   - `https://master.makedara.work/` と `https://makedara.work/` の両方が HTTPS で表示され、
     3 ページを相互遷移できること
   - 両ホスト名の問い合わせフォームで Turnstile を通過し送信 → `contact@master.makedara.work`
     に通知が届き、既存の転送で運営 Gmail に届くこと。その返信が送信者に届くこと（Reply-To）

> 補足: 問い合わせ通知の宛先は検証済みの `contact@master.makedara.work` のため、
> SES サンドボックスのままでも通知メールは送信されます（既存の受信転送に相乗り）。

### Terraform初期化

作業ディレクトリでTerraformを初期化します。環境変数 `AWS_PROFILE` でプロファイル名を指定してください。

```bash
aws sso login --profile master
export AWS_PROFILE=master && terraform init
```
