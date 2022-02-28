import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrain;

class UCourtyardTrainSpeedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Gameplay");
	default CapabilityTags.Add(n"TrainSpeed");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 80;

	ACourtyardTrain Train;

	bool bReachedMinSpeed = false;
	const float MinSpeed = 450.f;
	const float EngineAcceleration = 80.f;
	const float SlopeAcceleration = 125.f;
	const float Drag = 0.1f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Train = Cast<ACourtyardTrain>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Train.FollowComp.HasActiveSpline())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bReachedMinSpeed = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Train.CurrentSpeed -= Train.CurrentSpeed * Drag * DeltaTime;
		Train.CurrentSpeed += EngineAcceleration * DeltaTime;

		// Add acceleration from the slope
		FVector TrainForward = Train.FollowComp.Position.WorldForwardVector.GetSafeNormal();
		float TrainDot = TrainForward.DotProduct(-FVector::UpVector);
		Train.CurrentSpeed += SlopeAcceleration * TrainDot * DeltaTime;

		// Calcualte the acceleration added from the carriages
		for (ACourtyardTrainCarriage Carriage : Train.Carriages)
		{
			float CarriageDistance = Train.Track.Spline.GetDistanceAlongSplineAtWorldLocation(Carriage.GetActorLocation());
			FVector Forward = Train.Track.Spline.GetTangentAtDistanceAlongSpline(CarriageDistance, ESplineCoordinateSpace::World).GetSafeNormal();
			float UpDot = Forward.DotProduct(-FVector::UpVector);

			Train.CurrentSpeed += SlopeAcceleration * UpDot * DeltaTime;
		}		

		if (!bReachedMinSpeed && Train.CurrentSpeed >= MinSpeed)
			bReachedMinSpeed = true;

		if (bReachedMinSpeed)
			Train.CurrentSpeed = FMath::Max(MinSpeed, Train.CurrentSpeed);
	}
}