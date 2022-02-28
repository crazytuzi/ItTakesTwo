import Vino.Movement.Components.MovementComponent;

import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Animation.Features.LocomotionFeatureWallRun;
import Vino.Movement.MovementSystemTags;

class UCharacterWallRunCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::WallRun);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	
	default TickGroup = ECapabilityTickGroups::ReactionMovement;
	default TickGroupOrder = 1;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	FVector WallNormal = FVector::ZeroVector;

	float AccelerationDuration = 0.3f;
	float Duration = 0.95f;
	float Time;
	float Speed = 1200.f;
	float SpeedMultiplier;
	float Cooldown = .05f;
	float CooldownTime;
	bool bJumpRegistered = false;
	float StartSpeed;
	float InactiveTime;
	bool bInFrontOfWall = false;
	bool bShouldWallRun = false;
	bool bInChainedWallRuns = false;

	AHazePlayerCharacter Player;
	ULocomotionFeatureWallRun Feature;
	FHazeAnimationDelegate EnterDone;	

    UPrimitiveComponent WallRunningOn = nullptr;
    FVector RelativeWallNormal = FVector::ZeroVector;
	FVector WallRight = FVector::ZeroVector;
	FVector InputVector = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (CooldownTime < Cooldown)
			return EHazeNetworkActivation::DontActivate;

        if (bShouldWallRun && (IsActioning(ActionNames::MovementJump) || bInChainedWallRuns))
            return EHazeNetworkActivation::ActivateLocal;		

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Time >= Duration)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if (ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!bInFrontOfWall)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bInFrontOfWall = true;
		Time = 0.f;
		WallRight = WallNormal.CrossProduct(MoveComp.WorldUp);
		InputVector = GetAttributeVector(AttributeVectorNames::MovementDirection).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();

		if (InputVector.Size() != 0.f)
		{			
			if (WallRight.DotProduct(InputVector) > 0)
			{
				SpeedMultiplier = 1.f;
			}
			else
			{
				SpeedMultiplier = -1.f;
			}
		}
		else
		{
			if (WallRight.DotProduct(MoveComp.PreviousVelocity.GetSafeNormal()) > 0.f)
			{
				SpeedMultiplier = 1.f;
				// Print("No input used to pick direction", 5.f);
			}
			else
			{
				SpeedMultiplier = -1.f;
				// Print("No input used to pick direction", 5.f);

			}
		}

		bJumpRegistered = false;
		bInChainedWallRuns = true;

		Feature = ULocomotionFeatureWallRun::Get(Player);
		EnterDone.BindUFunction(this, n"PlayMH");
		Player.PlaySlotAnimation(OnBlendingOut = EnterDone, Animation = SpeedMultiplier < 0 ? Feature.RightWallRunStart.Sequence : Feature.LeftWallRunStart.Sequence, BlendTime = 0.1f, bLoop = false);
		WallNormal *= SpeedMultiplier;
		// Player.BlockCapabilities(CapabilityTags::MovementInput, this);
		Player.BlockCapabilities(MovementSystemTags::WallSlide, this);
		StartSpeed = Math::ConstrainVectorToPlane(MoveComp.PreviousVelocity, MoveComp.WorldUp).Size();

		
		// Print(""+StartSpeed, 5.f);

	}

	UFUNCTION()
	void PlayMH()
	{
		if (IsActive())
			Player.PlaySlotAnimation(Animation = SpeedMultiplier < 0 ? Feature.RightWallRunMH.Sequence : Feature.LeftWallRunMH.Sequence, BlendTime = 0.1f, bLoop = false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		CooldownTime = 0.f;
		if (bJumpRegistered)
		{
			if (SpeedMultiplier > 0)
			{
				Player.SetCapabilityActionState(n"WallRunJumpRight", EHazeActionState::Active);
				bJumpRegistered = false;
			}
			else
			{
				Player.SetCapabilityActionState(n"WallRunJumpLeft", EHazeActionState::Active);
				bJumpRegistered = false;
			}
		}

		Player.StopAllSlotAnimations();
		EnterDone.Clear();
		// Player.ClearPointOfInterestByInstigator(this);
		// Player.UnblockCapabilities(CapabilityTags::MovementInput, this);
		Player.UnblockCapabilities(MovementSystemTags::WallSlide, this);
		InactiveTime = 0.f;
	}

    bool CheckShouldWallRun()
    {
		FHitResult WallHit = MoveComp.PreviousImpacts.ForwardImpact;
		if (WallHit.Component == nullptr)
			return false;

		InputVector = GetAttributeVector(AttributeVectorNames::MovementDirection).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		WallRunningOn = nullptr;

		if (WallHit.Component != nullptr)
		{
			if (!WallHit.Component.HasTag(ComponentTags::WallRunnable))
				return false;
		}

		if(ShouldBeGrounded())
		 	return false;


		if (MoveComp.IsMovingUpwards(1000.f))
			return false;

		const float WallAngle = WallHit.Normal.DotProduct(MoveComp.WorldUp);
		if (WallAngle > 0.1f)
			return false;


		if (WallHit.Actor != nullptr)
		{
			if (!InputVector.IsNearlyZero())
			{
				if (WallHit.Normal.DotProduct(InputVector) > -0.85f)
				{
					WallNormal = WallHit.Normal;
					WallRunningOn = WallHit.Component;
					return true;
				}
			}	
			else
			{
				if (WallHit.Normal.DotProduct(MoveComp.PreviousVelocity.GetSafeNormal()) > -0.55f)
				{
					WallNormal = WallHit.Normal;
					WallRunningOn = WallHit.Component;
					return true;
				}
			}
		}

		return false;
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		Time += DeltaTime;
		float UpVel = FMath::GetMappedRangeValueClamped(FVector2D(0.f, Duration), FVector2D(800, -MoveComp.MaxFallSpeed), Time);
		float HorizontalVel = FMath::GetMappedRangeValueClamped(FVector2D(0.f, AccelerationDuration), FVector2D(StartSpeed, Speed), Time);
		UpVel *= DeltaTime;

		FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);

		if(IsDebugActive())
			Print("" + Input, 0.f);

		HorizontalVel *= DeltaTime;
		
		// Print(""+HorizontalVel, 0.f);
		FVector TargetDirection = WallNormal.CrossProduct(MoveComp.WorldUp);
		MoveComp.SetTargetFacingDirection(TargetDirection, 0.f);

		FVector Velocity = (WallRight * (HorizontalVel * SpeedMultiplier)) + FVector(0.f, 0.f, UpVel);
		FVector DeltaMove = Velocity;
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"WallRun");
        MoveData.ApplyDelta(DeltaMove);
		MoveData.ApplyTargetRotationDelta();
		MoveData.OverrideStepUpHeight(0.f);
		MoveData.OverrideStepDownHeight(0.f);
		MoveData.SetMoveWithComponent(WallRunningOn);
        MoveCharacter(MoveData, n"Movement");

		if (WasActionStarted(ActionNames::MovementJump))
		{
			Time = Duration;
			bJumpRegistered = true;
		}

		if (!WasAttributeVectorChangedDuringTime(AttributeVectorNames::RightStickRaw, 1.f))
        {
            FHazePointOfInterest Poi;
            Poi.FocusTarget.Type = EHazeFocusTargetType::WorldOffsetOnly;
            Poi.FocusTarget.WorldOffset = (Player.ActorLocation + (WallRight * 750.f) * SpeedMultiplier);
            Player.ApplyPointOfInterest(Poi, this);
        }
        else
        {
            Player.ClearPointOfInterestByInstigator(this);
        }

		FTransform WallHitRotationTransform = Math::ConstructTransformWithCustomRotation(MoveComp.OwnerLocation, -WallNormal * SpeedMultiplier, MoveComp.WorldUp);
		if (!IsFrontSolid(WallHitRotationTransform))
			bInFrontOfWall = false;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		FVector CurrentInput = GetAttributeVector(AttributeVectorNames::MovementDirection).ConstrainToPlane(MoveComp.WorldUp).GetSafeNormal();
		FHitResult WallHit = MoveComp.PreviousImpacts.ForwardImpact;
		if (WallHit.Actor != nullptr)
		{
			// Print("Hitting wall", 0.f);
			// Print(""+WallHit.Normal.DotProduct(MoveComp.Velocity.GetSafeNormal()), 0.f);
		}

		InactiveTime += DeltaTime;
		CooldownTime += DeltaTime;

		if (InactiveTime > 1.5f || !WasAttributeVectorChangedDuringTime(AttributeVectorNames::RightStickRaw, 1.f))
		{
			Player.ClearPointOfInterestByInstigator(this);
		}

		bShouldWallRun = CheckShouldWallRun();

		if (MoveComp.IsGrounded())
		{
			bInChainedWallRuns = false;
		}
	}


	bool IsFrontSolid(const FTransform& RotateToNormalTransform) const
	{
		float NumberOfSegments = 4;
		float StartHeight = MoveComp.ActorShapeExtents.Z * 1.55f;
		float EndHeight = MoveComp.ActorShapeExtents.Z * 0.25f;
		float SegmentDelta = (EndHeight - StartHeight) / NumberOfSegments;
		int FailedChecks = 0;

		const float CenterOfCapsuleDistanceCheck = 16.f;

		for (float ICenterSegment = 0; ICenterSegment < NumberOfSegments; ICenterSegment++)
		{			
			FVector HighLocalTraceStart(MoveComp.ActorShapeExtents.X * 0.9f, 0.f, StartHeight + (SegmentDelta * ICenterSegment));
			if (!TraceCheckWall(HighLocalTraceStart, RotateToNormalTransform, CenterOfCapsuleDistanceCheck))
				FailedChecks++;
		}

		const float WidthOffset = 12.f;
		const float SideDistanceCheck = 84.f;
		{
			//Left Check
			FVector LeftLocalHipTraceStart(-10.f, MoveComp.ActorShapeExtents.Y + WidthOffset, MoveComp.ActorShapeExtents.Z);
			if (!TraceCheckWall(LeftLocalHipTraceStart, RotateToNormalTransform, SideDistanceCheck))
				FailedChecks++;
		}

		{
			//Right Check
			FVector RightLocalHipTraceStart(-10.f, -MoveComp.ActorShapeExtents.Y - WidthOffset, MoveComp.ActorShapeExtents.Z);
			if (!TraceCheckWall(RightLocalHipTraceStart, RotateToNormalTransform, SideDistanceCheck))			
				FailedChecks++;
		}

		if (FailedChecks > 4)
			return false;

		return true;
	}

	bool TraceCheckWall(const FVector& LocalPosition, const FTransform& RotateToNormalTransform, const float LengthToTrace) const
	{
		const FVector LineStart = RotateToNormalTransform.TransformPosition(LocalPosition);
		const FVector LineEnd = LineStart + RotateToNormalTransform.GetRotation().Vector() * LengthToTrace;

		const float DebugDrawTime = 0.f;

		FHazeHitResult Hit;
		if (MoveComp.LineTrace(LineStart, LineEnd, Hit))
		{
			// if (IsDebugActive())
			// 	System::DrawDebugArrow(LineStart, LineEnd, LineColor = FLinearColor::Green, Duration = DebugDrawTime);

			return true;
		}
		else
		{
			// if (IsDebugActive())
			// 	System::DrawDebugArrow(LineStart, LineEnd, LineColor = FLinearColor::Red, Duration = DebugDrawTime);
		}

		return false;

	}

}
