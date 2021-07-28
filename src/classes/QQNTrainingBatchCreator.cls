public interface QQNTrainingBatchCreator {
    List<QQNQLearningTuple> prepareBatch(QQNAIDriver driver);
}