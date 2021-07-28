global class QQNNeuralNetwork {

    
    /** Layers of this neural network */
    private List<QQNLayer> layers;
    private QQNNeuralNetwork__c sfObject;

    //  Constructor
    public QQNNeuralNetwork(QQNNeuralNetwork__c sfObject) {
        this.sfObject = sfObject;
        layers = new List<QQNLayer>();
    }
    
    //  Methods
    /**
     * Evaluate the neural network output given an input vector
     * @param input Neural network input vector
     * @return Neural network output vector
     */
    public double[] evaluate(double[] input) {
        double[] layerParam = input;
        for(QQNLayer layer : layers) {
            layerParam = layer.evaluate(layerParam);
        }
        return layerParam;
    }
    
    /**
     * Update the weights of each neuron in each layer of the neural
     * network, starting from the output layer and moving backwards
     * @param errors Errors computed with respect to the last input
     */
    public void doUpdate(double[] errors) {
        double[] computedErrors = errors;
        
        for(integer k=layers.size()-1; k>=0; k--) {
            QQNLayer layer = layers.get(k);
            layer.doUpdate(computedErrors);
            computedErrors = layer.getLocalGradients();
        }
    }
    
    /**
     * Add a layer and set ActivationFunction, GradientFunction,
     * predecessor and successor
     * @param layer The layer to be added
     * @param isOutput A boolean value indicating whether layer is
     * the output layer for this network 
     */
    public  void addLayer(QQNLayer layer, boolean isOutput) {
        if(isOutput) {
            layer.setActivationFunction(new QQNLReLUActivationFunction());
            layer.setGradientFunction(new QQNOutputGradientFunction(layer));
        } else {
            layer.setActivationFunction(new QQNTanhActivationFunction());
            layer.setGradientFunction(new QQNHiddenGradientFunction(layer));
        }
        
        if(layers.size() > 0) {
            QQNLayer lastLayer = layers.get(layers.size() - 1);
            lastLayer.setSuccessor(layer);
            layer.setPredecessor(lastLayer);
        }
        
        layers.add(layer);
    }
    
    public QQNLayer getLayer(integer index) {
        return index < layers.size() ? layers.get(index) : null;
    }
    
    public integer getOutputCount() {
        if(layers.size() > 0) {
            QQNLayer lastLayer = layers.get(layers.size() - 1);
            return lastLayer.getNeuronCount();
        }
        
        return 0;
    }
    
    public QQNNeuralNetwork__c getSFObject() {
        return sfObject;
    }
    /**
     * Create and return a deep copy of this network.
     * This will be used to freeze network weights.
     */
    public QQNNeuralNetwork deepCopy() {
        QQNNeuralNetwork nn = new QQNNeuralNetwork(sfObject);
        integer remaining = this.layers.size();
        
        for(QQNLayer layer : this.layers) {
            nn.addLayer(layer.deepCopy(nn), (--remaining) == 0);
        }
        
        return nn;
    }
    // 2019/02/15 AI功能改修 by zy BEGIN
    public void initNeuron(List<Integer> nActions){
    	for(QQNLayer layer : layers) {
    		layer.initNeuron(nActions);
    	}
    }
    // 2019/02/15 AI功能改修 by zy END
}