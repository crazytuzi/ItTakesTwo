import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsActor;
import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsPlayerComponent;

class UMusicalChairsEndOfRoundCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MusicalChairs");

	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AMusicalChairsActor MusicalChairs;

	UMusicalChairsPlayerComponent MayMusicalChairsComp;
	UMusicalChairsPlayerComponent CodyMusicalChairsComp;

	AHazePlayerCharacter May;
	AHazePlayerCharacter Cody;

	float RoundOverDuration = 2.0f;
	float RoundOverTimer = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MusicalChairs = Cast<AMusicalChairsActor>(Owner);

		May = Game::GetMay();
		Cody = Game::GetCody();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MusicalChairs.bRoundOver)
			return EHazeNetworkActivation::DontActivate;
		else
			return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(RoundOverTimer >= RoundOverDuration)
			return EHazeNetworkDeactivation::DeactivateLocal;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(MayMusicalChairsComp == nullptr)
			MayMusicalChairsComp = UMusicalChairsPlayerComponent::Get(May);

		if(CodyMusicalChairsComp == nullptr)
			CodyMusicalChairsComp = UMusicalChairsPlayerComponent::Get(Cody);

		if(MusicalChairs.WinState == EMusicalChairsRoundWinState::MayWon)
		{
			MusicalChairs.AddScoreToMay();
		}
		else if(MusicalChairs.WinState == EMusicalChairsRoundWinState::CodyLost)
		{
			MusicalChairs.AddScoreToMay();
		}
		if(MusicalChairs.WinState == EMusicalChairsRoundWinState::CodyWon)
		{
			MusicalChairs.AddScoreToCody();
		}
		else if(MusicalChairs.WinState == EMusicalChairsRoundWinState::MayLost)
		{
			MusicalChairs.AddScoreToCody();
		}
		

		MusicalChairs.bRoundEnded = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RoundOverTimer = 0.0f;
		MusicalChairs.bRoundOver = false;
		MusicalChairs.bRoundEnded = false;
		MusicalChairs.RoundNumber++;
		MusicalChairs.bCountDownFinished = false;

		int CodyScore = MusicalChairs.MinigameComp.GetCodyScore();
		int MayScore = MusicalChairs.MinigameComp.GetMayScore();
		
		if(CodyScore >= MusicalChairs.ScoreLimit || MayScore >= MusicalChairs.ScoreLimit)
		{
			MusicalChairs.GameOver();
		}
		else
		{
			MusicalChairs.bCodyIsReady = true;
			MusicalChairs.bMayIsReady = true;
			
			May.SetCapabilityActionState(n"StartMusicalChairs", EHazeActionState::Active);
			Cody.SetCapabilityActionState(n"StartMusicalChairs", EHazeActionState::Active);
		}

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		RoundOverTimer += DeltaTime;
	}
}