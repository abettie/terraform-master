# AWS ログイン設定

このドキュメントでは、Terraformを利用するためのAWSログイン設定手順について説明します。

## 初回構築の場合

このリポジトリを使用して0から環境を構築する場合の手順です。

### 1. AWS CLI プロファイル設定（rootアカウント）

初回構築時は、AWSのrootアカウントでアクセスキーとシークレットアクセスキーを発行し、AWS CLIに設定します。

#### アクセスキーの発行

1. AWSマネジメントコンソールにrootアカウントでログイン
2. 右上のアカウント名をクリックし、「セキュリティ認証情報」を選択
3. 「アクセスキー」セクションで「アクセスキーを作成」をクリック
4. アクセスキーIDとシークレットアクセスキーをメモ（シークレットアクセスキーは後から確認できません）

#### AWS CLI 設定

以下のコマンドでプロファイルを設定します。

```bash
aws configure --profile terraform-master
```

プロンプトに従って、以下の情報を入力してください：

```
AWS Access Key ID: （発行したアクセスキーID）
AWS Secret Access Key: （発行したシークレットアクセスキー）
Default region name: ap-northeast-1
Default output format: json
```

#### 疎通確認

正しく設定できているか確認します。

```bash
aws sts get-caller-identity --profile terraform-master
```

正常に接続できている場合、以下のようなレスポンスが返ります：

```json
{
    "UserId": "123456789012",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:root"
}
```

### 2. Terraform apply の実行

rootアカウントでログインした状態で、Terraformを実行してAWS OrganizationsとIAM Identity Centerを構築します。

```bash
AWS_PROFILE=terraform-master; terraform init
AWS_PROFILE=terraform-master; terraform plan
AWS_PROFILE=terraform-master; terraform apply
```

### 3. rootアカウントのアクセスキー削除

セキュリティのため、Terraform applyが完了したら、rootアカウントのアクセスキーをAWSから削除します。

1. AWSマネジメントコンソールの「セキュリティ認証情報」に戻る
2. 作成したアクセスキーを削除

また、ローカルのAWS CLI設定からも削除します。

```bash
# ~/.aws/credentials から [terraform-master-root] セクションを削除
# ~/.aws/config から [profile terraform-master-root] セクションを削除
```

または、以下のコマンドで削除できます：

```bash
aws configure --profile terraform-master list
# 設定が存在することを確認後、手動で ~/.aws/credentials と ~/.aws/config を編集
```

### 4. SSOログイン設定へ移行

rootアカウントのアクセスキーを削除したら、以下の「構築済み環境にアサインされた場合」の手順に従ってSSOログイン設定を行います。

## 構築済み環境にアサインされた場合

既にAWS OrganizationsとIAM Identity Centerが構築済みの環境にアサインされた場合の手順です。

### SSOログインのための設定ファイル編集

`~/.aws/config` ファイルを編集して、SSO設定を追加します。

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
