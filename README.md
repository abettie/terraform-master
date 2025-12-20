# terraform-master

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
   AWS_PROFILE=terraform-master; terraform init
   AWS_PROFILE=terraform-master; terraform apply -target=aws_organizations_organization.main
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
   AWS_PROFILE=terraform-master; terraform apply
   ```

5. **ユーザーのメールアドレス検証**
   - Terraformでユーザーを作成した後、そのユーザーでログインするにはメールアドレスの検証が必要です
   - AWSコンソールでIAM Identity Centerに移動
   - 「ユーザー」メニューからpioneerユーザーを選択
   - 「メールアドレスの検証を送信」をクリック
   - ユーザーが受信したメールから検証リンクをクリックして検証を完了
   - 検証完了後、パスワード設定の案内メールが送信されます

### Terraform初期化

作業ディレクトリでTerraformを初期化します。環境変数 `AWS_PROFILE` でプロファイル名を指定してください。

```bash
AWS_PROFILE=terraform-master; terraform init
```
