import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;

// Displays active sequences durations, is for QA rendering some complex sequences
class UAudioDebugActiveSequencesCapability : UHazeDebugCapability
{
	private TSet<FName> ActiveSequences;

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		DebugValues.AddDebugSettingsValue(n"EnableAudioDebugActiveSequences", 1, "Prints a scaled message about all actively playing sequences", true);
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		int NewValue = 0;
		if (!Owner.GetDebugValue(n"EnableAudioDebugActiveSequences", NewValue) || NewValue == 0)
		{
			return;
		}

		DebugActiveSequences();
	}

	void DebugActiveSequences()
	{
		TArray<UHazeAkComponent> Comps;
		UHazeAkComponent::GetAllHazeAkComponents(Comps);
		for (UHazeAkComponent HazeAkComp : Comps)
		{
			if (HazeAkComp == nullptr)
				continue;

			for(const auto EventInstance: HazeAkComp.ActiveEventInstances)
			{
				if ((EventInstance.PostEventType & EHazeAudioPostEventType::Sequence) != 0)
				{
					int32 PlayPos = 0;
					if (UHazeAkComponent::GetSourcePlayPosition(EventInstance.PlayingID, PlayPos))
						PrintToScreen(EventInstance.EventName + ",  PlayPos: " + (PlayPos / 1000.f));
				}

			}
		}
		
		TArray<AHazeLevelSequenceActor> Actors;
		Audio::GetAllLevelSequenceActors(Actors);

		TSet<ULevelSequencePlayer> SequencePlayers;
		TSet<FName> CurrentSequences;

		const float Scale = 2.0f;
		const FLinearColor Color = FLinearColor::Yellow;

		for (AHazeLevelSequenceActor Actor: Actors)
		{
			if (Actor == nullptr || 
				Actor.SequencePlayer == nullptr || 
				SequencePlayers.Contains(Actor.SequencePlayer))
				continue;

			SequencePlayers.Add(Actor.SequencePlayer);
			if (!Actor.SequencePlayer.IsPlaying())
				continue;	
			
			CurrentSequences.Add(Actor.LevelSequence.Name);

			float Length = Actor.GetDurationAsSeconds();
			float Current = Length - Actor.GetTimeRemaining();

			if (!ActiveSequences.Contains(Actor.LevelSequence.Name))
				PrintToScreenScaled("   START", 0.f, Color,Scale);				

			PrintToScreenScaled("    TIME: " + Current + " / " + Length, 0.f, Color, Scale);
			PrintToScreenScaled("SEQUENCE: " + Actor.LevelSequence.Name, 0.f, Color, Scale);
		}

		for (FName SequenceName : ActiveSequences)
		{
			if (!CurrentSequences.Contains(SequenceName))
				PrintToScreenScaled("   STOP", 0.f, Color, Scale);
		}
		
		ActiveSequences = CurrentSequences;
	}		
}	