import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkChallenge;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkDeskLid;

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class AHomeworkManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(Category = "References")
	AHomeworkChallenge MathChallenge;

	UPROPERTY(Category = "References")
	AHomeworkChallenge MemoryChallenge;

	UPROPERTY(Category = "References")
	AHomeworkChallenge ConnectChallenge;

	TArray<AHomeworkChallenge> ChallengeArray;

	UPROPERTY(Category = "References")
	AHomeworkDeskLid DeskLid01;

	UPROPERTY(Category = "References")
	AHomeworkDeskLid DeskLid02;

	UPROPERTY(Category = "References")
	AHomeworkDeskLid DeskLid03;

	UPROPERTY(Category = "Timers")
	float MathChallengeTimerDuration;
	
	UPROPERTY(Category = "Timers")
	float MemoryChallengeTimerDuration;
	
	UPROPERTY(Category = "Timers")
	float ConnectChallengeTimerDuration;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ChallengeArray.Add(MathChallenge);
		ChallengeArray.Add(MemoryChallenge);
		ChallengeArray.Add(ConnectChallenge);

		for (AHomeworkChallenge Challenge : ChallengeArray)
		{
			Challenge.ChallengeCompleted.AddUFunction(this, n"ChallengeCompleted");
		}
	}

	UFUNCTION()
	void ChallengeCompleted(AHomeworkChallenge Challenge)
	{
		if (Challenge == MathChallenge)
			DeskLid01.CheckIfLidCanBeOpened();

		if (Challenge == MemoryChallenge)
			DeskLid02.CheckIfLidCanBeOpened();

		if (Challenge == ConnectChallenge)
			DeskLid03.CheckIfLidCanBeOpened();
	}

	UFUNCTION()
	void StartMathChallenge()
	{
		MathChallenge.StartChallenge();
	}	

	UFUNCTION()
	void StartMemoryChallenge()
	{
		MemoryChallenge.StartChallenge();
	}

	UFUNCTION()
	void StartConnectChallenge()
	{
		ConnectChallenge.StartChallenge();
	}
}