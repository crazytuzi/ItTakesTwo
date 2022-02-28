import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrog;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.JumpingFrog.JumpingFrogTags;

class UJumpingFrogMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"Movement";
	
	default TickGroup = ECapabilityTickGroups::LastMovement;

	AJumpingFrog Frog;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;
	bool bWasMountedLastFrame = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Frog = Cast<AJumpingFrog>(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Frog.MountedPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Frog.MountedPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Frog.VerticalTravelDirection = 0;
		MoveComp.StopMovement();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Frog.SetCapabilityAttributeValue(n"AudioFrogVelocity", 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"FrogMovement");
		float StepAmount = Frog.GetCollisionSize().Y;
		MoveData.OverrideStepUpHeight(StepAmount);

		// First frame, we force the frog to the ground
		if(!bWasMountedLastFrame)
		{
			bWasMountedLastFrame = true;
			MoveData.OverrideGroundedState(EHazeGroundedState::Grounded);
			MoveData.OverrideStepDownHeight(500.f);
		}
		else
		{
			MoveData.OverrideStepDownHeight(StepAmount);
		}
			
			
		Frog.SetCapabilityAttributeValue(n"AudioFrogVelocity", MoveComp.GetVelocity().Size());

		if(HasControl())
		{
			// Update Turning
			const FVector Input(Frog.CurrentMovementInput.X, Frog.CurrentMovementInput.Y, 0.0f);
			Frog.BlendSpaceTurn = Input.DotProduct(Frog.GetActorRightVector());

			const float WantedRotationSpeed = MoveComp.GetRotationSpeed();
			if(Input.IsNearlyZero() || WantedRotationSpeed <= 0 || !MoveComp.IsGrounded())
			{
				MoveComp.SetTargetFacingRotation(Frog.GetActorRotation());
			}
			else
			{
				const FVector InputDirection = Input.GetSafeNormal();	
				MoveComp.SetTargetFacingDirection(InputDirection, WantedRotationSpeed);	
			}

			MoveData.FlagToMoveWithDownImpact();
			MoveData.ApplyTargetRotationDelta();

			if(!MoveComp.IsGrounded())
			{
				MoveData.ApplyGravityAcceleration();
				MoveData.ApplyActorVerticalVelocity();
			}

			if(!Frog.bCharging && !Frog.bTongueIsActive && Frog.CurrentMovementDelay <= 0)
			{
				const float ForwardAmount = FMath::Max(Input.DotProduct(Frog.GetActorForwardVector()), 0.f);
				const FVector ForwardVelocity = Frog.GetActorForwardVector() * ForwardAmount * MoveComp.GetMoveSpeed();
				
				if(MoveComp.IsGrounded())
				{
					const FVector RedirectedVelocity = Math::ConstrainVectorToSlope(ForwardVelocity, MoveComp.DownHit.Normal, MoveComp.WorldUp).GetSafeNormal() * ForwardVelocity.Size();						
					MoveData.ApplyVelocity(RedirectedVelocity);
				}
				else
				{
					MoveData.ApplyVelocity(ForwardVelocity);
				}
			}
		}
		else if(Frog.MountedPlayer != nullptr)
		{
			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			MoveData.ApplyConsumedCrumbData(ConsumedParams);
		}

		MoveComp.Move(MoveData);

		if(MoveComp.IsGrounded())
			Frog.VerticalTravelDirection = 0;
		else
			Frog.VerticalTravelDirection = -1;

		if(Frog.MountedPlayer != nullptr)
			CrumbComp.LeaveMovementCrumb();
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString OutString = "";
		OutString += "Mounted: " + Frog.bMounted + "\n";
		OutString += "Charging: " + Frog.bCharging + "\n";
		OutString += "Jumping: " + Frog.bJumping + "\n";
		OutString += "Bouncing: " + Frog.bBouncing + "\n";
		OutString += "ShouldActivateTongue: " + Frog.bShouldActivateTongue + "\n";
		OutString += "GroundDistance: " + Frog.DistanceToGround + "\n";
		OutString += "BlendSpaceTurn: " + Frog.BlendSpaceTurn + "\n";
		OutString += "BlendSpaceCharge: " + Frog.BlendSpaceCharge + "\n";
		OutString += "VerticalTravelDirection: " + Frog.VerticalTravelDirection + "\n";	
		OutString += "CurrentMovementInput: " + Frog.CurrentMovementInput + "\n";
		return OutString;
	}

}