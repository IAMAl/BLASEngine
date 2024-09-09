# Reduction Note

BLASEngineはリダクション演算をサポートしています。リダクション演算は各レーンでの実行を制御するフラグレジスタLane_Enとローテートを利用して実装します。
Lane_Enレジスタはスカラユニットにあります。初めに初期値0のローテート（mv命令）後にLane_Enをセットする即値mv命令を実行してリダクションで行う演算命令を実行するこのパターンを即値の値を変えて繰り返してレーンを横断したツリーのデータフローを実現します。

<div align="center">
  <img src="https://github.com/IAMAl/BLASEngine/blob/main/notes/ExecConcept/Reduction.png"
       alt="Reduction"
       title="1D Convolution (K=3, Delite=1)"
       width="700px"
  />
</div>