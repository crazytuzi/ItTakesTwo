import Cake.LevelSpecific.Basement.ParentBlob.ParentBlob;
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobSettings;

class UParentBlobMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Movement");
	default CapabilityTags.Add(n"ParentBlob");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 150;

	default CapabilityDebugCategory = n"ParentBlob";

	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	AParentBlob ParentBlob;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ParentBlob = Cast<AParentBlob>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!MoveComp.CanCalculateMovement())
			return EHazeNetworkActivation::DontActivate;
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!MoveComp.CanCalculateMovement())
		{
			if (HasControl())
				return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			else
				return EHazeNetworkDeactivation::DeactivateLocal;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return MoveComp.CanCalculateMovement();
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UParentBlobSettings Settings = ParentBlob.Settings;

		if (HasControl())
		{
			// Calculate what direction to move in based on current inputs
			FVector Direction = FVector(0.f, 0.f, 0.f);
			for (const FVector& Input : ParentBlob.PlayerMovementDirection)
				Direction += Input;

			float InputSpeed = Direction.Size() / 2.f;
			InputSpeed = FMath::Pow(InputSpeed, 2.f);
			Direction.Normalize();

			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"ParentBlobMovement");

			// Try to face the direction we're moving in
			if (InputSpeed > 0.01f)
			{
				/* Draw a line between the players to rotate based on their position and where they want to go*/
				// The goal of this is to give the illusion of May's side pulling when May wants to move.
				FVector ActorLocation = ParentBlob.ActorLocation;
				FVector MayInput = ParentBlob.PlayerMovementDirection[Game::GetMay()];
				FVector CodyInput = ParentBlob.PlayerMovementDirection[Game::GetCody()];
				FVector MayTargetPos = ActorLocation + MayInput;
				FVector CodyTargetPos = ActorLocation + CodyInput;
				FVector MayToCody = CodyTargetPos - MayTargetPos;

				FVector TargetForward = FVector::ZeroVector;
				if (MayInput.Size() > 0.01f && CodyInput.Size() > 0.01f && (FMath::Acos(MayInput.DotProduct(CodyInput)) * RAD_TO_DEG) < 100.f)
					TargetForward = (MayInput + CodyInput) / 2.f;
				else
					TargetForward = MayToCody.CrossProduct(MoveComp.WorldUp);
				TargetForward.Normalize();				
				
				// MoveComp.SetTargetFacingDirection(Direction, 3.f);
				MoveComp.SetTargetFacingDirection(ParentBlob.DesiredForwardDirecton.GetSafeNormal());
				FrameMove.ApplyTargetRotationDelta();
			}

			float MoveSpeed = MoveComp.IsGrounded() ? Settings.MoveSpeed : Settings.AirControl;

			// Move the character based on our merged input
			
			FrameMove.ApplyAndConsumeImpulses();
			if (MoveComp.IsAirborne())
			{
				FrameMove.ApplyActorVerticalVelocity();
				FrameMove.ApplyGravityAcceleration();
			}
			FrameMove.FlagToMoveWithDownImpact();

			// if (MoveComp.Velocity.DotProduct(MoveComp.WorldUp) > 50.f)
				// FrameMove.OverrideStepDownHeight(0.f);

			FVector DesiredVelocity = Direction * MoveSpeed * InputSpeed;
			ParentBlob.DesiredVelocity = DesiredVelocity;
			FrameMove.ApplyVelocity(DesiredVelocity);

			MoveComp.Move(FrameMove);
			ParentBlob.SendAnimationRequest(FrameMove, n"Movement");

			CrumbComp.SetCustomCrumbVector(ParentBlob.PlayerMovementDirection[0]);
			CrumbComp.SetReplicatedInputDirection(ParentBlob.PlayerMovementDirection[1]);

			CrumbComp.LeaveMovementCrumb();
		}
		else
		{
			// Follow the crumb trail for all movement
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"ParentBlobMovement");

			FHazeActorReplicationFinalized ConsumedParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			FrameMove.ApplyConsumedCrumbData(ConsumedParams);

			MoveComp.Move(FrameMove);

			ParentBlob.PlayerMovementDirection[0] = ConsumedParams.CustomCrumbVector;
			ParentBlob.PlayerMovementDirection[1] = ConsumedParams.ReplicatedInput;
			ParentBlob.SendAnimationRequest(FrameMove, n"Movement");
		}
	}
};
