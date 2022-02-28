
// import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetHeavyComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
// import Vino.Pickups.PlayerPickupComponent;
// import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;

// UCLASS(Abstract)
// class UPlayerMagnetSlideCapability : UCharacterMovementCapability
// {
// 	default CapabilityTags.Add(n"LevelSpecific");
// 	default CapabilityDebugCategory = n"LevelSpecific";
	
// 	default CapabilityTags.Add(n"MagnetSlide");

// 	default TickGroup = ECapabilityTickGroups::BeforeMovement;
// 	default TickGroupOrder = 2;

// 	UPROPERTY()
// 	UAnimSequence MaySlideAnim;
// 	UPROPERTY()
// 	UAnimSequence CodySlideAnim;

// 	AHazePlayerCharacter Player;
// 	UHazePlayerPointActivationComponent FindMagnetComponent;
// 	UMagneticPlayerComponent PlayerMagnetComp;
	
// 	//bool bFinishedHeavy = false;

// 	float Timer = 0.0f;

// 	UMagnetHeavyComponent HeavyComp;

// 	UPROPERTY()
// 	TSubclassOf<UCameraShakeBase> CamShake;

// 	UPROPERTY()
// 	UForceFeedbackEffect SlideRumble;


// 	UFUNCTION(BlueprintOverride)
// 	void Setup(FCapabilitySetupParams SetupParams)
// 	{
// 		Super::Setup(SetupParams);
// 		Player = Cast<AHazePlayerCharacter>(Owner);
// 		FindMagnetComponent = UHazePlayerPointActivationComponent::Get(Player);
// 		PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);
// 	}

// 	UFUNCTION()
// 	bool IfPlayerIsCarryingPickup() const
// 	{
// 		// if(MagnetComp.UsedComp.Owner != Player.OtherPlayer)
// 		// 	return false;
		
// 		UPlayerPickupComponent PickupComp = UPlayerPickupComponent::Get(Player.OtherPlayer);

// 		if(PickupComp.IsHoldingObject())
// 			return true;
// 		else
// 			return false;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkActivation ShouldActivate() const
// 	{
// 		// if (!Player.IsAnyCapabilityActive(n"MagneticControl"))
// 		// 	return EHazeNetworkActivation::DontActivate;

// 		// if(Player.IsAnyCapabilityActive(n"MagneticBoost"))
// 		// 	return EHazeNetworkActivation::DontActivate;

// 		// if(Player.IsAnyCapabilityActive(n"MagnetLaunch"))
// 		// 	return EHazeNetworkActivation::DontActivate;

// 		// if(Player.IsAnyCapabilityActive(n"MagnetPerch"))
// 		// 	return EHazeNetworkActivation::DontActivate;
// 		if(FindMagnetComponent.GetActivePoint() != nullptr)
// 			return EHazeNetworkActivation::DontActivate;

// 		UMagneticPlayerComponent PlayerTargetPoint = Cast<UMagneticPlayerComponent>(FindMagnetComponent.GetTargetPoint(FMagneticTags::Magnetic));
// 		if(PlayerTargetPoint == nullptr)
// 			return EHazeNetworkActivation::DontActivate;

// 		if(PlayerTargetPoint.Owner.GetComponentByClass(UMagnetHeavyComponent::StaticClass()) == nullptr)
// 			return EHazeNetworkActivation::DontActivate;

// 		if(!PlayerTargetPoint.IsInfluencedBy(Player))
// 			return EHazeNetworkActivation::DontActivate;

// 		if(PlayerMagnetComp.HasEqualPolarity(PlayerTargetPoint))
// 		 	return EHazeNetworkActivation::DontActivate;
			
//         return EHazeNetworkActivation::ActivateFromControl;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	EHazeNetworkDeactivation ShouldDeactivate() const
// 	{
// 		if(!FindMagnetComponent.CurrentActivationInstigatorIs(this))
// 			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

// 		UMagneticComponent CurrentTargetedMagnet = Cast<UMagneticComponent>(FindMagnetComponent.GetActivePoint());
// 		if(!CurrentTargetedMagnet.IsInfluencedBy(Player))
// 			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

// 		if(PlayerMagnetComp.HasEqualPolarity(CurrentTargetedMagnet))
// 		 	return EHazeNetworkDeactivation::DeactivateUsingCrumb;

// 		// if (!Player.IsAnyCapabilityActive(n"MagneticControl"))
// 		// 	return EHazeNetworkDeactivation::DeactivateFromControl;
			
// 		// if(Player.IsAnyCapabilityActive(n"MagneticBoost"))
// 		// 	return EHazeNetworkDeactivation::DeactivateFromControl;

// 		// if(Player.IsAnyCapabilityActive(n"MagnetLaunch"))
// 		// 	return EHazeNetworkDeactivation::DeactivateFromControl;

// 		// if(Player.IsAnyCapabilityActive(n"MagnetPerch"))
// 		// 	return EHazeNetworkDeactivation::DeactivateFromControl;

// 		// if(Cast<UMagneticComponent>(MagnetComp.UsedComp) == nullptr)
// 		// 	return EHazeNetworkDeactivation::DeactivateFromControl;			
		
// 		return EHazeNetworkDeactivation::DontDeactivate;
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
// 	{
// 		UMagneticComponent CurrentTargetedMagnet = Cast<UMagneticComponent>(FindMagnetComponent.GetTargetPoint(FMagneticTags::Magnetic));
// 		ActivationParams.AddObject(n"CurrentMagnet", CurrentTargetedMagnet);
// 	}


// 	UFUNCTION(BlueprintOverride)
// 	void OnActivated(FCapabilityActivationParams ActivationParams)
// 	{
// 		UMagneticComponent ActivatedMagnet = Cast<UMagneticComponent>(ActivationParams.GetObject(n"CurrentMagnet"));
// 		FindMagnetComponent.ActivatePoint(ActivatedMagnet, this);

// 		HeavyComp = Cast<UMagnetHeavyComponent>(ActivatedMagnet.Owner.GetComponentByClass(UMagnetHeavyComponent::StaticClass()));
// 		if(HeavyComp.bPlayFeedback)
// 		{
// 			Player.PlayForceFeedback(SlideRumble, false, true, n"MagnetSlide");
// 			Player.PlayCameraShake(CamShake, 3.f);
// 		}
// 	}

// 	UFUNCTION(BlueprintOverride)
// 	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
// 	{		
// 		UMovementSettings::ClearMoveSpeed(Player, this);
// 		Timer = 0.0f;
// 		Player.StopAllSlotAnimations();
// 		//bFinishedHeavy = false;
// 		HeavyComp = nullptr;

// 		Player.StopAllInstancesOfCameraShake(CamShake, false);
// 		Player.StopForceFeedback(SlideRumble, n"MagnetSlide");
// 	}

// 	void PlaySlideAnimation()
// 	{
// 		UAnimSequence SlideAnimation = Player.IsCody() ? CodySlideAnim : MaySlideAnim;
// 		if(!Player.IsPlayingAnimAsSlotAnimation(SlideAnimation))
// 		{
// 			FHazeAnimationDelegate OnEnterFinished;
// 			Player.PlaySlotAnimation(OnBlendingOut = OnEnterFinished, Animation = SlideAnimation);
// 		}
// 	}


// 	UFUNCTION(BlueprintOverride)
// 	void TickActive(float DeltaTime)
// 	{	
// 		float Force;

// 		if(MoveComp.IsGrounded())
// 			Force = HeavyComp.SlideForce;
// 		else
// 			Force = (HeavyComp.SlideForce/2);

// 		FTransform MagnetTransform = FindMagnetComponent.GetActivePoint().GetTransformFor(Player);

// 		FVector Direction = MagnetTransform.Location - Player.ActorLocation;
// 		Direction.Normalize();


// 		if(MoveComp.IsGrounded() && !IsMoving())
// 		{
// 			PlaySlideAnimation();
// 		}
// 		else
// 		{			
// 			if(Player.IsPlayingAnimAsSlotAnimation(CodySlideAnim) || Player.IsPlayingAnimAsSlotAnimation(MaySlideAnim))
// 			{
// 				Player.StopAllSlotAnimations();
// 			}
// 		}

// 		Player.AddImpulse(Direction * DeltaTime * Force);

// 		// FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"MagnetSlide");
// 		// // MoveData.OverrideStepDownHeight(0.f);
// 		// // MoveData.OverrideStepUpHeight(0.f);

// 		// MoveData.ApplyDelta(Direction * SlideForce * DeltaTime * (1 - Timer/ForceDuration));

// 		// MoveComp.SetTargetFacingDirection(Direction);
// 		// MoveData.ApplyTargetRotationDelta();
// 		// MoveCharacter(MoveData, n"MagnetSlide");

// 		Player.SetFrameForceFeedback(0.025f, 0.025f, 0.025f, 0.025f);
		

// 		// Timer += DeltaTime;
// 		// if(Timer >= HeavyComp.HeavyForceDuration)
// 		// 	FinishHeavySliding();
// 	}
	
// 	// UFUNCTION()
// 	// void FinishHeavySliding()
// 	// {
// 	// 	bFinishedHeavy = true;
// 	// 	//UMovementSettings::ClearMoveSpeed(Player, this);
// 	// 	//Player.StopAllSlotAnimations();
// 	// }

// 	bool IsMoving()
// 	{
// 		const FVector2D AxisInput = GetAttributeVector2D(AttributeVectorNames::MovementDirection);
// 		return !AxisInput.IsNearlyZero(0.01f);
// 		//return Player.GetActualVelocity().SizeSquared2D() > 0.001f;
// 	}

// }