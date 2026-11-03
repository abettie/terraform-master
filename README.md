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
   - マスターアカウントのコンソールで `makedara.work`（apex ドメイン）と `master.makedara.work` の
     public hosted zone をそれぞれ作成
   - 払い出された Zone ID を `terraform.tfvars` の `makedara_zone_id` /
     `master_makedara_zone_id` に設定

2. **レジストラから apex ドメインへ NS 委任**
   - お名前ドットコムのネームサーバー設定を、`makedara.work` ゾーンの NS 4 本に変更する
   - `master.makedara.work` への委任は Terraform が `makedara.work` ゾーン内に NS レコード
     （`aws_route53_record.master_delegation`）として作成するため、レジストラ側の設定は不要
   - `kidsword` / `kidsword-stg` / `multibook-stg` / `static` / `static-stg` の各サブドメインも
     同ゾーンから委任する（`aws_route53_record.subdomain_delegation`）。委任先ホストゾーンは
     各メンバーアカウント側にあり data 参照できないため、NS 値は `locals.tf` の
     `subdomain_delegations` に直接記述している。委任先ゾーンを作り直した場合はこの値の更新が必要

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

### 重要: Abenotech 事業紹介サイト（makedara.work、旧 master.makedara.work）について

`https://makedara.work/`（apex ドメイン）を正規 URL とする事業紹介サイト（静的 3 ページ）です。

- **配信**: CloudFront + S3（OAC）
- **問い合わせフォーム**: API Gateway + Lambda。Cloudflare Turnstile で Bot を弾き、SES でメール通知します
- **静的コンテンツ**: `web/` 配下。Terraform では管理せず、`scripts/deploy-pages.sh` で配置します

#### リダイレクト

apex ドメイン以外へのアクセスは、`https://makedara.work` へ 301 リダイレクトします（パス・クエリ文字列は維持）。

- **対象**: `master.makedara.work`、CloudFront デフォルトドメイン（`*.cloudfront.net`）
- **実装**: viewer-request の CloudFront Function（`aws_cloudfront_function.redirect_to_apex`、コード本体は `cloudfront-functions/redirect-to-apex.js.tftpl`）
- **削除してはいけないもの**: `master.makedara.work` の ACM SAN・Route53 ALIAS レコード（TLS ハンドシェイクに必要）

各ページの `<head>` にも、自己参照の `rel="canonical"` を入れています。

#### クローラー向けファイル

`web/robots.txt` と `web/sitemap.xml` を管理しています。どちらも Google Search Console に登録済みの `https://makedara.work/` を正規 URL として記載しています。

ページを追加・削除した場合は、`web/sitemap.xml` の `<url>` と `<lastmod>` を更新してください。

#### デプロイ手順

1. **静的コンテンツをデプロイ**
   ```bash
   aws sso login --profile master
   export AWS_PROFILE=master && ./scripts/deploy-pages.sh
   ```
   - `web/` を配信バケットへ同期し、CloudFront キャッシュを無効化します

2. **疎通確認**
   - `https://makedara.work/` が HTTPS で表示され、3 ページを相互遷移できること
   - `https://master.makedara.work/` へアクセスすると `https://makedara.work/` へ 301
     リダイレクトされること（`curl -sI https://master.makedara.work/ | grep -iE '^(HTTP|location)'`）
   - apex ドメイン上の問い合わせフォームで Turnstile を通過し送信 → `contact@master.makedara.work`
     に通知が届き、既存の転送で運営 Gmail に届くこと。その返信が送信者に届くこと（Reply-To）
   - ページソースに `rel="canonical"` が出ていること

> 補足: 問い合わせ通知の宛先は検証済みの `contact@master.makedara.work` のため、
> SES サンドボックスのままでも通知メールは送信されます（既存の受信転送に相乗り）。
