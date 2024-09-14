# Reduction Note

BLASEngineはリダクション演算をサポートしています。リダクション演算は各レーンでの実行を制御するフラグレジスタLane_Enとローテートを利用して実装します。
Lane_Enレジスタはスカラユニットにあります。
初めに初期値0のローテート（mv命令）後にLane_Enをセットする即値mv命令を実行してリダクションで行う演算命令を実行するこのパターンを即値の値を変えて繰り返してレーンを横断したツリーのデータフローを実現します。

<div align="center">
  <img src="https://github.com/IAMAl/BLASEngine/blob/main/notes/ExecConcept/figures/Reduction.png"
       alt="Reduction"
       title="Reduction Control on BLASEngine"
       width="550px"
  />
</div>


また、BLASEngineは古典ベクトル演算もサポートしているので一次元のリダクション演算を古典ベクトル演算とSIMD演算を組み合わせて二次元にして（forループで例えると一次元ループを二次元に分割して内側のループを古典ベクトルに割り当てることに相当します）比較的規模の大きいリダクション演算に対応させることができます。