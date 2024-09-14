# Modulo Scheduling Note

BLASEngineはネットワークステージを通してモジュロスケジューリングを実現しています。プログラム中ループ内で配列が繰り返し間のデータ依存性を持つ際に適切なレーンへのアクセスを容易に実現し、コンパイラ側でのアクセス計算といった負荷をなくします。
下の図はレーン数4での簡易な例を示しています。データ依存性距離は14なのでモジュロスケジューリング時には右ローテート量2のレーンへ書き込めばよく読み書きの対応が保証されています。

<div align="center">
  <img src="https://github.com/IAMAl/BLASEngine/blob/main/notes/ExecConcept/figures/Modulo_Scheduling.png"
       alt="HTML image alt text"
       title="Matrix-Matrix Multiplication"
       width="600px"
  />
</div>

アレイデータはレーンを横断して要素を配置すればよく、アレイインデックスをレーン数と手整数モジュロ演算をしたときに得る数字をレーン番号として読み書きする配列要素が存在しているので、コンパイラやプログラマにとってデータ構造とマイクロアーキテクチャの対応を取りやすい特徴があります。これによりプログラム最適化の容易さを確保しています。