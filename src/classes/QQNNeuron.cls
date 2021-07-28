// 神経単位
public class QQNNeuron {
    //  Constructor
    //  Use only when the neuron has no corresponding data in DB
    // 用于数据库中没要相符的数据
    public QQNNeuron(integer nWeights, QQNLayer layer) {
    	this.layer = layer;
    	this.weights = new double[nWeights];
    	
    	for(integer i=0; i<nWeights; i++) {
    		this.weights[i] = Math.random() * 0.02 - 0.01;
    	}
    }
    
    //  Use when data for the neuron is present in DB
    // 数据库中存在数据
    public QQNNeuron(QQNNeuron__c neuronSFObject, QQNLayer layer) {
    	integer nWeights = neuronSFObject.WeightCount__c.intValue();
    	this.sfObject = neuronSFObject;
    	// 2019/02/15 AI功能改修 by zy BEGIN
    	//this.layer = layer;
    	this.weights = new List<double>();
    	/*
    	integer i=0;
    	string[] strWeights = sfObject.Weights__c.split(',');
    	for(string sw : strWeights) {
    		this.weights[i++] = Double.valueOf(sw);
    	}*/
    	// 2019/02/15 AI功能改修 by zy END
    }
    
    private QQNNeuron(double[] weights, QQNLayer layer) {
    	this.layer = layer;
    	this.weights = weights;
    }
    
    //  Methods
    /**
     * Evaluate and save neuron output before applying the
     * activation function
     * @param input Layer input vector 
     * @return neuron Output before applying the activation function
     */
    public double evaluate(double[] input) {
    	integer nWeights = weights.size();
    	output = 0;

    	// 返回每一个神经权重表现
    	for(integer j=0; j<nWeights; j++) {
    		if (weights[j] == null) continue;
    		// 2019/02/15 AI功能改修 by zy BEGIN
    		double inputValue = 0;
    		if (j < input.size() && input[j] != null) inputValue = input[j];
    		output += (weights[j] * inputValue);
    		// output += (weights[j] * input[j]);
    		// 2019/02/15 AI功能改修 by zy END
    	}
    	return output;
    }
    
    /**
     * Update the weights of this neuron
     * @param localGradient Local gradient for this neuron
     * @param input Layer input vector
     */
    public void doUpdate(double localGradient, double[] input) {
    	double alpha = layer.getLearningRate();
    	integer nWeights = weights.size();
    	
    	for(integer j=0; j<nWeights; j++) {
    		weights[j] += alpha * localGradient * input[j];
    	}
    }
    
    public double getWeight(integer index) {
    	return weights[index];
    }
    
    public double[] getWeights() {
    	return weights;
    }
    
    public double getLastOutput() {
    	return output;
    }
    
    public void setSFObject(QQNNeuron__c nc) {
    	sfObject = nc;
    }
    
    public QQNNeuron__c getSFObject() {
    	if(sfObject == null) {
    		sfObject = new QQNNeuron__c();
    		sfObject.WeightCount__c = weights.size();
    		sfObject.LayerId__c = layer.getSFObject().id;
    	}
    	
    	String csvWeights = '';
    	for(double w : weights) {
    		if(csvWeights.length() > 0)
    			csvWeights += ',';
    		csvWeights += Decimal.valueOf(w).toPlainString();
    	}
    	
    	sfObject.Weights__c = csvWeights;
    	
    	return sfObject;
    }
	
    public QQNNeuron deepCopy(QQNLayer parent) {
    	integer wsize = this.weights.size();
    	double[] nw = new double[wsize];
    	
    	for(integer i=0; i<wsize; i++) {
    		nw[i] = this.weights[i];
    	}
    	
    	return new QQNNeuron(nw, parent);
    }
    
    //  Fields
    /** Parent layer    */
    private QQNLayer layer;
    /** Neuron weights  */
    @TestVisible
    private double[] weights;
    /** Last evaluated Neuron output
        (Before applying Activation function)   */
    private double output;
    
    private QQNNeuron__c sfObject;
    // 2019/02/15 AI功能改修 by zy BEGIN
    public boolean isEmpty(){
    	return weights.isEmpty();
    }
    public void initNeuron(){
    	integer i=0;
    	if (this.weights.isEmpty()) {
	    	this.weights.add(null);
	    	string[] strWeights = sfObject.Weights__c.split(',');
	    	for(string sw : strWeights) {
	    		this.weights.add(Double.valueOf(sw));
	    	}
    	}
    }
    // 2019/02/15 AI功能改修 by zy END
}