import Cake.LevelSpecific.Music.Classic.Capabilities.KeyBirdEvaluationBaseCapability;

class UKeyBirdEvaluationStealKeyCapability : UKeyBirdEvaluationBaseCapability
{
	TArray<AHazePlayerCharacter> PlayerList;
	TArray<AHazePlayerCharacter> AvailablePlayers;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		Super::Setup(SetupParams);
		PlayerList.Add(Game::GetMay());
		PlayerList.Add(Game::GetCody());
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		AvailablePlayers.Reset();

		// Let's pick a player
		for(AHazePlayerCharacter Player : PlayerList)
		{
			if(KeyBirdCommon::IsPlayerValidTarget(Player, CombatArea))
			{
				AvailablePlayers.Add(Player);
			}
		}

		if(AvailablePlayers.Num() == 0)
			return;

		AvailablePlayers.Shuffle();

		AKeyBird ChosenKeyBird = EvaluateTargets(AvailablePlayers[0]);

		if(ChosenKeyBird == nullptr)
			return;

		ChosenKeyBird.SetNewTargetPlayer(AvailablePlayers[0]);
	}

	bool HasMaxOfCounter(UKeyBirdTeam KeyBirdTeam) const
	{
		return KeyBirdTeam.NumKeyStealers < CombatArea.MaxNumKeyStealers;
	}
	
	float GetFrequenzyMin() const
	{
		return CombatArea.SeekKeyFrequencyMin;
	}

	float GetFrequenzyMax() const
	{
		return CombatArea.SeekKeyFrequencyMax;
	}

	EKeyBirdTeamCounterType GetCounterType() const
	{
		return EKeyBirdTeamCounterType::KeySeeker;
	}

	float GetAverageDistance() const
	{
		return CombatArea.AverageDistanceSteal;
	}
}
