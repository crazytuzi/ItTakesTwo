import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrain;

class UCourtyardTrainStationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Gameplay");
	default CapabilityTags.Add(n"TrainSpeed");

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 60;

	ACourtyardTrain Train;

	const float StationaryTime = 2.5f;
	float StationaryTimeCounter = 0.f;

	float InitialSpeed = 0.f;
	float TrainStartDistanceAlongSpline = 0.f;
	float StationDistanceAlongSpline = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Train = Cast<ACourtyardTrain>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (Train.Track.StationPositionEnd.Spline == nullptr)
			return EHazeNetworkActivation::DontActivate;

		// This code just bypasses a bug where the region comps will enter twice on looped splines		
		const float Current = Train.FollowComp.Position.DistanceAlongSpline + Train.Track.Spline.GetSplineLength();
		const float Start = Train.Track.StationPositionStart.DistanceAlongSpline + Train.Track.Spline.GetSplineLength();
		if (Current < Start)
			return EHazeNetworkActivation::DontActivate;

		const float End = Train.Track.StationPositionEnd.DistanceAlongSpline + Train.Track.Spline.GetSplineLength();
		if (Current > End)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Train.Track.StationPositionEnd.Spline == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (StationaryTimeCounter >= StationaryTime)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
	
	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.BlockCapabilities(n"TrainSpeed", this);

		InitialSpeed = Train.CurrentSpeed;
		TrainStartDistanceAlongSpline = Train.FollowComp.Position.DistanceAlongSpline;
		StationDistanceAlongSpline = GetLoopedDistanceAlongSpline(Train.Track.StationPositionEnd.DistanceAlongSpline);

		StationaryTimeCounter = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.UnblockCapabilities(n"TrainSpeed", this);
		Train.Track.StationPositionEnd = FHazeSplineSystemPosition();

		Train.OnLeavingStation.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		const float CurrentDistanceAlongSpline = GetLoopedDistanceAlongSpline(Train.FollowComp.Position.DistanceAlongSpline);
		const float StationLength = StationDistanceAlongSpline - TrainStartDistanceAlongSpline;
		const float DistanceToStation = StationDistanceAlongSpline - CurrentDistanceAlongSpline;
		float DistancePercentage = FMath::Clamp(DistanceToStation / StationLength, 0.f, 1.0);
		DistancePercentage = FMath::Pow(DistancePercentage, 0.6f);

		float TargetSpeed = FMath::Lerp(0.f, InitialSpeed, DistancePercentage);
		if (FMath::IsNearlyZero(TargetSpeed, 0.2f))
			TargetSpeed = 0.f;

		Train.CurrentSpeed = TargetSpeed;

		if (FMath::IsNearlyZero(Train.CurrentSpeed))
		{
			if (StationaryTimeCounter == 0.f)
				Train.OnStoppedAtStation.Broadcast();

			StationaryTimeCounter += DeltaTime;
		}
	}

	float GetLoopedDistanceAlongSpline(float DistanceAlongSpline)
	{
		if (DistanceAlongSpline < TrainStartDistanceAlongSpline)
			return DistanceAlongSpline + Train.Track.Spline.GetSplineLength();

		return DistanceAlongSpline;
	}
}