public class QQNOutputGradientFunction extends QQNGradientFunction {
    public QQNOutputGradientFunction(QQNLayer layer) {
    	super(layer);
    }
    
    public override void evaluate(double[] error, double[] returnGradients) {
    	integer nNeurons = layer.getNeuronCount();
    	QQNActivationFunction phi = layer.getActivationFunction();
    	
    	//	Neurons are 1-based
    	for(integer i=1; i<=nNeurons; i++) {
    		QQNNeuron neuron = layer.getNeuron(i);
    		returnGradients[i] = error[i] * phi.tangent(neuron.getLastOutput());
    	}
    }
}