import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideComponent;
import Vino.Movement.Capabilities.WallSlide.CharacterWallSlideSettings;
import Vino.Movement.Capabilities.WallSlide.WallSlideNames;
import Vino.Movement.Jump.CharacterJumpBufferComponent;

class UCharacterWallSlideCapability : UCharacterMovementCapability
{
	default RespondToEvent(WallslideActivationEvents::Wallsliding);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::WallSlide);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(WallSlideTags::WallSliding);

	default CapabilityDebugCategory = CapabilityTags::Movement;

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 35;

	default SeperateInactiveTick(ECapabilityTickGroups::ReactionMovement, 50);

	UCharacterWallSlideComponent WallDataComp;
	UCharacterJumpBufferComponent JumpBuffer;
	FCharacterWallSlideSettings Settings;

	float CurrentSpeed = 0.f;
	AHazePlayerCharacter PlayerOwner = nullptr;

	bool bWantsArmOut = false;
	float ArmUpdateTime = 0.f;

	float WallSlideFastDistance = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams Params)
	{
		Super::Setup(Params);

		WallDataComp = UCharacterWallSlideComponent::GetOrCreate(Owner);
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		JumpBuffer = UCharacterJumpBufferComponent::GetOrCreate(Owner);
		ensure(PlayerOwner != nullptr);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!WallDataComp.ShouldSlide())
			return EHazeNetworkActivation::DontActivate;

		if (MoveComp.IsMovingUpwards(WallDataComp.DynamicSettings.MaxUpwardsSpeedToStart))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return RemoteLocalControlCrumbDeactivation();

		if (!WallDataComp.IsSliding())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		if (WallDataComp.PrimitiveWeWantToSlideOn.IsNetworked())
			OutParams.AddObject(WallSlideSyncing::Primitive, WallDataComp.PrimitiveWeWantToSlideOn);

		OutParams.AddVector(WallSlideSyncing::WallNormal, WallDataComp.WorldOrRelativeNormal);

		float FastSlideDistance = 0.f;
		if (WallDataComp.JumpOffData.IsValid())
		{
			FVector CurrentToJumpOff = WallDataComp.JumpOffData.JumpOffLocation - MoveComp.OwnerLocation;
			float Dot = CurrentToJumpOff.GetSafeNormal().DotProduct(WallDataComp.JumpOffData.WallNormal);
			float NormalDot = WallDataComp.TargetWallNormal.DotProduct(WallDataComp.JumpOffData.WallNormal);
			if (Dot > -0.15f || NormalDot > -0.9f)
			{
				if ((-CurrentToJumpOff).DotProduct(MoveComp.WorldUp) > 0.f)
					FastSlideDistance = CurrentToJumpOff.ConstrainToDirection(MoveComp.WorldUp).Size();
			}
		}

		OutParams.AddValue(WallSlideSyncing::FastSlideDistance, FastSlideDistance);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		bWantsArmOut = false;
		UPrimitiveComponent Primitive = Cast<UPrimitiveComponent>(Params.GetObject(WallSlideSyncing::Primitive));
		FVector Normal = Params.GetVector(WallSlideSyncing::WallNormal);

		WallDataComp.StartSliding(Primitive, Normal, WallDataComp.TargetWallHit);		

		Owner.BlockCapabilities(MovementSystemTags::SkyDive, this);
		Owner.BlockCapabilities(CapabilityTags::CharacterFacing, this);
		Owner.BlockCapabilities(ActionNames::WeaponAim, this);

		MoveComp.SetTargetFacingDirection(WallDataComp.NormalPointingAwayFromWall);
		UpdateCharacterMeshRotation(true);

		WallSlideFastDistance = Params.GetValue(WallSlideSyncing::FastSlideDistance);
		if (WallSlideFastDistance > 0.f)
			EnterFastWallSlide(WallSlideFastDistance);

		CurrentSpeed = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		Owner.UnblockCapabilities(MovementSystemTags::SkyDive, this);
		Owner.UnblockCapabilities(CapabilityTags::CharacterFacing, this);
		Owner.UnblockCapabilities(ActionNames::WeaponAim, this);

		PlayerOwner.RootOffsetComponent.ResetRotationWithSpeed();

		if (WallSlideFastDistance > 0.f)
			ExitFastSlide();
	}

	UFUNCTION(BlueprintOverride)
	void NotificationReceived(FName Notification, FCapabilityNotificationReceiveParams Params)
	{
		if (Notification == n"WallSlideArmUpdate")
			bWantsArmOut = Params.GetActionState(n"ArmOut") == EHazeActionState::Active;
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement WallSlideMove = MoveComp.MakeFrameMovement(MovementSystemTags::WallSlide);

		if (HasControl())
		{			
			if (WallSlideFastDistance > 0.f)
			{
				if (WasActionStarted(ActionNames::MovementJump))
					JumpBuffer.RegisterJump();

				FVector JumpOffToCurrent = MoveComp.OwnerLocation - WallDataComp.JumpOffData.JumpOffLocation;
				if (JumpOffToCurrent.DotProduct(MoveComp.WorldUp) > 0.f)
					WallSlideFastDistance = JumpOffToCurrent.ConstrainToDirection(MoveComp.WorldUp).Size();
				else
					ExitFastSlide();
			}
			else
			{
				WallDataComp.bReadyToDash = GetAttributeVector(AttributeVectorNames::MovementDirection).DotProduct(WallDataComp.NormalPointingAwayFromWall) >= 0.f;
				if (bWantsArmOut != WallDataComp.bReadyToDash && CanSyncArm())
				{
					FCapabilityNotificationSendParams Params;
					Params.AddActionState(n"ArmOut", WallDataComp.bReadyToDash ? EHazeActionState::Active : EHazeActionState::Inactive);
					TriggerNotification(n"WallSlideArmUpdate", Params);

					ArmUpdateTime = System::GetGameTimeInSeconds();
				}
			}

			MakeControlMovement(WallSlideMove, DeltaTime);
		}
		else
		{
			WallDataComp.bReadyToDash = bWantsArmOut;
			PrintToScreen("ArmOut: " + WallDataComp.bReadyToDash);
			MakeRemoteMovement(WallSlideMove, DeltaTime);
		}

		UpdateCharacterMeshRotation(false);

		MoveCharacter(WallSlideMove, FeatureName::WallMovement);
		CrumbComp.LeaveMovementCrumb();
	}

	bool CanSyncArm() const
	{
		float TimeDif = System::GetGameTimeInSeconds() - ArmUpdateTime;
		return (TimeDif > 0.5f);
	}

	void MakeControlMovement(FHazeFrameMovement& OutMovement, float DeltaTime)
	{
		float WallslideSpeed = WallDataComp.DynamicSettings.WallSlideSpeed;
		float InterpSpeed = WallDataComp.DynamicSettings.WallSlideInterpSpeed;
		if (WallSlideFastDistance > 0.f)
		{
			WallslideSpeed = WallDataComp.DynamicSettings.FastWallSlideSpeed;
			InterpSpeed = WallDataComp.DynamicSettings.WallSlideFastInterpSpeed;
		}

		const float TargetSpeed = -WallslideSpeed;
		CurrentSpeed = FMath::FInterpTo(CurrentSpeed, TargetSpeed, DeltaTime, InterpSpeed);
				
		FVector DeltaVector = MoveComp.WorldUp * CurrentSpeed * DeltaTime;
		OutMovement.ApplyDelta(DeltaVector);
		OutMovement.OverrideStepDownHeight(0.f);
		OutMovement.OverrideStepUpHeight(0.f);
		OutMovement.ApplyTargetRotationDelta();
		OutMovement.OverrideContactHit(WallDataComp.ActiveWallHit.FHitResult);
		if (WallDataComp.PrimitiveSlidingOn != nullptr)
			OutMovement.SetMoveWithComponent(WallDataComp.PrimitiveSlidingOn);
	}

	void MakeRemoteMovement(FHazeFrameMovement& OutMovement, float DeltaTime)
	{
		FHazeActorReplicationFinalized ConsumedParams;
		CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
		OutMovement.ApplyConsumedCrumbData(ConsumedParams);
		
		FHazeHitResult SurfaceHit;
		RemoteContactSurfaceTrace(SurfaceHit);

		if (SurfaceHit.bBlockingHit)
			OutMovement.OverrideContactHit(SurfaceHit.FHitResult);
	}

	void UpdateCharacterMeshRotation(bool bForceRotationToNormal)
	{
		if (WallDataComp.PrimitiveSlidingOn == nullptr && !bForceRotationToNormal)
			return;

		const FVector WorldWallNormal = WallDataComp.NormalPointingAwayFromWall;

		FVector TiltedUp = MoveComp.WorldUp.ConstrainToPlane(WorldWallNormal).GetSafeNormal();
		FRotator OffsetRotation = Math::ConstructRotatorFromUpAndForwardVector(-WorldWallNormal, TiltedUp);

		MoveComp.SetTargetFacingDirection(-WorldWallNormal);
		PlayerOwner.RootOffsetComponent.OffsetRotationWithSpeed(OffsetRotation, Settings.RotationTime);
	}

	void EnterFastWallSlide(float Distance)
	{
		if (HasControl())
			Owner.BlockCapabilities(MovementSystemTags::WallSlideJump, this);

		WallSlideFastDistance = Distance;
		CharacterOwner.SetAnimFloatParam(WallSlideAnimParams::FastSlideDistance, Distance);
	}

	void ExitFastSlide()
	{
		WallSlideFastDistance = 0.f;
		CurrentSpeed = -WallDataComp.DynamicSettings.WallSlideSpeed;

		if (HasControl())
			Owner.UnblockCapabilities(MovementSystemTags::WallSlideJump, this);
	}

	void RemoteContactSurfaceTrace(FHazeHitResult& OutHit)
	{
		// On the remote we manually recheck the contact surface here.
		ensure(!HasControl());
		
		FHazeTraceParams SurfaceCheck;
		SurfaceCheck.InitWithMovementComponent(MoveComp);
		SurfaceCheck.From = MoveComp.OwnerLocation;
		SurfaceCheck.To = SurfaceCheck.From - WallDataComp.NormalPointingAwayFromWall * 100.f;
		
		if (!SurfaceCheck.Trace(OutHit) && WallDataComp.PrimitiveSlidingOn != nullptr)
		{
			SurfaceCheck.To = WallDataComp.PrimitiveSlidingOn.WorldLocation;
			SurfaceCheck.Trace(OutHit);
		}
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		return "FastMode: " + (WallSlideFastDistance > 0.f ? "True" : "False");
	}
}
