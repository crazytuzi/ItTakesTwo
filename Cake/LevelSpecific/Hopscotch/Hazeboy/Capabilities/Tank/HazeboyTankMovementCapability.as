import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyTank;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager;
import Rice.Math.MathStatics;

class UHazeboyTankMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazeboyTank Tank;
	UHazeMovementComponent MoveComp;
	UHazeCrumbComponent CrumbComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Tank = Cast<AHazeboyTank>(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		CrumbComp = UHazeCrumbComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HazeboyGameIsActive())
			return EHazeNetworkActivation::DontActivate;

		if (Tank.OwningPlayer == nullptr)
			return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!HazeboyGameIsActive())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (Tank.OwningPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Tank.BP_BeginMovement();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Tank.BP_EndMovement();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float LastYaw = Tank.ActorRotation.Yaw;
		FRotator LastSpringArmRotation = Tank.SpringArm.WorldRotation;
		FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"Tank");

		if (HasControl())
		{
			FVector Input = GetAttributeVector(AttributeVectorNames::MovementRaw);
			Input = Tank.TransformInputRelativeToWorld(Input);

			// Rotate mesh and turret
			float InputMagnitude = Input.Size();
			FVector CurrentForward = Tank.ActorForwardVector;

			if (InputMagnitude > 0.02f)
			{
				// Rotate base
				FVector TargetForward = Input.GetSafeNormal();

				float TurnSpeed = Hazeboy::TurnSpeed * InputMagnitude;
				CurrentForward = SlerpVectorTowardsAroundAxis(CurrentForward, TargetForward, FVector::UpVector, TurnSpeed * DeltaTime);
			}

			// Next, move, but ONLY move in the current forward of the tank
			if (Tank.HurtTimer <= 0.f)
			{
				FrameMove.ApplyVelocity(Input.ConstrainToDirection(CurrentForward) * Hazeboy::MoveSpeed);
				FrameMove.SetRotation(Math::MakeQuatFromX(CurrentForward));
			}
		}
		else
		{
			FHazeActorReplicationFinalized CrumbData;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbData);
			FrameMove.ApplyConsumedCrumbData(CrumbData);
		}

		MoveComp.Move(FrameMove);
		CrumbComp.LeaveMovementCrumb();

		// Update our current speed for audio :)
		float SpeedPercent = MoveComp.Velocity.Size() / Hazeboy::MoveSpeed;
		Tank.BP_OnMoveForward(SpeedPercent);
		if (SpeedPercent > 0.5f)
			Tank.OwningPlayer.SetFrameForceFeedback(0.1f * SpeedPercent, 0.1f * SpeedPercent);

		float NewYaw = Tank.ActorRotation.Yaw;
		float DeltaRotate = FMath::FindDeltaAngleDegrees(LastYaw, NewYaw);
		float RotateSpeed = DeltaRotate / DeltaTime;
		float RotatePercent = RotateSpeed / 360.f;

		Tank.BP_OnTurn(RotatePercent);
		if (RotatePercent > 0.1f)
			Tank.OwningPlayer.SetFrameForceFeedback(0.1f * FMath::Abs(RotatePercent), 0.1f * FMath::Abs(RotatePercent));

		// Restore spring arm rotation
		Tank.SpringArm.WorldRotation = LastSpringArmRotation;
		Tank.UpdateOcclusionParams();
	}
}