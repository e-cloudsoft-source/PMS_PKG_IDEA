public class QQNTanhActivationFunction implements QQNActivationFunction {
    public double evaluate(double v) {
    	return Math.tanh(v);
    }
    
    public double tangent(double v){
    	double th = evaluate(v);
    	return 1 - th * th;
    }
}