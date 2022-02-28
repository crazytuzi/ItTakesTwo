import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingDoublePoints;

class UAxeThrowingDoublePointsCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AxeThrowingDoublePointsCapability");
	default CapabilityTags.Add(n"AxeThrowing");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AAxeThrowingDoublePoints DoublePoints;

	// FRotator StartingRot;
	FVector StartingLoc;
	FVector EndLoc;

	FHazeAcceleratedRotator AcceleratedRot;
	FHazeAcceleratedVector AcceleratedLoc;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DoublePoints = Cast<AAxeThrowingDoublePoints>(Owner);

		StartingLoc = DoublePoints.ActorLocation;
		EndLoc = StartingLoc + DoublePoints.ActorUpVector * DoublePoints.MovementAmount;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AcceleratedRot.SnapTo(0.f);
		AcceleratedLoc.SnapTo(StartingLoc);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (DoublePoints.MovementType == EMovementTypeDoublePoints::Move)
		{
			MovementLogic(DeltaTime);
		}
		else
		{
			RotateLogic(DeltaTime);
		}
	}

	UFUNCTION()
	void RotateLogic(float DeltaTime)
	{
		FRotator RotationTarget;
		
		RotationTarget = FRotator(GetRotationAmount(), 0.f, 0.f);

		if (DoublePoints.bIsActive)
			AcceleratedRot.AccelerateTo(RotationTarget, 2.5f, DeltaTime);
		else
			AcceleratedRot.AccelerateTo(FRotator(0.f), 2.5f, DeltaTime);

		DoublePoints.MeshHoopComp.SetRelativeRotation(AcceleratedRot.Value, false, FHitResult(), true);
	}

	float GetRotationAmount()
	{
		float Value = 0.f;

		if (DoublePoints.bIsActive)
		{
			switch (DoublePoints.RotationDirection)
			{
				case ERotationDirectionDoublePoints::Positive: Value = DoublePoints.RotationAmount * -1.f; break;
				case ERotationDirectionDoublePoints::Negative: Value = DoublePoints.RotationAmount * 1.f; break;
			}
		}
		else
		{
			switch (DoublePoints.RotationDirection)
			{
				case ERotationDirectionDoublePoints::Positive: Value = DoublePoints.RotationAmount * 1.f; break;
				case ERotationDirectionDoublePoints::Negative: Value = DoublePoints.RotationAmount * -1.f; break;
			}			
		}

		return Value;
	}

	UFUNCTION()
	void MovementLogic(float DeltaTime)
	{
		AcceleratedLoc.AccelerateTo(GetLocationTarget(), 2.5f, DeltaTime);
		DoublePoints.SetActorLocation(AcceleratedLoc.Value);
	}

	FVector GetLocationTarget()
	{
		if (DoublePoints.bIsActive)
			return EndLoc;
		else
			return StartingLoc;
	}
}