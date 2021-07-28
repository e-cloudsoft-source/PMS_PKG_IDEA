public class QQNNNQTable implements QQNQTable {
    public QQNNNQTable(QQNNeuralNetwork network) {
    	this.network = network;
    }
    
    public double[] getRow(double[] state) {
    	// 预测队列
    	integer nStates = state.size();
    	// 初始化预测结果
    	if(null == lastState) {
    		lastState = new double[nStates + 1];
    	}
    	// 第0位为空房间
    	//	Add bias term
    	lastState[0] = 1;
    	// 预测队列
    	for(integer i=1; i<=nStates; i++) {
    		lastState[i] = state[i-1];
    	}
    	
    	double[] result = network.evaluate(lastState);
		// 2019/02/15 AI功能改修 by zy BEGIN
    	return result;
    	// 2019/02/15 AI功能改修 by zy END
    	integer nActions = result.size() - 1;
    	
    	if(null == lastRow) {
    		lastRow = new double[nActions];
    	}
    	
    	for(integer i=0; i<nActions; i++) {
    		//	Results are 1-based. Convert to 0-based QTable column indices.
    		lastRow[i] = result[i+1];
    	}
    	return lastRow;
    }
    
    public void doUpdate(double[] state, integer action, double error) {
    	integer nActions = network.getOutputCount();
system.debug(logginglevel.info,'nActions:::' + nActions);
    	if(null == errors || errors.size() < (nActions + 1)) {
    		//	Neuron indices are 1-based
    		errors = new double[nActions + 1];
    	}
    	for(integer i=0; i<=nActions; i++) {
    		errors[i] = 0;
    	}
system.debug(logginglevel.info,'errors:::' + errors.size());
    	errors[action+1] = error;
    	
    	network.doUpdate(errors);
    }
    
    public QQNQTable deepCopy() {
    	return new QQNNNQTable(network.deepCopy());
    }
    
    /** The underlying neural network   */
    private QQNNeuralNetwork network;
    
    private double[] errors;
	private double[] lastRow;
	private double[] lastState;
	// 2019/02/15 AI功能改修 by zy BEGIN
	public void initNeuron(List<Integer> nActions){
		network.initNeuron(nActions);
	}
	// 2019/02/15 AI功能改修 by zy END
}