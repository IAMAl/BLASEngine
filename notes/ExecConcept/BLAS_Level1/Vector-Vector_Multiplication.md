# Vector-Vector Multiplication Note

ベクトルとベクトルの要素乗算はBLASEngineでは3通りの実装方法があります。

<div align="center">
  <img src="https://github.com/IAMAl/BLASEngine/blob/main/notes/ExecConcept/figures/VectorOP.png"
       alt="HTML image alt text"
       title="Vector Multiplication"
       width="600px"
  />
</div>

## 方法1：古典ベクトル演算

これは一つのレーン内でベクトルがレジスタファイルに収まる場合を中心にした方法です。
スライシングを使用してレジスタファイル内の連続した複数の要素を各サイクルで読み出し時系列で乗算います。
この方法は分岐命令を必要としないことと、一つの命令で内積演算を実現できるので分岐予測器を持たないBLASEngineにとって都合の良い方法と言えます。
従ってこの方法は時系列で演算を行いますがオーバーヘッドのない演算方法と言えます。

## 方法2：SIMD演算

2つ目の方法はSIMDで実装する方法です。
これはレーンを横断した方向に要素が並んでいる際に使用する方法です。

## 方法3：ベクトルSIMD演算

3つ目は古典ベクトルとSIMDを組み合わせた方法です。
これはベクトル積の一次元を3次元に分割します。
アルゴリズム上forループ構造の最内側ループを古典ベクトル演算、その外側ループをソフトウェアパイプラインの要領で各レーンにマップし、最外ループは分岐命令を使用して実装します。