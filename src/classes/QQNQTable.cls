public interface QQNQTable {
    /**
     * Get one row of this Q-table corresponding to the specified state
     * @param state Input state
     * @return Q-table row
     */
    double[] getRow(double[] state);
    
    /**
     * Update the value for the specified action corresponding to the row
     * specified by state 
     * @param state Input state (Q-table row identifier)
     * @param action The action for which a Q-table value is to be updated
     * @param error Error computed for Q(s,a)
     */
    void doUpdate(double[] state, integer action, double error);
    
    /**
     * Create a clone of this QTable.
     * @return A clone of this QTable
     */
    QQNQTable deepCopy();
    // 2019/02/15 AI功能改修 by zy BEGIN
    void initNeuron(List<Integer> nActions);
    // 2019/02/15 AI功能改修 by zy END
}