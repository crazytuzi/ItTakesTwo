import Vino.LevelSpecific.Garden.ValveTurnInteractionActor;

class UValveTurnInteractionAudioCapability : UHazeCapability
{
	UPROPERTY()
	UAkAudioEvent OnStartInteraction;

	UPROPERTY()
	UAkAudioEvent OnStopInteraction;

	UPROPERTY()
	UAkAudioEvent OnChangeDirection;

	UPROPERTY()
	UAkAudioEvent OnFullyTurned;

	UPROPERTY()
	UAkAudioEvent OnBlocked;

	AValveTurnInteractionActor Valve;
	UHazeAkComponent HazeAkComp;

	float LastActiveDirection;
	float LastTurnProgress;
	float LastTurnSpeed;
	float LastTurnDirection;

	FRotator LastRotator;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(Valve == nullptr)
		{
			UObject Temp;
			if(ConsumeAttribute(n"AudioValveToTurn", Temp))
			{
				Valve = Cast<AValveTurnInteractionActor>(Temp);
			}		
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Valve == nullptr)	
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		HazeAkComp = UHazeAkComponent::GetOrCreate(Valve);

		if(HazeAkComp != nullptr)
			HazeAkComp.HazePostEvent(OnStartInteraction);
	}
	
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(HazeAkComp != nullptr)
			HazeAkComp.HazePostEvent(OnStopInteraction);		
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		if(ConsumeAction(n"AudioStoppedInteraction") == EActionStateStatus::Active)
			Valve = nullptr;

		if(Valve == nullptr)
			return;

		const float TurnProgress = Valve.SyncComponent.Value;
		if(LastTurnProgress > 0 && TurnProgress == 0)
		{
			HazeAkComp.HazePostEvent(OnBlocked);
			//PrintToScreen("blocked", 1);
		}
			


		const float TurnDirection = FMath::Sign(TurnProgress - LastTurnProgress);
		if(TurnDirection != LastTurnDirection)
		{
			HazeAkComp.SetRTPCValue("Rtpc_World_Shared_Interactables_Rotators_Direction", TurnDirection);
			LastTurnDirection = TurnDirection;

			if(TurnDirection != 0)
				HazeAkComp.HazePostEvent(OnChangeDirection);
		}

		float TurnSpeed = FMath::Abs(TurnDirection);
		if(TurnSpeed != LastTurnSpeed)
		{
			HazeAkComp.SetRTPCValue("Rtpc_World_Shared_Interactables_Rotators_Velocity", TurnSpeed);
			LastTurnSpeed = TurnSpeed;
			//PrintToScreen("TurnSpeed: " + TurnSpeed);
		}		

		if(TurnProgress >= Valve.MaxValue && TurnProgress != LastTurnProgress)
		{
			HazeAkComp.HazePostEvent(OnFullyTurned);
			LastTurnProgress = TurnProgress;
			//PrintToScreen("Fully turned", 1);
		}
					
		LastTurnProgress = TurnProgress;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Valve != nullptr)	
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

}