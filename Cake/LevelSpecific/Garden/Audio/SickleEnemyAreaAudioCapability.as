import Peanuts.Audio.AudioStatics;

// Now used in the whole of garden
class USickleEnemyAreaAudioCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAreaAudio");
	
	default RespondToEvent(GardenAudioActions::SickleAreaEntered);
	default RespondToEvent(GardenAudioActions::SickleAreaExited);
	default RespondToEvent(GardenAudioActions::SickleAreaCombatActivated);
	default RespondToEvent(GardenAudioActions::SickleAreaCombatDeactivated);
	default RespondToEvent(GardenAudioActions::SickleAreaAllEnemiesDefeated);
	default RespondToEvent(GardenAudioActions::ShieldedBuldExplosion);

	int InCombatReferenceCount = 0;
	int InAreaReferenceCount = 0;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (IsAnyActionActive())
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		InCombatReferenceCount = 0;
		InAreaReferenceCount = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintEvent)
	void OnEnterArea(bool bCombatActive) {}
	UFUNCTION(BlueprintEvent)
	void OnExitArea(bool bCombatActive) {}
	UFUNCTION(BlueprintEvent)
	void OnEnterCombat() {}
	UFUNCTION(BlueprintEvent)
	void OnExitCombat() {}
	UFUNCTION(BlueprintEvent)
	void OnBulbDestroyed() {}
	UFUNCTION(BlueprintEvent)
	void OnAllEnemiesDefeated() {}

	bool IsAnyActionActive() const
	{
		return 	IsActioning(GardenAudioActions::SickleAreaEntered) ||
				IsActioning(GardenAudioActions::SickleAreaExited) ||
				IsActioning(GardenAudioActions::SickleAreaCombatActivated) ||
				IsActioning(GardenAudioActions::SickleAreaCombatDeactivated) ||
				IsActioning(GardenAudioActions::SickleAreaAllEnemiesDefeated) ||
				IsActioning(GardenAudioActions::ShieldedBuldExplosion);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		bool bWasInCombat = false;
		if(ConsumeAction(GardenAudioActions::SickleAreaCombatActivated) == EActionStateStatus::Active) 
		{
			++InCombatReferenceCount;
			if (InCombatReferenceCount == 1)
			{
				OnEnterCombat();
				// Print(GardenAudioActions::SickleAreaCombatActivated.ToString());
			}
		}
		
		bWasInCombat = InCombatReferenceCount > 0;
		if(ConsumeAction(GardenAudioActions::SickleAreaCombatDeactivated) == EActionStateStatus::Active) 
		{
			--InCombatReferenceCount;
			if (InCombatReferenceCount == 0)
			{
				OnExitCombat();
				// Print(GardenAudioActions::SickleAreaCombatDeactivated.ToString());
			}

		}
		
		if(ConsumeAction(GardenAudioActions::SickleAreaEntered) == EActionStateStatus::Active) 
		{
			++InAreaReferenceCount;
			if (InAreaReferenceCount == 1) 
				OnEnterArea(InCombatReferenceCount > 0);

			// Print(GardenAudioActions::SickleAreaEntered.ToString());
		}

		if(ConsumeAction(GardenAudioActions::SickleAreaExited) == EActionStateStatus::Active) 
		{
			--InAreaReferenceCount;
			if (InAreaReferenceCount == 0)
				OnExitArea(bWasInCombat);

			// Print(GardenAudioActions::SickleAreaExited.ToString());
		}

		if(ConsumeAction(GardenAudioActions::SickleAreaAllEnemiesDefeated) == EActionStateStatus::Active) 
		{
			OnAllEnemiesDefeated();
			// Print(GardenAudioActions::SickleAreaAllEnemiesDefeated.ToString());
		}

		if(ConsumeAction(GardenAudioActions::ShieldedBuldExplosion) == EActionStateStatus::Active) 
		{
			OnBulbDestroyed();
			// Print(GardenAudioActions::ShieldedBuldExplosion.ToString());
		}

		if (IsDebugActive())
			Print("AreaCount: " + InAreaReferenceCount + ", CombatCount: " + InCombatReferenceCount, 0);
	}
}