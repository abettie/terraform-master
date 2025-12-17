# terraform-master

## 概要

AWS Organizationのマスターアカウント用のTerraformソースです。

## AWS OrganizationsとIAM Identity Centerについて

AWS OrganizationsとIAM Identity Centerを使用して、複数のAWSアカウントとユーザーアクセスを一元管理します。詳しい解説は以下のドキュメントを参照してください。

- [AWS OrganizationsとIAM Identity Centerの詳細解説](docs/aws-organizations-iam-identity-center.md)

## AWS準備

AWSコンソールで以下の設定を行います。

### AWS Organizationsの有効化

1. AWSマネジメントコンソールにログイン
2. AWS Organizationsサービスに移動
3. 「組織の作成」をクリックして有効化

### IAM Identity Centerの有効化

1. AWSマネジメントコンソールで「IAM Identity Center」サービスに移動
2. 「有効にする」をクリックしてIAM Identity Centerを有効化
3. アイデンティティソースは「Identity Center ディレクトリ」を選択（デフォルト）

### IAM Identity Centerのグループ作成

1. IAM Identity Centerコンソールで「グループ」を選択
2. 「グループを作成」をクリック
3. グループ名を入力（例：`TerraformAdministrators`）
4. 説明を入力して作成

### IAM Identity Centerのユーザー作成

1. IAM Identity Centerコンソールで「ユーザー」を選択
2. 「ユーザーを追加」をクリック
3. ユーザー情報を入力
   - ユーザー名
   - メールアドレス
   - 名前・姓
4. ユーザーを作成（初回ログイン用のメールが送信されます）
5. 作成したユーザーを適切なグループに追加

### アクセス許可セットの作成とグループへの割り当て

1. IAM Identity Centerコンソールで「アクセス許可セット」を選択
2. 「アクセス許可セットを作成」をクリック
3. 事前定義されたアクセス許可セットから「AdministratorAccess」を選択
4. 必要に応じて名前と説明をカスタマイズして作成
5. 「AWSアカウント」タブに移動
6. 対象のAWSアカウントを選択
7. 「ユーザーまたはグループを割り当て」をクリック
8. 先ほど作成したグループ（例：`TerraformAdministrators`）を選択
9. アクセス許可セット（`AdministratorAccess`）を選択
10. 「送信」をクリックして割り当てを完了

## ローカル準備

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

## Terraform準備

### 状態管理用S3バケット作成

1. AWSコンソールでS3バケットを作成します
   - バケット名: `terraform-state-{UUID}` など、グローバルでユニークな名前を指定
   - リージョン: `ap-northeast-1` (東京)
   - バージョニング: 有効化を推奨

2. 作成したバケット名を `backend.tf` の `bucket` 項目に反映します

### Terraform初期化

作業ディレクトリでTerraformを初期化します。

```bash
terraform init
```
