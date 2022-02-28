import Cake.LevelSpecific.Music.Classic.Capabilities.KeyBirdEvaluationBaseCapability;

class UKeyBirdEvaluationSeekKeyCapability : UKeyBirdEvaluationBaseCapability
{
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);

		UMusicalFollowerKeyTeam KeyTeam = Cast<UMusicalFollowerKeyTeam>(HazeAIBlueprintHelper::GetTeam(n"MusicalKeyTeam"));

		if(KeyTeam == nullptr)
			return;

		TSet<AHazeActor> AllKeys = KeyTeam.GetMembers();

		AMusicalFollowerKey AvailableKey = nullptr;
		for(AHazeActor KeyActor : AllKeys)
		{
			AMusicalFollowerKey Key = Cast<AMusicalFollowerKey>(KeyActor);

			if(Key != nullptr && !Key.IsUsed() && !Key.HasFollowTarget() && CombatArea.IsInsideCombatArea(Key.ActorLocation))
			{
				// Okay so this key has no follow target.
				AvailableKey = Key;
				break;
			}
		}

		if(AvailableKey == nullptr)
			return;

		AKeyBird ChosenKeyBird = EvaluateTargets(AvailableKey);

		if(ChosenKeyBird == nullptr)
			return;

		ChosenKeyBird.SetNewSeekTarget(AvailableKey, EKeyBirdState::SeekKey);
	}

	bool HasMaxOfCounter(UKeyBirdTeam KeyBirdTeam) const
	{
		return KeyBirdTeam.NumKeySeekers < CombatArea.MaxNumKeySeekers;
	}

	float GetFrequenzyMin() const property
	{
		return CombatArea.SeekKeyFrequencyMin;
	}

	float GetFrequenzyMax() const property
	{
		return CombatArea.SeekKeyFrequencyMax;
	}

	EKeyBirdTeamCounterType GetCounterType() const property
	{
		return EKeyBirdTeamCounterType::KeySeeker;
	}

	float GetAverageDistance() const property
	{
		return CombatArea.AverageDistanceSeek;
	}
}
