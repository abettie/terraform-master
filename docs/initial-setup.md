# 初期構築手順

このドキュメントでは、AWS OrganizationsとIAM Identity Centerの初期構築、Terraformバックエンドの設定、および既存リソースのインポート手順について説明します。

## 1. AWS準備

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

## 2. Terraformバックエンド設定

### 2.1. 状態管理用S3バケット作成

Terraformの状態ファイルを保存するS3バケットを作成します。

1. AWSコンソールでS3バケットを作成します
   - バケット名: `terraform-state-{UUID}` など、グローバルでユニークな名前を指定
   - リージョン: `ap-northeast-1` (東京)
   - バージョニング: 有効化を推奨
   - 暗号化: 有効化を推奨

2. 作成したバケット名を [backend.tf](../backend.tf:3) の `bucket` 項目に反映します

### 2.2. Terraform初期化

バックエンド設定を反映し、Terraformを初期化します。

```bash
terraform init
```

初期化が成功すると、S3バケットに状態ファイルが作成され、Terraformがバックエンドを使用する準備が整います。

## 3. AWS Organizationsリソースのインポート

AWS コンソールで作成した既存のリソースをTerraformの管理下に取り込みます。

以下の手順で、`terraform import` コマンドを使用してリソースをインポートします。

### 3.1. IAM Identity Centerインスタンスのインポート

```bash
# IAM Identity CenterインスタンスARNを取得
aws sso-admin list-instances --profile terraform-master

# インスタンスARNを使用してインポート
terraform import aws_ssoadmin_instances.main <instance-arn>
```

### 3.2. グループのインポート

```bash
# グループIDを取得
aws identitystore list-groups --identity-store-id <identity-store-id> --profile terraform-master

# グループをインポート
terraform import aws_identitystore_group.terraform_administrators <identity-store-id>/<group-id>
```

### 3.3. ユーザーのインポート

```bash
# ユーザーIDを取得
aws identitystore list-users --identity-store-id <identity-store-id> --profile terraform-master

# ユーザーをインポート
terraform import aws_identitystore_user.example_user <identity-store-id>/<user-id>
```

### 3.4. アクセス許可セットのインポート

```bash
# アクセス許可セットARNを取得
aws sso-admin list-permission-sets --instance-arn <instance-arn> --profile terraform-master

# アクセス許可セットをインポート
terraform import aws_ssoadmin_permission_set.admin_access <permission-set-arn>,<instance-arn>
```

### 3.5. グループへのユーザー割り当てのインポート

```bash
# グループメンバーシップをインポート
terraform import aws_identitystore_group_membership.example <identity-store-id>/<membership-id>
```

### 3.6. アカウントへのアクセス許可割り当てのインポート

```bash
# アクセス許可の割り当てをインポート
terraform import aws_ssoadmin_account_assignment.example <permission-set-arn>,<instance-arn>,<account-id>,GROUP,<group-id>
```

## 4. インポート後の確認

インポートが完了したら、以下のコマンドで状態を確認します。

```bash
# Terraformの状態を確認
terraform state list

# 差分がないことを確認
terraform plan
```

`terraform plan` の結果で変更が検出されない場合、インポートは正常に完了しています。
