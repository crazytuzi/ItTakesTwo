import Cake.LevelSpecific.Music.Classic.MusicalFollowerKey;

class UMusicKeyApproachLocationCapability : UHazeCapability
{
	AMusicalFollowerKey Key;
	UHazeSplineFollowComponent SplineFollow;

	float DistanceToSecondPoint = 0;

	bool bCloseEnoughToTarget = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Key = Cast<AMusicalFollowerKey>(Owner);
		SplineFollow = UHazeSplineFollowComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(Key.TargetLocationActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(Key.MusicKeyState != EMusicalKeyState::GoToLocation)
			return EHazeNetworkActivation::DontActivate;

		if(Key.HasReachedTargetLocation())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bCloseEnoughToTarget = false;
		Key.SetGlowActive(false);
		Key.SetTrailActive(false, true);


		Key.TargetLocationActor.SplineComp.AddSplinePoint(Key.ActorLocation, ESplineCoordinateSpace::World);

		if(Key.TargetLocationActor.SplineComp.NumberOfSplinePoints > 2)
		{
			DistanceToSecondPoint = Key.TargetLocationActor.SplineComp.GetDistanceAlongSplineAtSplinePoint(1);
		}


		SplineFollow.ActivateSplineMovement(Key.TargetLocationActor.SplineComp, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		
		FHazeSplineSystemPosition Position;
		EHazeUpdateSplineStatusType SplineStatus = SplineFollow.UpdateSplineMovement(Key.ApproachTargetLocationSpeed * DeltaTime, Position);

		if(SplineStatus == EHazeUpdateSplineStatusType::AtEnd)
		{
			bCloseEnoughToTarget = true;
		}

		FQuat RotationTarget;
		float RotationSpeed = 1.0f;
		if(Position.DistanceAlongSpline < DistanceToSecondPoint)
		{
			RotationTarget = Key.TargetLocationActor.ActorRotation.Quaternion();
			RotationSpeed = 6.5f;
		}
		else
		{
			RotationTarget = Position.WorldForwardVector.ToOrientationQuat();
			RotationSpeed = 5.5f;
		}

		const FQuat RotationCurrent = FQuat::Slerp(Owner.ActorRotation.Quaternion(), Position.WorldForwardVector.ToOrientationQuat(), 5.5f * DeltaTime);
		Owner.SetActorRotation(RotationCurrent);
		
		
		Owner.SetActorLocation(Position.WorldLocation);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(Key.MusicKeyState != EMusicalKeyState::GoToLocation)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(Key.HasReachedTargetLocation())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(bCloseEnoughToTarget)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(bCloseEnoughToTarget)
			Key.ReachedTargetLocation();
	}
}
