import Cake.LevelSpecific.PlayRoom.SpaceStation.GravityBoots.GravityBootsComponent;
import Vino.Camera.Capabilities.DebugCameraCapability;
import Peanuts.Outlines.Outlines;
import Vino.Movement.Components.MovementComponent;

class UGravityBootsCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Gravity");

	AHazePlayerCharacter Player;
    UHazeMovementComponent MoveComp;
	UGravityBootsComponent GravBootsComp;

	FRotator TargetUpRotation = FVector::UpVector.Rotation();
	FVector PreviousTargetUp;
	FVector TraversalPlaneNormal;
    FHazeAcceleratedRotator UpRotation;
    default UpRotation.Value = TargetUpRotation;
    default UpRotation.Velocity = FRotator::ZeroRotator;

	FVector ForcedWorldUp;

	bool bOnGravityPath = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
        MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
		GravBootsComp = UGravityBootsComponent::Get(Owner);

		Owner.SetCapabilityActionState(n"GravityBootsEnabled", EHazeActionState::Active);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"GravityBootsEnabled"))
			return	EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"GravityBootsEnabled"))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PreviousTargetUp = MoveComp.GetWorldUp();
		TraversalPlaneNormal = FRotator(0.f, 0.f, 90.f).RotateVector(PreviousTargetUp).GetSafeNormal(); // This will be reset as soon as target up isn't in traversal plane
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		Owner.ChangeActorWorldUp(FVector::UpVector);
		
		if (Player != nullptr)
		{
			Player.ClearIdealDistanceByInstigator(this);
			Player.ClearCameraOffsetOwnerSpaceByInstigator(this);
		}
    }

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{        

	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (IsActioning(n"ResetGravityBoots"))
		{
			Owner.SetCapabilityActionState(n"ResetGravityBoots", EHazeActionState::Inactive);
			UpRotation.Value = FVector::UpVector.Rotation();
			TargetUpRotation = FVector::UpVector.Rotation();
			Owner.ChangeActorWorldUp(FVector::UpVector);
		}

		if (ConsumeAttribute(n"ForcedWorldUp", ForcedWorldUp))
		{
			TargetUpRotation = ForcedWorldUp.Rotation();
			UpRotation.Value = ForcedWorldUp.Rotation();
			Owner.ChangeActorWorldUp(ForcedWorldUp);
		}

		FHitResult Ground;
		if (MoveComp.LineTraceGround(Owner.GetActorLocation(), Ground, 600.f) && Ground.Component.HasTag(ComponentTags::GravBootsWalkable))
		{
			if (!IsActioning(n"GravityPathAlignmentBlocked"))
			{
				if (!bOnGravityPath && GravBootsComp != nullptr)
					GravBootsComp.GravityBootsActivated();
					
				bOnGravityPath = true;
				TargetUpRotation = Ground.Normal.Rotation();
				if (Player != nullptr)
				{
					float Blend = 2.f;
					Player.ApplyIdealDistance(750.f, FHazeCameraBlendSettings(Blend), this);
					Player.ApplyCameraOffsetOwnerSpace(FVector(0.f, 0.f, 175.f), FHazeCameraBlendSettings(Blend), this);
				}
			}
			else
			{
				AlignWhenLeavingPath();
			}
		}
		else if (Player != nullptr && bOnGravityPath)
		{
			GravBootsComp.GravityBootsDeactivated();
			bOnGravityPath = false;
			Player.ClearIdealDistanceByInstigator(this, 1.f);
			Player.ClearCameraOffsetOwnerSpaceByInstigator(this);
			AlignWhenLeavingPath();
		}

		FRotator CurUpRot = UpRotation.AccelerateTo(TargetUpRotation, 0.5f, DeltaTime);

		// Accelerating past 90 degrees pitch will give a gimbal wobble. Even if using 
		// quaternion shortest path may not align with plane we want to rotate in. 
		// Thus we constrain the axis to the plane spanned by current and previous target normals.
		FVector TargetUpVector = TargetUpRotation.Vector();
		if (FMath::Abs(TraversalPlaneNormal.DotProduct(TargetUpVector)) > 0.01f) 
		{
			//Past ~0.6 degrees of orthogonal, we're changing traversal plane
			TraversalPlaneNormal = TargetUpVector.CrossProduct(PreviousTargetUp).GetSafeNormal(); 
		}

		FVector NewUp = CurUpRot.Vector();
		NewUp = NewUp.ConstrainToPlane(TraversalPlaneNormal);

		float TargetUpDifSize = (NewUp - PreviousTargetUp).Size();
		if (TargetUpDifSize >= 0.025f && Player != nullptr)
			Player.SetFrameForceFeedback(0.f, 0.15f);

		PreviousTargetUp = TargetUpVector;
        Owner.ChangeActorWorldUp(NewUp);
	}

	void AlignWhenLeavingPath()
	{
		FVector CurWorldUp = MoveComp.WorldUp;
		FVector AbsWorldUp = CurWorldUp.Abs;

		FVector NewWorldUp;

		if (AbsWorldUp.X > AbsWorldUp.Y && AbsWorldUp.X > AbsWorldUp.Z)
			NewWorldUp = FVector(FMath::RoundToInt(CurWorldUp.X), 0.f, 0.f);
		if (AbsWorldUp.Y > AbsWorldUp.X && AbsWorldUp.Y > AbsWorldUp.Z)
			NewWorldUp = FVector(0.f, FMath::RoundToInt(CurWorldUp.Y), 0.f);
		if (AbsWorldUp.Z > AbsWorldUp.X && AbsWorldUp.Z > AbsWorldUp.Y)
			NewWorldUp = FVector(0.f, 0.f, FMath::RoundToInt(CurWorldUp.Z));

		TargetUpRotation = NewWorldUp.Rotation();
	}
}