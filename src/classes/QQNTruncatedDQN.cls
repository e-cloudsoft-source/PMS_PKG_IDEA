public class QQNTruncatedDQN {
	private QQNTruncatedDQN__c sfObject;
	
    public QQNTruncatedDQN(QQNTruncatedDQN__c sfObject, QQNQTable qTable, double gamma) {
    	this.sfObject = sfObject;
    	this.qTable = qTable;
    	this.gamma = gamma;
    }
    
    /**
     * Evaluate the best action to perform, given an input state
     * @param state Input state
     * @return Best choice of action
     */
    public integer evaluate(double[] state) {
    	double[] row = getRow(state);
    	return argmax(row);
    }
    
    /**
     * Get one row of the Q-table, given an input state
     * @param state Input state
     * @return A row of the Q-table
     */
    public double[] getRow(double[] state) {
    	return qTable.getRow(state);
    }
    
    /**
     * Update Q(state, action) given the computed error
     * @param state Input state
     * @param action Chosen action
     * @param error Error computed after evaluating state
     */
    public void doUpdate(double[] state, integer action, double error) {
    	qTable.doUpdate(state, action, error);
    }
    
    /**
     * Execute one training step i.e. evaluate a state, compute output
     * error and update the Q-table
     * @param tuple A Q-Learning training tuple <s,a,r,s'>
     * @param frozenQTable The fixed targets to use for training this TDQN
     * @return The computed error term
     */
    public double train(QQNQLearningTuple tuple, QQNQTable frozenQTable) {
    	// 特征组预测
    	double[] qRow = qTable.getRow(tuple.state);
    	// 结果组预测
    	// input -> predict -> output
    	double[] fqRow = frozenQTable.getRow(tuple.endState);
    	double actionRes = tuple.action < qRow.size() ? qRow[tuple.action] : 0;
        system.debug(logginglevel.info,'tuple=' + tuple + ', qRow=' + qRow + 'actionRes：：' + actionRes);
    	// 权重值
    	double error = tuple.reward + gamma * max(fqRow) - actionRes;
            	
        system.debug('tuple=' + tuple + ', qRow=' + qRow + ', error=' + error);
        // 更新神经单位
        // 指定节点权重值更新
    	doUpdate(tuple.state, tuple.action, error);
    	
        return error;
    }
    
    /**
     * Train the TDQN with one batch of training tuples and return the
     * computed Mean Squared Error for the batch
     * @param batch One batch of training tuples
     * @return Computed Mean Squared Error for batch
     */
    public double trainBatch(List<QQNQLearningTuple> batch) {
    	double squareSum = 0;
    	QQNQTable frozenQTable = qTable.deepCopy();
    	
    	for(QQNQLearningTuple tuple : batch) {
    		double error = train(tuple, frozenQTable);
    		squareSum += (error * error);
    	}
    	
        double mse = squareSum / batch.size();
    	return mse;
    }
    
    private static double max(double[] arr) {
    	return arr[argmax(arr)];
    }
    
    private static integer argmax(double[] arr) {
    	integer arrSize = arr.size();
    	integer ret = 0;
    	// 赛选权重最大的序号
    	for(integer i=1; i<arrSize; i++) {
    		if(arr[i] > arr[ret]){
    			ret = i;
    		}
    	}
    	
    	return ret;
    }
    
    public QQNTruncatedDQN__c getSFObject() {
    	return sfObject;
    }
    
    //  Fields
    /** The underlying Q-Table for this TDQN    */
    private QQNQTable qTable;
    /** Discount factor */
    @TestVisible
    private double gamma;
    // 2019/02/15 AI功能改修 by zy BEGIN
    public void initNeuron(List<Integer> nActions){
    	qTable.initNeuron(nActions);
    }
    public List<integer> evaluateLst(double[] state) {
    	double[] row = getRow(state);
    	List<DoubleValue> dbs = new List<DoubleValue>();
        // 2019/03/29 JINYABUG-1552 bug fix by zy BEGIN
    	for (integer i = 0 ; i < row.size() ; i++) {
        // 2019/03/29 JINYABUG-1552 bug fix by zy END
    		double db = row[i];
    		if (db != null) dbs.add(new DoubleValue(db,i));
    	}
    	dbs.sort();
    	List<Integer> result = new List<Integer>();
    	for (DoubleValue dv : dbs) result.add(dv.index);
    	return result;
    }
    class DoubleValue implements Comparable{
    	double value;
    	integer index;
    	public DoubleValue(double val,integer idx) {
    		value = val;
    		index = idx;
    	}
    	public Integer compareTo(Object compareTo) {
	        DoubleValue compareToEmp = (DoubleValue)compareTo;
	        if (value == compareToEmp.value) return 0;
	        if (value > compareToEmp.value) return -1;
	        return 1;       
	    }
    }
    // 2019/02/15 AI功能改修 by zy END
}