import Vino.Triggers.VOBarkPlayerLookAtTrigger;
event void FOnFinishTurtleQuest();
event void FOnActivateTurtles();

class ASnowTurtleEventManager : AHazeActor
{
	UPROPERTY()
	TArray<AHazeActor> TurtlesArray;

	bool bEventActivated;

	int TurtleCount = 0;

	UPROPERTY()
	FOnFinishTurtleQuest OnFinishTurtleQuest;

	UPROPERTY()
	FOnActivateTurtles OnActivateTurtles;

	UPROPERTY()
	AVOBarkPlayerLookAtTrigger LookAtVOTrigger;

	UFUNCTION()
	void ActivateSnowTurtles()
	{
		if (!bEventActivated)
		{
			bEventActivated = true;
			OnActivateTurtles.Broadcast();
			
			for (AHazeActor Turtle : TurtlesArray)
			{
				Turtle.SetCapabilityActionState(n"AudioStart", EHazeActionState::ActiveForOneFrame);
			}
		}
	}

	UFUNCTION()
	void CheckForCompletedQuest()
	{
		TurtleCount++;

		if (LookAtVOTrigger.IsActorDisabled(this))
			LookAtVOTrigger.DisableActor(this);

		if (TurtleCount >= 4)
			FinishTurtleQuest();
	}

	UFUNCTION()
	void FinishTurtleQuest()
	{
		OnFinishTurtleQuest.Broadcast();

		Online::UnlockAchievement(Game::May, n"TurtleFamilyReunite");
		Online::UnlockAchievement(Game::Cody, n"TurtleFamilyReunite");
	}
}

