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
   - マスターアカウントのコンソールで `master.makedara.work` の public hosted zone を作成
   - 払い出された Zone ID を `terraform.tfvars` の `master_makedara_zone_id` に設定

2. **親ドメインへ NS 委任**
   - `makedara.work` を管理する DNS（レジストラ or 親ゾーン）に、手順1で払い出された
     4 本の NS を持つ `master` サブドメインの NS レコードを追加して委任する

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

### Terraform初期化

作業ディレクトリでTerraformを初期化します。環境変数 `AWS_PROFILE` でプロファイル名を指定してください。

```bash
aws sso login --profile master
export AWS_PROFILE=master && terraform init
```
