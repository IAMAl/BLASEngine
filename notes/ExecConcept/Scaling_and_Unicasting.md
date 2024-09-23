# Scaling and Unicasting Note

テンソルを扱う際にスカラ定数をそのテンソルのすべての要素に乗算するスケーリングを行う場合があります。BLASEngineではスカラユニット側にその定数を配置しておき、スカラユニットからベクトルユニットの各レーンにユニキャストを行いそのスカラ値と乗算することで実装することができます。これはベクトルユニット内のレジスタファイルについてSIMD演算をする際に一つのレジスタエントリを消費すれば済むところそれぞれのレーンで1エントリを消費してしまうことを防ぐことができます。この時、ネットワークステージにおいてソースオペランドについてスカラデータを入力するように選択しておく必要があります。

<div align="center">
  <img src="https://github.com/IAMAl/BLASEngine/blob/main/notes/ExecConcept/figures/TPU_Unicast.png"
       alt="Transposition"
       title="Unicasting from Scalar Unit"
       width="650px"
  />
</div>