# Vector Transposition Note

BLASEngineはベクトルの転地をサポートしています。
下図は列ベクトルから行ベクトル、行ベクトルから列ベクトルへの転地についてその実行ステップを示しています。

転地はインデックスステージでスライシングとウィンドウを使用してレジスタリードインデックスを調整して各ステップでアクセスします。
書き込み側も同様です。
読み出した要素データはネットワークでローテーションを通して適切なレーンへ転送されます。
ローテーション量はインデックス生成同様にアフィン式で生成され使用されますが、転地の場合は初期値0の+1インクリメントで実装します。

読み出しと書き込みについてインテックスユニット内の遅延回路を使用してタイミングをずらし、かつ命令内の読み出しと書き込み有効フラグをマスキングすることで適切なタイミングでのデータ転送を実現します。


<div align="center">
  <img src="https://github.com/IAMAl/BLASEngine/blob/main/notes/ExecConcept/figures/Transpose_Vector.png"
       alt="Transposition"
       title="Transposing Matrix"
       width="700px"
  />
</div>