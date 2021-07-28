public interface QQNActivationFunction {
    /**
     * Evaluate activation function for v
     * @param v Neuron output before applying activation function
     * @return activation function output for v
     */
    double evaluate(double v);
    
    /**
     * Evaluate the derivative of the activation function for v
     * @param v Neuron output before applying activation function
     * @return derivative of the activation function for v
     */
    double tangent(double v);
}