# ecmove のこと

## 注意事項

ecmoveは私の環境に合わせて作ったものなので、他の環境で使うときは十分にテストしてください。
必要に応じてecmove.shをマウントしていじって使ってください。(sshとdbのポートがデフォルトと違うときなど)

## ecmove について

eccube のローカル環境を本番環境に移したり、その反対もできるツール ・docker image  
データベース、app、html、vendor、composer.json、composer.lockを移すことで移行が可能

シェルスクリプトでプログラムを作成

## 前提条件

- 使うときは自己責任で、責任は一切負いません
- eccube4 系であること
- docker-compose で作ること
- mysql を使うこと

## おすすめフォルダ・ファイル構成

```
.
├── Dockerfile
├── docker-compose.yml
├── dockerbuild
├── eccube  　　（ec-cubeを入れたフォルダ）
│      ├── COPYING
│      ├── LICENSE.txt
│      ├── Procfile
│      ├── app
│      ├── app.json
│      ├── bin
│      ├── codeception
│      ├── codeception.yml
│      ├── composer.json
│      ├── composer.lock
│      ├── gulp
│      ├── html
│      ├── index.php
│      ├── maintenance.php
│      ├── node_modules
│      ├── package.sh
│      ├── phpstan.neon.dist
│      ├── phpunit.xml.dist
│      ├── robots.txt
│      ├── src
│      ├── symfony.lock
│      ├── tests
│      ├── var
│      ├── vendor
│      ├── web.config
│      └── zap
└── ecmove
       └── root
           ├── backup
           └── ecmove
                └── ecmove.sh
```

## 使い方

### docker-compose.ymlの書き方
上記のフォルダ構成を元に解説  

1. docker-compose.ymlにsample-docker-compose.ymlのecmoveの部分を記述する
1. volumesに必要な引数を指定する  
    - /var/www/htmlにeccubeを  
    - /root/backupにecmove/root/backupを  
    - /root/.sshに~/.ssh（自分の鍵があるフォルダ）を  
    - /root/ecmove/にecmove/root/ecmoveを（必要なとき）
1. environmentに必要な引数を指定
    - 最低限指定するもの
        - ○○○_DIR_PATH
        - ○○○_DB_NAME
        - ○○○_DB_USER
        - ○○○_DB_PASSWORD
        - ○○○_DB_HOST
        - ○○○_SSH_HOST
        - ○○○_SSH_USER

    - 必要に応じて使うもの
        - ECMOVE_BACKUP_ECCUBE: "true"（毎回localと○○○のフォルダ・ファイルをバックアップするようになる）

### ecmoveコマンドの打つ場所
docker exec -w /home/ -it ecmovetest_ecmove /bin/bashで入れるコンテナの中

### ecmoveコマンドの使い方
```
ecmove $1 $2 $3
例：ecmove pull STAGING td（STAGINGからテーマとプラグインとデータベースを引っ張ってくる）
```
$1：「push」or「pull」

$2：docker-compose.ymlで渡した環境引数の変数の最初の文字
例：「STAGING」「PRODUCTION」

$3：「t」or「d」or「td」
t：テーマとプラグインを移動対象とする
（app html vendorフォルダ composer.json composer.lock）
d：データベースを移動対象とする