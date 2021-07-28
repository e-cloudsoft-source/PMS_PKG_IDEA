public class QQNHiddenGradientFunction extends QQNGradientFunction {
    public QQNHiddenGradientFunction(QQNLayer layer) {
    	super(layer);
    }
    
    public override void evaluate(double[] successorGradients, double[] returnGradients) {
    	integer nNeurons = layer.getNeuronCount();
    	QQNActivationFunction phi = layer.getActivationFunction();
    	double successorSum;
    	QQNLayer successor = layer.getSuccessor();
    	integer nSuccessorNeurons = successor.getNeuronCount();
    	system.debug('nNeurons=' + nNeurons + ',nSuccessorNeurons=' + nSuccessorNeurons);
    	//	Neurons are 1-based
    	for(integer i=1; i<=nNeurons; i++) {
    		successorSum = 0;
    		
    		for(integer j=1; j<=nSuccessorNeurons; j++) {
    			successorSum += (successorGradients[j] * successor.getNeuron(j).getWeight(i));
    		}
    		
    		QQNNeuron neuron = layer.getNeuron(i);
    		returnGradients[i] = phi.tangent(neuron.getLastOutput()) * successorSum; 
    	}
    }
}