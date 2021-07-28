public class QQNQLearningTuple {
    public QQNQLearningTuple(double[] state, integer action, integer reward, double[] endState) {
    	this.state = state;
    	this.action = action;
    	this.reward = reward;
    	this.endState = endState;
    }
    
    /** Input state s   */
    public double[] state;
    /** Chosen action a */
    public integer action;
    /** Reward for performing action a in state s   */
    public integer reward;
    /** Resultant state after performing action a in state s    */
    public double[] endState;
}