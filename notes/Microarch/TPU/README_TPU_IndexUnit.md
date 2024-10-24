## Index Unit Note

TPUはインデックス計算のパイプラインステージを持ちます。
この計算されたインデックス値はレジスタの読み書きに使用します。
インデックス計算は各レーンで計算しますが、各レーンで同じ命令を実行するとしても異なるテンソル（配列）の要素位置を扱うのでそのための実際アクセスするインデックス値を計算します。


<div align="center">
  <img src="./TPU_IndexUnit.png"
       alt="HTML image alt text"
       title="インデックスユニットデータパス構成図"
       width="550px"
  />
</div>



図はインデックスユニットの計算回路を示しています。
二つのカウンタ、二つの加算回路、一つの乗算回路で構成されます。
この計算はアフィン式であり演算回路を用いてその値を計算します。
インデックスはスライシングに対応していて開始位置のインデックス値から読み書きする長さを指定してその長さ分の読み書きを行います。
これは古典的なベクトルプロセッサの演算におけるレジスタの読み書きに相当します。
TPUはこれに加えてウィンドウというコンセプトを導入しています。
レジスタファイルへのアクセスはインデックス開始位置からウィンドウサイズの間で行われます。
この範囲で複数回アクセスをするので同じレジスタエントリへのアクセスを可能とします。

インデックスユニットはレーンID番号とスレッドID番号を演算データとして使用することができます。
これにより同じ命令で異なる位置にあるテンソル要素へアクセスでき、また複数のスレッドに大規模なデータを分割して渡して演算する際に適切なアクセスも可能にします。

また、このユニットは遅延回路を内蔵しています。
個の遅延が有効な場合、カウンタ値とレーンIDとを比較して一致したタイミングでインデックスユニットが動作開始します。
これはレジスタ読み出しと書き込みのそれぞれのインデックスユニットで遅延制御が可能であり、これによりシストリックアレイ動作におけるイニシエートインターバルを実現し、またベクトルの転地も実現します。