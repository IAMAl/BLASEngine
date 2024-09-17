# BLASEngine

アクセラレータのソースコード(SystemVerilog)を公開します。ライセンスはAGPLなので順守してください。AI専用ではなく数値演算アクセラレータを目指してます：
https://github.com/IAMAl/BLASEngine

**ライセンスについて**

AGPLライセンスなので個人含め自由にソースコードを使用できますが、使用と同時にソースコードの公開に応じる必要があることを意味します。
また不正を伴う使用については個人と団体問わず対処します。

## 全体の構成

トップモジュールから見てもらえれば分かりますが全体的な構成としてMPUというモジュールの下にTPUがぶら下がっています。
MPUはホストからプログラムを受け取りそのプログラムを複数のTPUに投げ、TPUからの終了通知を受けて次のプログラムを投げます。
複数のTPUは二次元アレイを構成します。縦（行）方向はタスクレベルパラレリズム、横（列）方向はデータレベルパラレリズムに相当します。


## TPUの構成

<div align="center">
  <img src="https://github.com/IAMAl/BLASEngine/blob/main/BLASEngine_Layout.png"
       alt="HTML image alt text"
       title="全体構成（左）とTPUの構成（右）"
       width="550px"
  />
</div>

一つのTPUはサービス管理ユニットの下に一つのスカラユニットと一つのベクトルユニットで構成されます。
TPU内のサービス管理ユニットはMPUとの間の通信を担います。
スカラユニットのフロントエンド下にベクトルユニットが接続しています。

レジスタファイルの読み書きはスライシングに対応しています。
つまり元のレジスタインデックスに対して長さLの連続したレジスタ読み書きをサポートしています。
実際レジスタファイルに存在するデータブロックへのアクセスはレーンごとに違う事が発生することを想定してこれに対応させるためにインデックス計算のパイプラインステージを設けています。
スライシングに加えてレーンIDや定数などを使用してアフィン式を構成してレジスタファイルの実際のインデックス値を生成します。

レジスタリードステージの次にネットワークステージがあります。
これはレーン間の通信に用います。
読み出したデータを他のレーンへ送信したり他のレーンから受信することを可能としています。
これによりプログラム内ループ部分の配列にあるイテレート間のデータ依存性に対応させています。

## 3入力演算をサポート

演算は3入力演算をサポートしています。
例えばMAD(Multiply-Add)を想定しています。
3ソースオペランドとスライシングによりMAD演算を一つの命令でバイパス（ネットワークステージ）を利用してレジスタファイルへの書き戻しや読み出し無しに実現します。
例えば3ソースオペランドとスライシングによるMAD演算は長さLのスライシング対応の2ソースオペランド演算ではO(2L)ステップになりますが3ソースオペランド＋バイパスを前提とするとO(L+1)までステップ数を短縮できます。
これはCrayスタイルの古典ベクトルプロセッサでのChainingという技術に相当します。

ベクトル側での演算で3オペランド演算を積極的に利用することで全体の演算ステップ数を削減することを目指しています。
先に示したようにピーク性能として2倍のスピードアップになります。
もちろん横方向でもデータ並列演算をするのでレーン数がNであれば理論的にN並列のデータ処理が可能になります。
総じてベクトルユニット単体としてO(2N)のピーク性能を有します。
さらにCrayスタイルのベクトル演算のサポートにより分岐命令なしに最内ループの繰り返し処理を実現します。

## 命令セットアーキテクチャ

命令セットアーキテクチャはスカラユニットとベクトルユニットで同じビットフィールド割り当てを持ち、主な違いは分岐とマスク、対応演算種類です。
スカラ系での条件分岐命令はベクトルユニットではマスク命令として扱われます。
ベクトルユニットは複数のスカラユニットのバックエンドがそれぞれSIMDのレーンとして構成されていますが、対応する演算は接続元のスカラ演算ユニットとは異なります。
スカラとベクトルユニットのバックエンドは分岐やマスク以外ほぼ同じで、２つのレジスタファイルと２つのロードストアユニットを持ちます。

## サポートする数値精度

スカラユニットは32或いは64-bit整数のいずれかをサポートします。
ベクトルユニットは単精度浮動小数点演算或いは倍精度浮動小数点演算のいずれかと32或いは64-bit整数のいずれかとの変換命令のみサポートします。
現在様々な数値精度のデータ型にあふれていますが対応予定はないです。
むしろそういった使われるかどうかわからないハードウェア設計側の都合のものをすべて排除して回路を簡素にし、実装密度を上げるとともにソフトウェアコンパイラの負担軽減も図ります。

## 演算のスタイル

縦方向のTPU間の通信はデータメモリを通して行います。
つまり縦方向2つのTPUの間にデータメモリがあり両方から読み書きができる構成としています。
これにより各縦方向の一つ以上の行のブロックで何らかのタスクを処理することを可能とし、タスクレベルでのパイプライン動作を実現します。
また、このアーキテクチャはベクトルユニット内にある複数のスカラ演算バックエンドでCrayスタイルのベクトル演算を最内ループに対して行い、横方向にレーンを構成してこの次元で外側のループに関する通信を行います。
従って複数のスカラ演算バックエンドでSIMD相当の演算を行います。

## ハザード検出とコミット（命令リタイア）

MPUもTPUもハザード検出を行っていてその際のテーブルの番号を利用してコミットを実施する仕組みにしています（コミットリクエスト時にWBで番号を受け取りその番号のテーブルエントリに対応する有効フラグレジスタをクリアします）。
ハザード検出はMPUの場合は送信するプログラム（スレッド）の順序を保証し、TPUの場合は発行する命令の順序を保証しています。
スレッドは複数コピーされて各TPUで実行することもできるのですべてのスレッドの実行終了を確認する必要があります。
同様にTPU内の各レーンもすべてのスカラバックエンドの実行が終了することを確認する必要があります。
BLASEngineはこのための機構を有します。


## 宣伝
シストリックアレイの設計マニュアルを個人販売してます。
よかったらどうぞ。

https://electron-nest.booth.pm/