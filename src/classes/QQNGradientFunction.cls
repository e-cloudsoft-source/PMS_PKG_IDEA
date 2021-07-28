public abstract class QQNGradientFunction {
    public QQNGradientFunction(QQNLayer layer) {
    	this.layer = layer;
    }
    
    //  Here, it may be more efficient to pass in the output array
    //  as a parameter. That decision is left to the implementor.
    /**
     * Evaluate the local gradient for e  
     * @param e output error vector or successor layer gradients
     * @return local gradient for e
     */
    public abstract void evaluate(double[] e, double[] returnGradients);
    
    /** Parent layer */
    protected QQNLayer layer;
}