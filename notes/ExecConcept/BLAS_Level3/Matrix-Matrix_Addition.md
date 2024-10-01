# Matrix-Matrix Addition Note

ベクトルとベクトルの加算と減算はBLASEngineでは3通りの実装方法があります。

## 方法1：古典ベクトル演算

これは各レーンで加算や減算を行うレジスタファイルに収まるベクトル長を中心とした方法です。
スライシングを使用してレジスタファイル内の連続した複数の要素を各サイクルで読み出し時系列で加算や減算を行います。
この方法は分岐命令を必要としないことと、一つの命令で演算を実現できるので分岐予測器を持たないBLASEngineにとって都合の良い方法と言えます。
従ってこの方法は時系列で演算を行いますがオーバーヘッドのない演算方法と言えます。

## 方法2：SIMD演算

2つ目の方法はSIMDで実装する方法です。

## 方法3：ベクトルSIMD演算

3つ目は古典ベクトルとSIMDを組み合わせた方法です。
これはベクトルの一次元を3次元に分割します。
アルゴリズム上forループ構造の最内側ループを古典ベクトル演算、その外側ループを各レーンにマップし、最外ループは分岐命令を使用して実装します。
それぞれのレーンで演算を行います。

<div align="center">
  <img src="https://github.com/IAMAl/BLASEngine/blob/main/notes/ExecConcept/figures/MatrixOP.png"
       alt="HTML image alt text"
       title="Matrix Addition"
       width="600px"
  />
</div>