# Deconvolution (Transposed Convolution) Note

BLASEngineはDeconvolutionをサポートしています。Deconvolutionは別名Transposed Convolutionであり、ストライド量Sとデライト量Dの役割が一般的な畳み込みと比較して役割が交換された畳み込み演算と言えます。例えば、ストライド量Sは入力ベクトル要素間のにいくつ定数数を埋め込むのか（元々の畳み込みでいうディレート相当）であり、ディレートは重みベクトルの移動量（元々の畳み込みのストライド量）を定義しています。下図はその際の各パラメータを示しています。

<div align="center">
  <img src="https://github.com/IAMAl/BLASEngine/blob/main/notes/ExecConcept/figures/DeconvConfigParams.png"
       alt="Transposition"
       title="Parameters for Deconvolution"
       width="700px"
  />
</div>

これらのパラメータに従い畳み込み演算と同様に適宜インデックスステージとネットワークステージを活用することで畳み込みと同じ方法でDeconvolutionを実現できます。


#### BLASEngineのメリット

各レーンにある入力ベクトルの部分ベクトルを再配置する必要がなくなり、例えば次の演算において現在の演算結果ベクトルの各要素を各レーンへ再配置することを不要としてベクトル演算ユニットの演算器は演算のみに集中でき、無駄な処理を削減します。