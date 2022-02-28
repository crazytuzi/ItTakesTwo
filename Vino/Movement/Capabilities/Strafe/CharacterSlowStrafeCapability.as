
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Movement.NoWallCollisionSolver;
import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Peanuts.Animation.Features.LocomotionFeatureLanding;
import Vino.Movement.Capabilities.Strafe.CharacterStrafeComponent;
import Peanuts.AutoMove.CharacterAutoMoveCapability;
import Vino.Camera.Capabilities.CameraTags;

class UCharacterSlowStrafeCapability : UCharacterMovementCapability
{
	default RespondToEvent(MovementActivationEvents::Grounded);

	UHazeCharacterSkeletalMeshComponent SkelMeshComp;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::BasicFloorMovement);
	default CapabilityTags.Add(MovementSystemTags::AudioMovementEfforts);
	default CapabilityTags.Add(CapabilityTags::CharacterFacing);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 100;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	AHazePlayerCharacter Player;
	UCharacterStrafeComponent StrafeComp;

	//Static value of how much we keep of the force
	const float ForceGroundFrictionValue = 0.14f;

	float CurrentForwardSpeed = 0.f;
	float SlowStrafeSpeed = 300.f;
	FHazeAcceleratedFloat FaceTargetSpeed;
	float InitialRotationTime = 0.f;
	FHazeAcceleratedRotator FacingRotation;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		SkelMeshComp = UHazeCharacterSkeletalMeshComponent::Get(Owner);

		Player = Cast<AHazePlayerCharacter>(Owner);
		StrafeComp = UCharacterStrafeComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if (!StrafeComp.bIsStrafing)
			return EHazeNetworkActivation::DontActivate;

		if (!ShouldBeGrounded())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		if (!StrafeComp.bIsStrafing)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		CurrentForwardSpeed = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).Size();
		SetMutuallyExclusive(CapabilityTags::CharacterFacing, true);

		Player.BlockCapabilities(CapabilityTags::MovementAction, this);

		FacingRotation.SnapTo(Owner.ActorRotation);

		// Hacks to deal with out of cutscene transition in music ending
		FaceTargetSpeed.SnapTo(0.f);
		InitialRotationTime = Time::RealTimeSeconds + 1.f;
		Player.BlockCapabilities(CameraTags::Control, this);	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!HasControl())
		{
			CrumbComp.SetCrumbDebugActive(this, false);
		}

		SetMutuallyExclusive(CapabilityTags::CharacterFacing, false);

		Player.UnblockCapabilities(CapabilityTags::MovementAction, this);
		if (InitialRotationTime != 0.f)
			Player.UnblockCapabilities(CameraTags::Control, this);			
	}

	void PlayLandingAnimation()
	{
		ULocomotionFeatureLanding LandingFeature = ULocomotionFeatureLanding::Get(CharacterOwner);
		if(LandingFeature != nullptr && LandingFeature.Landing.Sequence != nullptr)
		{
			FHazePlayAdditiveAnimationParams AddativeParams;
			AddativeParams.Animation = LandingFeature.Landing.Sequence;
			AddativeParams.PlayRate = LandingFeature.Landing.PlayRate;
			AddativeParams.BoneFilter = LandingFeature.BoneFilter;
			AddativeParams.BlendTime = LandingFeature.BlendTime;
			
			CharacterOwner.PlayAdditiveAnimation(FHazeAnimationDelegate(), AddativeParams);
		}
	}

	void MakeFrameMovementData(FHazeFrameMovement& FrameMoveData, float DeltaTime)
	{
		if(HasControl())
		{
			FVector Input = GetAttributeVector(AttributeVectorNames::MovementDirection);

			float TargetSpeed = 0.f;
			if (!Input.IsNearlyZero())
				TargetSpeed = SlowStrafeSpeed * Input.GetClampedToSize(0.4f, 1.f).Size();
			
			float AccelerationSpeed = SlowStrafeSpeed / 0.35f;
			CurrentForwardSpeed += AccelerationSpeed * DeltaTime;
			
			if (CurrentForwardSpeed > TargetSpeed)
				CurrentForwardSpeed = TargetSpeed;

			FVector InputMoveDelta = Input.GetSafeNormal() * CurrentForwardSpeed * DeltaTime;
			//FVector InputMoveDelta = Input.GetClampedToSize(0.4f, 1.f) * SlowStrafeSpeed * DeltaTime;
			FVector MoveDelta = InputMoveDelta;

			if (MoveComp.PreviousImpacts.DownImpact.bBlockingHit)
			{
				FVector WorldUp = MoveComp.WorldUp.GetSafeNormal();
				FVector Normal = MoveComp.DownHit.Normal.GetSafeNormal();				

				MoveDelta = Math::ConstrainVectorToSlope(Input, Normal, WorldUp).GetSafeNormal() * InputMoveDelta.Size();
			}
			
			//We only apply forces on the controlside and let the remote be affected through by it indirectly from syncing the position.
			FVector ForceVelocity = MoveComp.ConsumeAccumulatedImpulse();
			ForceVelocity = ScaleUpForce(ForceVelocity, DeltaTime);
		
			//We need to constrain the force to the horizontal plain since we allow small vertical forces through.
			ForceVelocity = Math::ConstrainVectorToPlane(ForceVelocity, MoveComp.WorldUp);
			MoveDelta += (ForceVelocity * DeltaTime);


			FrameMoveData.ApplyDelta(MoveDelta);
			FrameMoveData.ApplyTargetRotationDelta();
			FrameMoveData.FlagToMoveWithDownImpact();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMoveData.ApplyConsumedCrumbData(ConsumedParams);
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector Input = Player.GetActorRotation().UnrotateVector(GetAttributeVector(AttributeVectorNames::MovementDirection));
		Input *= 400.0f;

		Player.SetAnimFloatParam(n"SlowStrafeX", Input.Y);
		Player.SetAnimFloatParam(n"SlowStrafeY", Input.X);

		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"FloorMove");
		MoveComp.SetAnimationToBeRequested(n"SlowStrafe");

		if(HasControl())
		{	
			FHazeLocomotionTransform RootMotion;
			SkelMeshComp.ConsumeLastExtractedRootMotion(RootMotion);
			MoveData.ApplyRootMotion(RootMotion, bApplyRotation = false, bRedirectWithGround = false);
			MoveData.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			MoveData.ApplyConsumedCrumbData(ConsumedParams);
		}

		if (StrafeComp.CurrentSpline != nullptr && Player.IsAnyCapabilityActive(UCharacterAutoMoveCapability::StaticClass()))
		{
			float ClosestDistanceToPlayer = StrafeComp.CurrentSpline.GetDistanceAlongSplineAtWorldLocation(Player.ActorLocation);
			FRotator CurSplineRotation = StrafeComp.CurrentSpline.GetRotationAtDistanceAlongSpline(ClosestDistanceToPlayer, ESplineCoordinateSpace::World);
			MoveComp.SetTargetFacingRotation(FQuat(CurSplineRotation));
			FacingRotation.SnapTo(CurSplineRotation);
		}
		else if (Time::RealTimeSeconds > InitialRotationTime)
		{
			if (InitialRotationTime != 0.f)
			{
				Player.UnblockCapabilities(CameraTags::Control, this);			
				InitialRotationTime = 0.f;
			}

			// No rotation at start until view starts moving (i.e. we get move or camera input)
			if (Player.ViewVelocity.SizeSquared() > 1.f)
				FaceTargetSpeed.AccelerateTo(100.f, 2.f, DeltaTime);
			if (FaceTargetSpeed.Value > 0.f)
			{
				FRotator Rotation = Player.ViewRotation;
				Rotation.Pitch = 0.f;
				Rotation.Roll = 0.f;
				if (FaceTargetSpeed.Value < 99.f)
					Rotation = FQuat::Slerp(Player.ActorQuat, FQuat(Rotation), FMath::Min(1.f, FaceTargetSpeed.Value * DeltaTime)).Rotator();

				FacingRotation.AccelerateTo(Rotation, 0.3f, DeltaTime);	
				MoveComp.SetTargetFacingRotation(FacingRotation.Value);
			}
		}
		
		MoveComp.Move(MoveData);
		MoveComp.Velocity = MoveData.Velocity;
		CrumbComp.LeaveMovementCrumb();

		FHazeRequestLocomotionData AnimationRequest;
 		AnimationRequest.AnimationTag = n"SlowStrafe";
		CharacterOwner.RequestLocomotion(AnimationRequest);
	}

	void UpdateBlendSpaceValues()
	{
		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw) * 100.f;
		Player.SetBlendSpaceValues(Input.Y, Input.X);
	}

	FVector ScaleUpForce(FVector InputForce, float DeltaTime) const
	{
		//We allow forces set this frame to affect this frames delta movement, we scale the force up since we only apply it for one frame.
		//Note: Since floor movement doesn't use the characters velocity the forces will only have an effect for one frame.
		FVector OutputForce = InputForce;

		OutputForce = InputForce / DeltaTime;
			
		//We apply friction to the force so the same force in the air will have greater effect.
		OutputForce = OutputForce * ForceGroundFrictionValue;

		return OutputForce;
	}


	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{	
		FString Str = "";
		Str += "Velocity: <Yellow>" + MoveComp.Velocity.Size() + "</> (" + MoveComp.Velocity.ToString() + ")\n";
		
		return Str;
	} 
};

UFUNCTION()
void ActivateSlowStrafe(AHazePlayerCharacter Player)
{
	if (Player == nullptr)
		return;
	
	UCharacterStrafeComponent StrafeComp = UCharacterStrafeComponent::Get(Player);
	if (StrafeComp == nullptr)
		return;

	StrafeComp.bIsStrafing = true;
}

UFUNCTION()
void DeactivateSlowStrafe(AHazePlayerCharacter Player)
{
	if (Player == nullptr)
		return;
	
	UCharacterStrafeComponent StrafeComp = UCharacterStrafeComponent::Get(Player);
	if (StrafeComp == nullptr)
		return;

	StrafeComp.bIsStrafing = false;
}
