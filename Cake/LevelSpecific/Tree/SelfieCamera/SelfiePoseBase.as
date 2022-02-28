event void FOnStageTurnStarted();
event void FOnStageTurnCompleted();

class ASelfiePoseBase : AHazeActor
{
	FOnStageTurnStarted OnStageTurnStarted;

	FOnStageTurnCompleted OnStageTurnCompleted;

	void BindFunctions() {}
}