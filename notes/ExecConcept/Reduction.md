# Reduction Note

BLASEngineはリダクション演算をサポートしています。
命令内にあるレジスタ読み出しと書き込みそれぞれの有効フラグにマスクを行い、かつネットワークステージでローテートを利用して実装します。
マスクレジスタはスカラユニットにあります。
初めに初期値0のローテート（mv命令）後にマスクをセットする即値mv命令を実行してリダクションで行う演算命令を実行するこのパターンを即値の値を変えて繰り返してレーンを横断したツリーのデータフローを実現します。


<div align="center">
  <img src="https://github.com/IAMAl/BLASEngine/blob/main/notes/ExecConcept/figures/Reduction.png"
       alt="Reduction"
       title="Reduction Control on BLASEngine"
       width="550px"
  />
</div>


また、BLASEngineは古典ベクトル演算もサポートしているので一次元のリダクション演算を古典ベクトル演算とSIMD演算を組み合わせて二次元にして（forループで例えると一次元ループを二次元に分割して内側のループを古典ベクトルに割り当てることに相当します）比較的規模の大きいリダクション演算に対応させることができます。
この時、スライシングを利用しますが、スライシングを使用した演算命令を演算回路のパイプライン段数分実行することでこの段数分の部分演算結果を計算できます。
これらの部分演算結果をスライシングとマスクとローテートを使用してレジスタファイルに対しての読み書きを制御することで最終的に一つのレーンにパイプライン段数分の部分演算結果が残ります。
最終的にこれらに対してスライシングを使用して自己参照演算を行えばリダクション演算したスカラー値を得ます。