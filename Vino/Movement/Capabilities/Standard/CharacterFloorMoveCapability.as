
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Peanuts.Movement.NoWallCollisionSolver;
import Peanuts.Movement.DefaultCharacterCollisionSolver;
import Peanuts.Animation.Features.LocomotionFeatureLanding;

class UCharacterFloorMoveCapability : UCharacterMovementCapability
{
	default RespondToEvent(MovementActivationEvents::Grounded);

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MovementSystemTags::GroundMovement);
	default CapabilityTags.Add(MovementSystemTags::BasicFloorMovement);
	default CapabilityTags.Add(MovementSystemTags::AudioMovementEfforts);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 150;

	default CapabilityDebugCategory = CapabilityTags::Movement;

	//Static value of how much we keep of the force
	const float ForceGroundFrictionValue = 0.14f;

	float CurrentForwardSpeed = 0.f;

	// If set, the remote side will be forced grounded for a few frames to help the crumbtrail settle
	bool bRemoteForceGrounded = false;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate_EventBased() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;

		if(ShouldBeGrounded())
			return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(!ShouldBeGrounded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams Params)
	{
		CurrentForwardSpeed = MoveComp.Velocity.ConstrainToPlane(MoveComp.WorldUp).Size();
		bRemoteForceGrounded = !HasControl() && IsActioning(n"RemoteForceGroundedState");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!HasControl())
			CrumbComp.SetCrumbDebugActive(this, false);
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
			float MoveSpeed = MoveComp.MoveSpeed;

			float TargetSpeed = 0.f;
			if (!Input.IsNearlyZero())
				TargetSpeed = MoveSpeed * Input.GetClampedToSize(0.4f, 1.f).Size();
			
			float AccelerationSpeed = MoveSpeed / 0.35f;
			CurrentForwardSpeed += AccelerationSpeed * DeltaTime;
			
			if (CurrentForwardSpeed > TargetSpeed)
				CurrentForwardSpeed = TargetSpeed;

			FVector InputMoveDelta = Input.GetSafeNormal() * CurrentForwardSpeed * DeltaTime;
			//FVector InputMoveDelta = Input.GetClampedToSize(0.4f, 1.f) * MoveSpeed * DeltaTime;
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
			FHazeReplicatedFrameMovementSettings Settings;
			FHazeActorReplicationFinalized ConsumedParams;
			if(!CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams))
			 	Settings.bUseReplicatedVelocity = false;

			if (bRemoteForceGrounded && ActiveDuration < 0.15f + CrumbComp.PredictionLag)
				FrameMoveData.OverrideGroundedState(EHazeGroundedState::Grounded);

			FrameMoveData.ApplyConsumedCrumbData(ConsumedParams, Settings);
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement FinalMovement = MoveComp.MakeFrameMovement(n"FloorMove");

		MakeFrameMovementData(FinalMovement, DeltaTime);

		if (MoveComp.BecameGrounded())
		{
			SendMovementAnimationRequest(FinalMovement, FeatureName::Landing, NAME_None);
		}
		else
		{
			SendMovementAnimationRequest(FinalMovement, FeatureName::Movement, NAME_None);
		}
	
		MoveComp.Move(FinalMovement);
		CrumbComp.LeaveMovementCrumb();
		
		// Print Debug
		if(!HasControl())
		{
			CrumbComp.SetCrumbDebugActive(this, IsDebugActive());
		}
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
