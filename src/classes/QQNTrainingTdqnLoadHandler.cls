public with sharing class QQNTrainingTdqnLoadHandler implements QQNTdqnLoadHandler {
	public void tdqnLoaded(QQNAIDriver driver) {
		driver.trainTDQN();
	}
}