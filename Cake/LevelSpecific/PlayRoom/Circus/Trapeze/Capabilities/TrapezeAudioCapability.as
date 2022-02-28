import Cake.LevelSpecific.PlayRoom.Circus.Trapeze.TrapezeActor;
import Vino.Characters.PlayerCharacter;

enum ETrapezeAudioCapabilityState
{
	None,
	WaitingForInitialMovement,
	WaitingForDirectionChange,
	WaitingForTrapezeToStop
}

class UTrapezeAudioCapability : UHazeCapability
{
    default CapabilityTags.Add(TrapezeTags::Trapeze);
	default CapabilityTags.Add(TrapezeTags::Audio);

	default CapabilityDebugCategory = TrapezeTags::Trapeze;

	UPROPERTY(BlueprintReadOnly)
	APlayerCharacter PlayerOwner;

	UPROPERTY(BlueprintReadOnly)
	ATrapezeActor TrapezeActor;

	UPROPERTY(BlueprintReadOnly)
	UTrapezeComponent TrapezeComponent;

	ETrapezeAudioCapabilityState AudioCapabilityState;

	UPROPERTY()
	const FName AkStateGroup = n"MStg_Playroom_Goldberg";

	float PreviousTrapezeForwardDotVelocity;

	bool bHasPlayedShitThrowBark = false;
	bool bHasPlayedShitCatchBark = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<APlayerCharacter>(Owner);
		TrapezeComponent = UTrapezeComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!TrapezeComponent.IsSwinging())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TrapezeActor = Cast<ATrapezeActor>(TrapezeComponent.GetTrapezeActor());
		AudioCapabilityState = ETrapezeAudioCapabilityState::WaitingForInitialMovement;

		TrapezeActor.OnPlayerReleasedSwingEvent.AddUFunction(this, n"OnPlayerStoppedSwinging");
		TrapezeActor.OnBothPlayersSwingingEvent.AddUFunction(this, n"OnBothPlayersStartedSwinging");
		TrapezeActor.OnMarbleCaughtEvent.AddUFunction(this, n"OnMarbleCaught");
		TrapezeActor.OnMarbleShitThrowEvent.AddUFunction(this, n"OnMarbleShitThrow");

		TrapezeActor.Marble.OnMarbleReadyForReset.AddUFunction(this, n"OnMarbleDestroyed");
		TrapezeActor.Marble.OnMarbleSpawnEvent.AddUFunction(this, n"OnMarbleSpawned");
		TrapezeActor.Marble.OnMarbleEnteredReceptacle.AddUFunction(this, n"OnMarbleEnteredReceptacle");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Update velocity variables
		float TrapezeForwardDotVelocity = TrapezeActor.ActorForwardVector.DotProduct(TrapezeActor.SwingMesh.ComponentVelocity.GetSafeNormal());
		TrapezeActor.HazeAkComponent.SetRTPCValue("Rtpc_Goldberg_Circus_Trapeze_Direction", 1.f * FMath::Sign(TrapezeForwardDotVelocity), 0);
		TrapezeActor.HazeAkComponent.SetRTPCValue("Rtpc_Goldberg_Circus_Trapeze_Velocity", TrapezeActor.GetNormalizedSpeed(), 0);

		// Update intensity (distance between players)
		if(TrapezeComponent.BothPlayersAreSwinging())
		{
			float PlayerDistance = FMath::Clamp(PlayerOwner.GetDistanceTo(PlayerOwner.OtherPlayer), 500.f, 3000.f) - 500.f;
			float NormalPlayerDistance = 1 - (PlayerDistance / 2500.f);
			TrapezeActor.HazeAkComponent.SetRTPCValue("RTPC_BalanceIntensity", NormalPlayerDistance);
		}

		// Update events
		switch(AudioCapabilityState)
		{
			case ETrapezeAudioCapabilityState::WaitingForInitialMovement:
				if(TrapezeActor.SwingMesh.ComponentVelocity.IsZero())
					break;

				TrapezeActor.HazeAkComponent.HazePostEvent(TrapezeActor.StartSwingEvent);
				AudioCapabilityState = ETrapezeAudioCapabilityState::WaitingForDirectionChange;
				break;

			case ETrapezeAudioCapabilityState::WaitingForDirectionChange:
				if(FMath::Sign(TrapezeForwardDotVelocity) == FMath::Sign(PreviousTrapezeForwardDotVelocity))
					break;

				TrapezeActor.HazeAkComponent.HazePostEvent(TrapezeForwardDotVelocity < 0.f ?
					TrapezeActor.BackwardsDirectionEvent :
					TrapezeActor.ForwardsDirectionEvent);

				PreviousTrapezeForwardDotVelocity = TrapezeForwardDotVelocity;
				break;

			case ETrapezeAudioCapabilityState::WaitingForTrapezeToStop:
				if(TrapezeActor.SwingIsLerpingToRestPosition())
					break;

				TrapezeActor.HazeAkComponent.HazePostEvent(TrapezeActor.StopSwingEvent);
				AudioCapabilityState = ETrapezeAudioCapabilityState::None;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(AudioCapabilityState == ETrapezeAudioCapabilityState::None)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TrapezeActor.HazeAkComponent.HazeStopEvent();
		AudioCapabilityState = ETrapezeAudioCapabilityState::None;

		TrapezeActor.OnPlayerReleasedSwingEvent.Unbind(this, n"OnPlayerStoppedSwinging");
		TrapezeActor.OnBothPlayersSwingingEvent.Unbind(this, n"OnBothPlayersStartedSwinging");
		TrapezeActor.OnMarbleCaughtEvent.Unbind(this, n"OnMarbleCaught");
		TrapezeActor.OnMarbleShitThrowEvent.Unbind(this, n"OnMarbleShitThrow");

		TrapezeActor.Marble.OnMarbleReadyForReset.Unbind(this, n"OnMarbleDestroyed");
		TrapezeActor.Marble.OnMarbleSpawnEvent.Unbind(this, n"OnMarbleSpawned");
		TrapezeActor.Marble.OnMarbleEnteredReceptacle.Unbind(this, n"OnMarbleEnteredReceptacle");

		TrapezeActor = nullptr;
	}


	UFUNCTION(BlueprintEvent, DisplayName = "OnPlayerStoppedSwinging")
	void BP_OnPlayerStoppedSwinging(AHazePlayerCharacter PlayerCharacter) { }
	UFUNCTION(NotBlueprintCallable)
	void OnPlayerStoppedSwinging(AHazePlayerCharacter PlayerCharacter)
	{
		AudioCapabilityState = ETrapezeAudioCapabilityState::WaitingForTrapezeToStop;

		// Return to circus music
		// AkGameplay::SetState(AkStateGroup, n"MStt_Playroom_Goldberg_Circus_Main");

		BP_OnPlayerStoppedSwinging(PlayerCharacter);
	}

	UFUNCTION(BlueprintEvent, DisplayName = "OnBothPlayersStartedSwinging")
	void BP_OnBothPlayersStartedSwinging() { }
	UFUNCTION(NotBlueprintCallable)
	void OnBothPlayersStartedSwinging()
	{
		// AkGameplay::SetState(AkStateGroup, n"MStt_Playroom_Goldberg_Circus_Balance");

		BP_OnBothPlayersStartedSwinging();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "OnMarbleSpawned")
	void BP_OnMarbleSpawned(ATrapezeMarbleActor Marble, bool bBothPlayersAreSwinging) { }
	UFUNCTION(NotBlueprintCallable)
	void OnMarbleSpawned(ATrapezeMarbleActor Marble)
	{
		// if(TrapezeComponent.BothPlayersAreSwinging())
		// 	AkGameplay::SetState(AkStateGroup, n"MStt_Playroom_Goldberg_Circus_Balance");
		// else
		// 	AkGameplay::SetState(AkStateGroup, n"MStt_Playroom_Goldberg_Circus_Main");

		BP_OnMarbleSpawned(Marble, TrapezeComponent.BothPlayersAreSwinging());
	}

	UFUNCTION(BlueprintEvent, DisplayName = "OnMarbleCaught")
	void BP_OnMarbleCaught() { }
	UFUNCTION(NotBlueprintCallable)
	void OnMarbleCaught()
	{
		// TrapezeActor.HazeAkComponent.PostTrigger("MStr_Goldberg_Circus_Catch");

		BP_OnMarbleCaught();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "OnMarbleEnteredReceptacle")
	void BP_OnMarbleEnteredReceptacle() { }
	UFUNCTION(NotBlueprintCallable)
	void OnMarbleEnteredReceptacle(ATrapezeMarbleActor Marble)
	{
		// AkGameplay::SetState(AkStateGroup, n"MStt_Playroom_Goldberg_Circus_Main");
		// TrapezeActor.HazeAkComponent.PostTrigger("MStr_Goldberg_Circus_TrapezeSuccess");

		BP_OnMarbleEnteredReceptacle();
	}

	UFUNCTION(BlueprintEvent, DisplayName = "OnMarbleDestroyed")
	void BP_OnMarbleDestroyed(bool bBothPlayersAreSwinging) { }
	UFUNCTION(NotBlueprintCallable)
	void OnMarbleDestroyed(ATrapezeMarbleActor Marble)
	{
		// if(TrapezeComponent.BothPlayersAreSwinging())
		// 	AkGameplay::SetState(AkStateGroup, n"MStt_Playroom_Goldberg_Circus_Balance_Fail");
		// else
		// 	TrapezeActor.HazeAkComponent.PostTrigger("MStr_Goldberg_Circus_DropBallSingle");

		BP_OnMarbleDestroyed(TrapezeComponent.BothPlayersAreSwinging());

		// Check if player should play shit catch bark
		if(ShouldPlayShitCatchBark(Marble))
		{
			FName EventName = PlayerOwner.IsCody() ?
				TrapezeActor.CatchFailCodyVOEventName :
				TrapezeActor.CatchFailMayVOEventName;

			PlayFoghornVOBankEvent(TrapezeActor.VOBank, EventName);
			bHasPlayedShitCatchBark = true;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnMarbleShitThrow(AHazePlayerCharacter PlayerCharacter, ATrapezeActor Trapeze)
	{
		if(bHasPlayedShitThrowBark || !OtherPlayerIsSwinging())
			return;

		FName EventName = PlayerCharacter.IsCody() ?
			Trapeze.ThrowFailCodyVOEventName :
			Trapeze.ThrowFailMayVOEventName;

		PlayFoghornVOBankEvent(Trapeze.VOBank, EventName);
		bHasPlayedShitThrowBark = true;
	}

	bool ShouldPlayShitCatchBark(const ATrapezeMarbleActor& Marble) const
	{
		if(bHasPlayedShitCatchBark)
			return false;

		if(TrapezeActor == nullptr)
			return false;

		if(!TrapezeActor.bIsCatchingEnd)
			return false;

		if(!Marble.bWasWithinReachOfCatcherSide)
			return false;

		if(!OtherPlayerIsSwinging())
			return false;

		return true;
	}

	bool OtherPlayerIsSwinging() const
	{
		return PlayerOwner.OtherPlayer.IsAnyCapabilityActive(TrapezeTags::Swing);
	}
}