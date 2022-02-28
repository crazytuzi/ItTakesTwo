import Cake.LevelSpecific.SnowGlobe.MagnetHockey.HockeyPuck;
event void FGoalScored(AHazePlayerCharacter Player);

enum EHockeyGoalPlayerOwner
{
	May,
	Cody 
};

class AHockeyGoals : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(Category = "Setup")
	EHockeyGoalPlayerOwner HockeyGoalPlayerOwner;

	TArray<AHockeyPuck> HockeyPuckArray;

	AHockeyPuck HockeyPuck;

	FGoalScored OnGoalScoredEvent;

	//Will also require a reset
	bool bHaveScored;

	bool bCanScore;

	UPROPERTY(Category = "ScoringParameters")
	float RightMin = -1300.f;
	
	UPROPERTY(Category = "ScoringParameters")
	float RightMax = 1300.f;

	UPROPERTY(Category = "ScoringParameters")
	float ForwardMax = 150.f;

	UPROPERTY(Category = "ScoringParameters")
	float ForwardMin = -682.f;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(HockeyPuckArray);
		HockeyPuck = HockeyPuckArray[0];
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		//Either control fires it OR both sides are checking, and whoever reaches first then makes the call... maybe
		if (HasControl())
			CheckGoalScored();
		
		// PrintToScreen("bCanScore: " + bCanScore);
	}

	//If we have control, run this
	UFUNCTION()
	void CheckGoalScored()
	{
		if (!bCanScore)
			return;

		if (bHaveScored)
			return;

		FVector DeltaDirection = HockeyPuck.ActorLocation - ActorLocation; 
		// FVector RightDelta = HockeyPuck.ActorLocation - ActorLocation;

		float DistanceFromForward = ActorForwardVector.DotProduct(DeltaDirection);
		float DistanceFromRight = ActorRightVector.DotProduct(DeltaDirection);
		
		PrintToScreen("DistanceFromRight: " + DistanceFromRight);
		// PrintToScreen("DistanceFromForward: " + DistanceFromForward);

		if (DistanceFromRight < RightMin || DistanceFromRight > RightMax)
			return;

		if (DistanceFromForward > ForwardMax)
			return;

		if (DistanceFromForward < ForwardMin)
			return;

		if (!bHaveScored)
		{
			Print("SCORE GOAL", 20.f);
			bHaveScored = true;
			GoalScored();
		}
	}

	UFUNCTION()
	void GoalScored()
	{
		if (HockeyGoalPlayerOwner == EHockeyGoalPlayerOwner::May)
			OnGoalScoredEvent.Broadcast(Game::GetCody());
		else
			OnGoalScoredEvent.Broadcast(Game::GetMay());
	}

	UFUNCTION()
	void SetPlayerOwner(EHockeyGoalPlayerOwner PlayerOwner)
	{
		HockeyGoalPlayerOwner = PlayerOwner;
	}

	UFUNCTION()
	void ResetbScoringState()
	{
		bHaveScored = false;
	}
}