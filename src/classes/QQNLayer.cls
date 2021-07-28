global class QQNLayer {
    
    /** Parent Neural Network   */
    private QQNNeuralNetwork network;
    /** Predecessor Layer   */
    private QQNLayer predecessor;
    /** Successor Layer */
    private QQNLayer successor;
    /** Activation Function for this layer  */
    private QQNActivationFunction phi;
    /** Gradient function for this layer    */
    private QQNGradientFunction delta;
    /** Neurons */
    private List<QQNNeuron> neurons;
    /** Last input processed by this layer. We store this in memory
     * because it is needed again in the training step. */
    private double[] input;
    /** Last evaluated Layer output
        (After applying Activation function)    */
    private double[] output;
    /** Computed gradients  */
    private double[] gradients;
    /** Learning rate   */
    @TestVisible
    private double alpha;
    
    private QQNLayer__c sfObject;
    
    //  Constructors
    //  TODO: Dropped unnecessary nInputs and second constructor. Update design.
    public QQNLayer(QQNLayer__c sfObject, double alpha, QQNNeuralNetwork network) {
        this.sfObject = sfObject;
        neurons = new List<QQNneuron>();
        //  Add a dummy neuron to make the list indices 1-based
        neurons.add(null);
        //  Neurons must be constructed and added manually
        this.alpha = alpha;
        this.network = network;
    }
    /** Call this if data for neurons is not present in the DB */
    // 数据库中没有神经元数据，新作成神经元
    public void initialize(integer nInputs, integer nNeurons) {
        //  nInputs does not include the bias term
        integer nWeights = nInputs + 1;
        for(integer i=1; i<=nNeurons; i++) {
            neurons.add(new QQNNeuron(nWeights, this));
        }
    }
    // 数据库中没有神经元数据，新作成神经元
    public void initialize(List<QQNNeuron> qqnNeruos) {
        for (QQNNeuron qqn : qqnNeruos) {
        	neurons.add(qqn);
        }
    }
    //  Methods
    /**
     * Evaluate, store and return the layer output vector
     * @param input Layer input vector with input[0] = 1 appended
     * @return Layer output vector
     */
    public double[] evaluate(double[] input) {
        integer nNeurons = getNeuronCount();
        
        if(null == output) {
            //  One more than the number of neurons for bias term
            output = new double[nNeurons + 1];
        }
        // 2019/02/15 AI功能改修 by zy BEGIN
        //output[0] = 1;
        output[0] = 0;
        // 2019/02/15 AI功能改修 by zy END
        // 权重值评估
        // 每一个节点在此次处理中的表现
        for(integer i=1; i<=nNeurons; i++) {
        	// 2019/02/15 AI功能改修 by zy BEGIN
        	QQNNeuron neuron = getNeuron(i);
        	if (neuron.isEmpty()) continue;
        	// 将表现分成大于0，0
            output[i] = phi.evaluate(neuron.evaluate(input));
            // output[i] = phi.evaluate(getNeuron(i).evaluate(input));
 			// 2019/02/15 AI功能改修 by zy END      
        }
        this.input = input;
        
        return output;
    }
    /**
     * Compute local gradients and update weights of the neurons
     * in this layer 
     * @param e Local gradients of the successor layer or
     * error vector if this is the output layer
     */

    public void doUpdate(double[] e) {
        integer nNeurons = getNeuronCount();
        
        if(null == gradients) {
            //  One more than the number of neurons to make sure indices match
            gradients = new double[nNeurons + 1];
        }
        
        delta.evaluate(e, gradients);
        for(integer i=1; i<=nNeurons; i++) {
            getNeuron(i).doUpdate(gradients[i], this.input);
        }
    }
    
    public void setPredecessor(QQNLayer predecessor) {
        this.predecessor = predecessor;
    }
    
    public QQNLayer getPredecessor() {
        return predecessor;
    }
    
    public void setSuccessor(QQNLayer successor) {
        this.successor = successor;
    }
    
    public QQNLayer getSuccessor() {
        return successor;
    }
    
    public void setActivationFunction(QQNActivationFunction phi) {
        this.phi = phi;
    }
    
    public QQNActivationFunction getActivationFunction() {
        return phi;
    }
    
    public void setGradientFunction(QQNGradientFunction delta) {
        this.delta = delta;
    }
    
    public double[] getLocalGradients() {
        return gradients;
    } 
    
    public double getLearningRate() {
        return alpha;
    }
    
    public void addNeuron(QQNNeuron neuron) {
        neurons.add(neuron);
    }
    
    //  Remember to pass 1-based indices. If number of neurons is n,
    //  index must be in the range [1..n] not [0..n-1].
    public QQNNeuron getNeuron(integer index) {
        return index < neurons.size() ? neurons.get(index) : null;
    }
    
    public integer getNeuronCount() {
        //  Neuron indices are 1-based
        return neurons.size() - 1;
    }
    
    public QQNLayer__c getSFObject() {
        return sfObject;
    }
    
    public QQNLayer deepCopy(QQNNeuralNetwork parent) {
        QQNLayer l = new QQNLayer(sfObject, this.alpha, parent);
        
        for(QQNNeuron neuron : this.neurons) {
        	if(neuron!=null)
            	l.addNeuron(neuron.deepCopy(l));
        }
        
        return l;
    }
    // 2019/02/15 AI功能改修 by zy BEGIN
    public void initNeuron(List<Integer> nActions){
    	for (Integer index : nActions) {
    		QQNNeuron neuron = getNeuron(index);
    		if(neuron == null) continue;
    		neuron.initNeuron();
    	}
    }
    public void removeNeuron(integer index){
    	if (index < neurons.size()) neurons[index] = null;
    }
    // 2019/02/15 AI功能改修 by zy END

}