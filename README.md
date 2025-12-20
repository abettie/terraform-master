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

### SSOログインのための設定ファイル編集

`~/.aws/config` ファイルを編集して、SSO設定を追加します。

※プロファイル名 `terraform-master` は [provider.tf](provider.tf:3) で指定されているため、変更しないでください。

```ini
[profile terraform-master]
sso_session = my-sso
sso_account_id = 123456789012
sso_role_name = AdministratorAccess
region = ap-northeast-1
output = json

[sso-session my-sso]
sso_start_url = https://your-sso-portal.awsapps.com/start
sso_region = ap-northeast-1
sso_registration_scopes = sso:account:access
```

設定値の説明：
- `sso_start_url`: IAM Identity CenterのポータルURL（IAM Identity Centerコンソールの「設定」で確認可能）
- `sso_region`: IAM Identity Centerが有効化されているリージョン
- `sso_account_id`: 対象のAWSアカウントID
- `sso_role_name`: 使用するアクセス許可セット名
- `region`: デフォルトで使用するAWSリージョン

### SSOログイン方法

以下のコマンドでSSOログインを実行します。

```bash
aws sso login --profile terraform-master
```

ブラウザが自動的に開き、IAM Identity Centerのログイン画面が表示されます。ユーザー名とパスワードを入力してログインしてください。

※WSL2でログインする場合は~/.bashrcに下記を追記してください。

```bash
export BROWSER='/mnt/c/Program Files/Google/Chrome/Application/chrome.exe'
```

### 疎通確認

SSOログイン後、正しくAWSに接続できるか確認します。

```bash
aws sts get-caller-identity --profile terraform-master
```

正常に接続できている場合、以下のようなレスポンスが返ります：

```json
{
    "UserId": "AROAXXXXXXXXXXXXXXXXX:user@example.com",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/AWSReservedSSO_AdministratorAccess_xxxxx/user@example.com"
}
```

`Arn` に `AWSReservedSSO` が含まれていれば、IAM Identity Center経由で正常にアクセスできています。

## 使い方

### Terraform初期化

作業ディレクトリでTerraformを初期化します。

```bash
terraform init
```
