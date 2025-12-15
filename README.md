# terraform-master

## 概要

AWS Organizationのマスターアカウント用のTerraformソースです。

## 前準備

### AWS CLIのインストール

AWS CLIをインストールしてください。

- [AWS CLI インストールガイド](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)

### Terraformのインストール

Terraformをインストールしてください。

- [Terraform インストールガイド](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### Terraform用のロール作成と使用準備（AssumeRole回り）

Terraformを実行するためのIAMロールを作成し、AssumeRoleを使用できるように設定してください。

1. マスターアカウントにTerraform実行用のIAMロールを作成
2. 必要な権限ポリシーをアタッチ
3. AWS CLIでAssumeRoleを使用できるように `~/.aws/config` を設定

```ini
[profile terraform-master]
role_arn = arn:aws:iam::ACCOUNT_ID:role/TerraformRole
source_profile = default
region = ap-northeast-1
```

### ロールを使った疎通確認

設定したIAMロールで正しくAWSに接続できるか確認してください。

```bash
# プロファイルを指定してAWS CLIコマンドを実行
aws sts get-caller-identity --profile terraform-master
```

正常に接続できている場合、以下のようなレスポンスが返ります：

```json
{
    "UserId": "AROAXXXXXXXXXXXXXXXXX:session-name",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/TerraformRole/session-name"
}
```

`Arn` に `assumed-role` が含まれていれば、AssumeRoleが正常に機能しています。
