import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsActor;
import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsPlayerComponent;

class UMusicalChairsGameOverCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MusicalChairs");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMusicalChairsActor MusicalChairs;

	// UMusicalChairsPlayerComponent MayMusicalChairsComp;
	// UMusicalChairsPlayerComponent CodyMusicalChairsComp;

	// AHazePlayerCharacter May;
	// AHazePlayerCharacter Cody;

	// float GameOverDuration = 2.0f;
	// float GameOverTimer = 0.0f;
	
	bool bVictoryScreenFinished = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MusicalChairs = Cast<AMusicalChairsActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MusicalChairs.bGameOver)
			return EHazeNetworkActivation::DontActivate;
			
		if(MusicalChairs.MinigameComp.GetCodyScore() != MusicalChairs.MinigameComp.GetMayScore() && !MusicalChairs.bWinnerReachedSeat)
			return EHazeNetworkActivation::DontActivate;

		if(!MusicalChairs.bMayFinishedAnimations)
			return EHazeNetworkActivation::DontActivate;
			
		if(!MusicalChairs.bCodyFinishedAnimations)
			return EHazeNetworkActivation::DontActivate;

		else
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bVictoryScreenFinished)
			return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MusicalChairs.MinigameComp.OnMinigameVictoryScreenFinished.AddUFunction(this, n"OnWinnerScreenFinished");
		MusicalChairs.MinigameComp.AnnounceWinner();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bVictoryScreenFinished = false;
		
		MusicalChairs.OnMusicalChairsGameOver.Broadcast();

		MusicalChairs.ResetMusicalChairs();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}

	UFUNCTION()
	void OnWinnerScreenFinished()
	{
		bVictoryScreenFinished = true;
	}
}