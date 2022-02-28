import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsActor;
import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsPlayerComponent;

class UMusicalChairsPlayingRoundCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MusicalChairs");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMusicalChairsActor MusicalChairs;

	UMusicalChairsPlayerComponent MayMusicalChairsComp;
	UMusicalChairsPlayerComponent CodyMusicalChairsComp;

	AHazePlayerCharacter May;
	AHazePlayerCharacter Cody;

	float DurationTimer = 0.0f;

	bool bPlayingEffect = false;
	 

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MusicalChairs = Cast<AMusicalChairsActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MusicalChairs.bMayIsReady)
			return EHazeNetworkActivation::DontActivate;

		if(!MusicalChairs.bCodyIsReady)
			return EHazeNetworkActivation::DontActivate;

		if(MusicalChairs.bGameOver)
			return EHazeNetworkActivation::DontActivate;
			
		if(MusicalChairs.bRoundOver)
			return EHazeNetworkActivation::DontActivate;

		if(!MusicalChairs.bFinishedTutorial)
			return EHazeNetworkActivation::DontActivate;
			
		else
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(MusicalChairs.bRoundOver)
			return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MusicalChairs.StartMusicalChairs();
		
		May = Game::GetMay();
		Cody = Game::GetCody();

		MayMusicalChairsComp = UMusicalChairsPlayerComponent::Get(May);
		CodyMusicalChairsComp = UMusicalChairsPlayerComponent::Get(Cody);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!MusicalChairs.bSongIsStopped)
		{
			MusicalChairs.bSongIsStopped = true;

			MusicalChairs.NotesFX.Deactivate();
			bPlayingEffect = false;

			MusicalChairs.OnMusicalChairsMusicStopped.Broadcast();
		}

		MusicalChairs.bShowButtonPrompt = false;
		DurationTimer = 0.0f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		if(MusicalChairs.bCountDownFinished)
		{	
			if(!MusicalChairs.bSongIsStopped)
			{
				DurationTimer += DeltaTime;
				
				if(!bPlayingEffect)
				{
					MusicalChairs.NotesFX.Activate();
					bPlayingEffect = true;
				}

				if(DurationTimer >= MusicalChairs.CurrentPlayingDuration)
				{
					MusicalChairs.NotesFX.Deactivate();
					bPlayingEffect = false;
					MusicalChairs.bSongIsStopped = true;
					MusicalChairs.OnMusicalChairsMusicStopped.Broadcast();
					
					MusicalChairs.bShowButtonPrompt = true;
				}
			}
		}
	}


}