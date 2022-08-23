# ecmoveのこと

##ecmoveについて
eccubeのローカル環境を本番環境に移したり、その反対もできるツール ・docker image

シェルスクリプトでプログラムを作成

## 前提条件
- 使うときは自己責任で、責任は一切負いません
- eccube4系であること
- docker-composeで作ること
- mysqlを使うこと

## おすすめファイル構成
.  
├── Dockerfile  
├── docker-compose.yml  
├── dockerbuild  
├── eccube  　　（ec-cubeのappとかを入れたフォルダ）  
└── ecmove  
       └── root  
           ├── backup  
           └── ecmove  
                └── ecmove.sh  