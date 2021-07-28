public class QQNReLUActivationFunction implements QQNActivationFunction {
    public double evaluate(double v) {
    	return Math.max(v, 0);
    }
    
    public double tangent(double v){
    	return (v <= 0 ? 0 : 1);
    }
}