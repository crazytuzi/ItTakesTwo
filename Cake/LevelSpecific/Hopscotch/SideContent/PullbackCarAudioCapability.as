import Cake.LevelSpecific.Hopscotch.SideContent.PullbackCar;

class UPullbackCarAudioCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PullbackCarAudioCapability");

	default CapabilityDebugCategory = n"PullbackCarAudioCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	// HazeAkComponent is attached to this PullbackCar actor. "PullbackCar.HazeAkComponent"
	APullbackCar PullbackCar;
	UHazeMovementComponent MoveComp;
	UHazeAkComponent HazeAkComponent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_PlayVelocityLoop_AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_StopVelocityLoop_AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_PlayWindUpLoop_AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_StopWindUpLoop_AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_Explode_AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_Airborne_AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_Launch_AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_PlayIdle_AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_StopIdle_AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_Ignition_AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_PlayerCrash_AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_PlayHonk_AudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PBC_StopHonk_AudioEvent;

	// Current windup value
	float WindupValue = 0.f;	

	// Maximum windup force has been reached
	bool bWindupMaxedOut = false;
	
	// If a player is holding the car
	bool bCarBeingWoundUp = false;

	bool bHasHonked = false;

	bool bIsWoke = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PullbackCar = Cast<APullbackCar>(Owner);
		MoveComp = UHazeMovementComponent::Get(PullbackCar);

		PullbackCar.PullbackCarAudioDriverInteracted.AddUFunction(this, n"DriverInteracted");
		PullbackCar.PullbackCarAudioWindupPlayerInteracted.AddUFunction(this, n"WindupPlayerInteracted");
		PullbackCar.OnPullbackCarWasDestroyed.AddUFunction(this, n"CarWasDestroyed");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (PullbackCar != nullptr)
			return EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PullbackCar == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!PullbackCar.HazeAkComponent.bIsEnabled)
			return;

		if (ConsumeAction(n"AudioLaunchCar") == EActionStateStatus::Active)
		{
			PullbackCar.HazeAkComponent.HazePostEvent(PBC_StopWindUpLoop_AudioEvent);
			PullbackCar.HazeAkComponent.HazePostEvent(PBC_Launch_AudioEvent);
			PullbackCar.HazeAkComponent.HazePostEvent(PBC_StopIdle_AudioEvent);
			//PrintScaled("LaunchedCar", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioGrabCar") == EActionStateStatus::Active)
		{
			PullbackCar.HazeAkComponent.HazePostEvent(PBC_Ignition_AudioEvent);
			PullbackCar.HazeAkComponent.HazePostEvent(PBC_PlayIdle_AudioEvent);
			PullbackCar.HazeAkComponent.HazePostEvent(PBC_PlayWindUpLoop_AudioEvent);
			//PrintScaled("GrabbedCar", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioCarIsAirborne") == EActionStateStatus::Active)
		{
			PullbackCar.HazeAkComponent.HazePostEvent(PBC_Airborne_AudioEvent);
			//PullbackCar.HazeAkComponent.HazePostEvent(PBC_StopVelocityLoop_AudioEvent);
			//PrintScaled("Airborne", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioCarNotAirborne") == EActionStateStatus::Active)
		{
			//PrintScaled("NOTAirborne", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioCarExploded") == EActionStateStatus::Active)
		{
			//PullbackCar.HazeAkComponent.HazePostEvent(PBC_Explode_AudioEvent);
			UHazeAkComponent::HazePostEventFireForget(PBC_Explode_AudioEvent, PullbackCar.GetActorTransform());
			//PrintScaled("CarExploded", 2.f, FLinearColor::Black, 2.f);
		}

		if (ConsumeAction(n"AudioPlayerHitByCar") == EActionStateStatus::Active)
		{
			PullbackCar.HazeAkComponent.HazePostEvent(PBC_PlayerCrash_AudioEvent);
			//PrintScaled("PlayerHitByCar", 2.f, FLinearColor::Black, 2.f);
		}
	
		
		//-----------------------
		// Useful values for RTPC

		// VELOCITY RTPC
		PullbackCar.HazeAkComponent.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interactions_PullBackCar_Velocity", MoveComp.Velocity.Size());
		// PrintToScreen("Velocity " + MoveComp.Velocity.Size());

		// Goes from 0 to 1.5. Higher value means greater speed when the car is being released.
		WindupValue = GetAttributeValue(n"PullbackCarWindupAmount");
		PullbackCar.HazeAkComponent.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interactions_PullBackCar_WindUp", WindupValue);
		//PrintToScreen("WindUpValue" + WindupValue);
		
		// This is only true if WindupValue goes all the way up to 1.5.
		bWindupMaxedOut = WindupValue >= 1.5f ? true : false;

		// If the driving player is honking
		if (PullbackCar.CanHonk() && !bHasHonked && PullbackCar.bPlayerIsHonking)
		{
			bHasHonked = true;
			OnActorHonk(true);
		} 
		else if ((!PullbackCar.CanHonk() || !PullbackCar.bPlayerIsHonking) && bHasHonked)
		{
			bHasHonked = false;
			OnActorHonk(false);
		}
			

		if (MoveComp.Velocity.Size() < 100.f && bIsWoke)
		{
			bIsWoke = false;
			OnSleep();
		}

		if (MoveComp.Velocity.Size() > 100.f && !bIsWoke)
		{
			bIsWoke = true;
			OnWake();
		}
	}

	void OnActorHonk(bool bHonked)
	{
		if (bHonked)
			PullbackCar.HazeAkComponent.HazePostEvent(PBC_PlayHonk_AudioEvent);
		else
			PullbackCar.HazeAkComponent.HazePostEvent(PBC_StopHonk_AudioEvent);
	}

	// If a player jumped in or out of the car
	UFUNCTION()
	void DriverInteracted(bool bJumpedIn)
	{
		
	}

	// True when grabbing car, false when releasing
	UFUNCTION()
	void WindupPlayerInteracted(bool bGrabbedCar)
	{	
		bCarBeingWoundUp = bGrabbedCar;
	}

	// Begin called whenever the car is being destroyed
	UFUNCTION()
	void CarWasDestroyed()
	{
		
	}

	UFUNCTION()
	void OnWake()
	{
		PullbackCar.HazeAkComponent.HazePostEvent(PBC_PlayVelocityLoop_AudioEvent);
		//Print("OnWake!");
	}

	UFUNCTION()
	void OnSleep()
	{
		PullbackCar.HazeAkComponent.HazePostEvent(PBC_StopVelocityLoop_AudioEvent);
		//Print("OnSleep");
	}
}