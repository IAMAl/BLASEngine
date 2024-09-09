# Transposition Note

BLASEngineは転地をサポートしています。下図はその実行ステップを示しています。転地はインデックスステージでスライシングとウィンドウを使用してレジスタリードインデックスを調整して各ステップでアクセスします。書き込み時も同様です。読み出した要素データはネットワークでローテーションととおして適切なレーンへ転送されます。ローテーション量はインデックス生成同様にアフィン式で生成され使用されますが、転地の場合は初期値0の+1インクリメントで実装します。


<div align="center">
  <img src="https://github.com/IAMAl/BLASEngine/blob/main/notes/ExecConcept/Transpose.png"
       alt="Transposition"
       title="1D Convolution (K=3, Delite=1)"
       width="700px"
  />
</div>