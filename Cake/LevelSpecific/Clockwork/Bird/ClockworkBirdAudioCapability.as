import Peanuts.Audio.AudioStatics;
import Cake.LevelSpecific.Clockwork.Bird.ClockworkBird;
import Vino.Movement.Components.MovementComponent;

class ClockworkBirdAudioCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::AfterPhysics;

	AHazePlayerCharacter Player;
	AClockworkBird Bird;
	UHazeAkComponent BirdHazeAkComp;
	UHazeMovementComponent MoveComp;

	private float LastTiltRtpcValue;
	private float LastRollRtpcValue;
	private float LastBirdIsFlyingRtpc;	
	private float LastIsGlidingRtpcValue;
	private float LastNormalizedLeftWingVelo;
	private float LastNormalizedRightWingVelo;

	private FVector BirdLocation;
	private FVector LastBirdLocation;
	private FVector BirdVeloVector;

	private FVector LastLeftWingPosition;
	private FVector LastRightWingPosition;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent Idle;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent Mount;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent Dismount;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnEnterForcefieldEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnEnterForcefieldBirdEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent OnExitForcefieldEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent VocalStartFlyingEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent VocalLandingEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent FlapWingsEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent LaunchEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent DeathEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent RespawnEvent;

	private bool bWasMounted = false;
	private bool bInsideTimeSphere = false;
	private float TimeSphereTimer = 0.f;
	private bool bWasFlying = false;

	const float GROUNDED_MAX_SPEED = 100.f;
	const float FLYING_MAX_SPEED = 6500.f;
	FHazeAudioEventInstance IdleEventInstance;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Bird = Cast<AClockworkBird>(Owner);
		BirdHazeAkComp = UHazeAkComponent::GetOrCreate(Bird);
		MoveComp = UHazeMovementComponent::Get(Bird);

		BirdHazeAkComp.SetTrackVelocity(true, GROUNDED_MAX_SPEED);		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		IdleEventInstance = BirdHazeAkComp.HazePostEvent(Idle);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		BirdHazeAkComp.HazeStopEventInstance(IdleEventInstance);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Bird.AnyPlayerIsUsingBird())
		{
			if(bWasMounted)
				OnBirdDismounted();

			return;
		}

		// Bird was mounted
		UObject RawPlayerOwner;
		ConsumeAttribute(n"AudioMountedBird", RawPlayerOwner);
		AHazePlayerCharacter PlayerOwner = Cast<AHazePlayerCharacter>(RawPlayerOwner);

		if(PlayerOwner != nullptr)
			OnBirdMounted(PlayerOwner);	

		// Flight Events

		if(ConsumeAction(n"AudioStartedFlying") == EActionStateStatus::Active)
			BirdHazeAkComp.HazePostEvent(VocalStartFlyingEvent);

		if(ConsumeAction(n"AudioStoppedFlying") == EActionStateStatus::Active)
			BirdHazeAkComp.HazePostEvent(VocalLandingEvent);

		if(ConsumeAction(n"AudioFlapWings") == EActionStateStatus::Active)
		{
			BirdHazeAkComp.HazePostEvent(FlapWingsEvent);
			//PrintScaled("FlapWings", 2.f, FLinearColor::Black, 2.f);
		}			

		if(ConsumeAction(n"AudioLaunchBird") == EActionStateStatus::Active)
		{
			BirdHazeAkComp.HazePostEvent(LaunchEvent);
			//PrintScaled("Launch", 2.f, FLinearColor::Black, 2.f);
		}

		if(ConsumeAction(n"AudioBirdDeath") == EActionStateStatus::Active)
		{
			BirdHazeAkComp.HazePostEvent(DeathEvent);
			//PrintScaled("Launch", 2.f, FLinearColor::Black, 2.f);
		}

		if(ConsumeAction(n"AudioBirdRespawn") == EActionStateStatus::Active)
		{
			BirdHazeAkComp.HazePostEvent(RespawnEvent);
			//PrintScaled("Launch", 2.f, FLinearColor::Black, 2.f);
		}	

		if(ConsumeAction(n"AudioEnteredForcefield") == EActionStateStatus::Active)
			OnEnterForcefield();

		if(ConsumeAction(n"AudioExitedForcefield") == EActionStateStatus::Active)
			OnExitForcefield();

		float BirdIsFlyingRtpcValue = Bird.bIsFlying ? 1.f : 0.f;
		if(BirdIsFlyingRtpcValue != LastBirdIsFlyingRtpc)
		{
			BirdHazeAkComp.SetRTPCValue("Rtpc_Vehicles_ClockBird_IsInAir", BirdIsFlyingRtpcValue);
			LastBirdIsFlyingRtpc = BirdIsFlyingRtpcValue;
		}

		bool bCurrentlyFlying = false;
		if(FlyingStateWasChanged(bCurrentlyFlying))
		{
			const float MaxSpeed = bCurrentlyFlying ? FLYING_MAX_SPEED : GROUNDED_MAX_SPEED;
			BirdHazeAkComp.SetTrackVelocity(true, MaxSpeed);
		}
	
		//(UGLY FIX BY PHILIP, The object velo rtpc stops updating when the bird is grounded)
		if(!Bird.bIsFlying)
			return;
		//(UGLY FIX BY PHILIP, The object velo rtpc stops updating when the bird is grounded)

		// Calculate and update bird flight audio parameters

		BirdLocation = Bird.Mesh.GetWorldLocation();
		BirdVeloVector = BirdLocation - LastBirdLocation;
		float Velo = BirdVeloVector.Size();			

		float NormalizedTilt = 0.f;
		float NormalizedRoll = 0.f;
		float NormalizedLeftWingVelo = 0.f;
		float NormalizedRightWingVelo = 0.f;

		// Ground velocity (UGLY FIX BY PHILIP, The object velo rtpc stops updating when the bird is grounded)
		//float GroundVelo = HazeAudio::NormalizeRTPC01(BirdVeloVector.Size(), 0.f, 100.f);
		//BirdHazeAkComp.SetRTPCValue("Rtpc_Vehicles_ClockBird_GroundVelocity", GroundVelo);
		//PrintToScreenScaled("GroundVelo: " + BirdVeloVector.Size(), 0.f);

		// Calculate and update bird flight audio parameters

		GetCurrentFlightRtpcValues(Velo, NormalizedTilt, NormalizedRoll, NormalizedLeftWingVelo, NormalizedRightWingVelo);		
			
		if(NormalizedTilt != LastTiltRtpcValue)
		{
			BirdHazeAkComp.SetRTPCValue("Rtpc_Vehicles_ClockBird_Tilt", NormalizedTilt);
			LastTiltRtpcValue = NormalizedTilt;

			//Print("Tilt: "+ NormalizedTilt);
		}

		if(NormalizedRoll != LastRollRtpcValue)
		{
			BirdHazeAkComp.SetRTPCValue("Rtpc_Vehicles_ClockBird_Roll", NormalizedRoll);
			LastRollRtpcValue = NormalizedRoll;

			//Print("Roll: "+ NormalizedRoll);
		}

		const float IsGlidingRtpcValue = IsActioning(ClockworkBirdTags::Aiming) ? 1.f : 0.f;

		if(IsGlidingRtpcValue != LastIsGlidingRtpcValue)
		{
			BirdHazeAkComp.SetRTPCValue("Rtpc_Vehicles_ClockBird_IsGliding", IsGlidingRtpcValue);
			LastIsGlidingRtpcValue = IsGlidingRtpcValue;

			//Print("IsGliding: "+ IsGlidingRtpcValue);
		}

		if(NormalizedLeftWingVelo != LastNormalizedLeftWingVelo)
		{
			BirdHazeAkComp.SetRTPCValue("Rtpc_Vehicles_ClockBird_WingMovement_Left", NormalizedLeftWingVelo);
			LastNormalizedLeftWingVelo = NormalizedLeftWingVelo;
		}

		if(NormalizedRightWingVelo != LastNormalizedRightWingVelo)
		{
			BirdHazeAkComp.SetRTPCValue("Rtpc_Vehicles_ClockBird_WingMovement_Right", NormalizedRightWingVelo);
			LastNormalizedRightWingVelo = NormalizedRightWingVelo;
		}
	
		LastBirdLocation = BirdLocation;
	}

	void GetCurrentFlightRtpcValues(const float& Velo, float& InTilt, float& InRoll, float& InLeftWingVelo, float& InRightWingVelo)
	{
		FVector VelocityPlaneForward = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();	

		float Tilt = Math::DotToDegrees(MoveComp.Velocity.GetSafeNormal().DotProduct(VelocityPlaneForward));
		Tilt = Tilt * FMath::Sign(MoveComp.Velocity.DotProduct(MoveComp.WorldUp));
		InTilt = HazeAudio::NormalizeRTPC(Tilt, -80.f, 80.f, -1.f, 1.f);
		
		float Roll = Bird.Mesh.RelativeRotation.Roll;
		InRoll = HazeAudio::NormalizeRTPC01(FMath::Abs(Roll), 0.f, 59.f);

		FVector RightWingPosition = Bird.Mesh.GetSocketLocation(n"RightHand");
		FVector LeftWingPosition = Bird.Mesh.GetSocketLocation(n"LeftHand");

		RightWingPosition.ConstrainToPlane(Bird.GetActorUpVector());
		LeftWingPosition.ConstrainToPlane(Bird.GetActorUpVector());	
		
		float RightWingVelo = FMath::Abs((RightWingPosition - LastRightWingPosition).Size() - Velo);
		float LeftWingVelo = FMath::Abs((LeftWingPosition - LastLeftWingPosition).Size() - Velo);		
	
		InLeftWingVelo = HazeAudio::NormalizeRTPC01(LeftWingVelo, 0.f, 15.f);
		InRightWingVelo = HazeAudio::NormalizeRTPC01(RightWingVelo, 0.f, 15.f);	

		LastRightWingPosition = RightWingPosition;
		LastLeftWingPosition = LeftWingPosition;		
	}

	void OnBirdMounted(AHazePlayerCharacter PlayerOwner)	
	{
		HazeAudio::SetPlayerPanning(BirdHazeAkComp, PlayerOwner);
		BirdHazeAkComp.HazePostEvent(Mount);	

		bWasMounted = true;
	}

	void OnBirdDismounted()
	{
		BirdHazeAkComp.HazePostEvent(Dismount);
		bWasMounted = false;
	}

	void OnEnterForcefield()
	{
		bInsideTimeSphere = true;
		TimeSphereTimer = 0.f;

		BirdHazeAkComp.HazePostEvent(OnEnterForcefieldEvent);
		BirdHazeAkComp.HazePostEvent(OnEnterForcefieldBirdEvent);
		BirdHazeAkComp.SetRTPCValue("Rtpc_Vehicles_ClockBird_InsideTimeBubble", 1.f);
		Bird.ActivePlayer.PlayerHazeAkComp.SetRTPCValue("Rtpc_Vehicles_ClockBird_InsideTimeBubble", 1.f);

	}
	
	void OnExitForcefield()
	{
		bInsideTimeSphere = false;
		BirdHazeAkComp.SetRTPCValue("Rtpc_Vehicles_ClockBird_InsideTimeBubble", 0.f);
		Bird.ActivePlayer.PlayerHazeAkComp.SetRTPCValue("Rtpc_Vehicles_ClockBird_InsideTimeBubble", 0.f);
		System::SetTimer(this, n"DelayedRespawn", 1.f, false);
	}

	UFUNCTION()
	void DelayedRespawn()
	{
		BirdHazeAkComp.HazePostEvent(OnExitForcefieldEvent);
	}

	bool FlyingStateWasChanged(bool& bStartedFlying)
	{
		if(bWasFlying != Bird.bIsFlying)
		{
			bWasFlying = Bird.bIsFlying;
			bStartedFlying = Bird.bIsFlying;
			return true;
		}

		return false;
	}
}