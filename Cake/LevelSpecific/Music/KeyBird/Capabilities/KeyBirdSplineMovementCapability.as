import Cake.LevelSpecific.Music.KeyBird.KeyBird;

class UKeyBirdSplineMovementCapability : UHazeCapability
{
	AKeyBird KeyBird = nullptr;
	USteeringBehaviorComponent Steering;
	ASplineActor SplineActor;
	UKeyBirdSettings Settings;

	bool bWasInRange = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		KeyBird = Cast<AKeyBird>(Owner);
		Steering = USteeringBehaviorComponent::Get(Owner);
		Settings = UKeyBirdSettings::GetSettings(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if(KeyBird.IsDead())
			return EHazeNetworkActivation::DontActivate;

		if(KeyBird.CurrentState != EKeyBirdState::SplineMovement)
			return EHazeNetworkActivation::DontActivate;

		if(KeyBird.CurrentSplineActor == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"SplineActor", KeyBird.CurrentSplineActor);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SplineActor = Cast<ASplineActor>(ActivationParams.GetObject(n"SplineActor"));
		KeyBird.SplineDistanceTotal = SplineActor.Spline.SplineLength;
		KeyBird.SplineDistanceCurrent = 0.0f;

		if(KeyBird.KeyBirdSplineSettings != nullptr)
			Owner.ApplySettings(KeyBird.KeyBirdSplineSettings, this, EHazeSettingsPriority::Override);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!HasControl())
			return;

		FVector LocationCurrent = SplineActor.Spline.GetLocationAtDistanceAlongSpline(KeyBird.SplineDistanceCurrent, ESplineCoordinateSpace::World);
		Steering.Seek.SetTargetLocation(LocationCurrent);

		const float DistanceToSplinePointSq = LocationCurrent.DistSquared(Owner.ActorLocation);

		const bool bIsInRange = DistanceToSplinePointSq < FMath::Square(Settings.SplineMovementAcceptableDistance);

		if(bIsInRange)
		{
			KeyBird.SplineDistanceCurrent = FMath::Min(KeyBird.SplineDistanceCurrent + (Settings.SplinePointMovementSpeed * DeltaTime), KeyBird.SplineDistanceTotal);
			KeyBird.FacingDirection = SplineActor.Spline.GetRotationAtDistanceAlongSpline(KeyBird.SplineDistanceCurrent, ESplineCoordinateSpace::World).Vector().GetSafeNormal2D();
		}

		KeyBird.bCustomFacingDirection = bIsInRange;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(KeyBird.IsDead())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(KeyBird.CurrentState != EKeyBirdState::SplineMovement)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(KeyBird.CurrentSplineActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(KeyBird.SplineDistanceCurrent >= KeyBird.SplineDistanceTotal)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreDeactivation(FCapabilityDeactivationSyncParams& OutParams)
	{
		if(KeyBird.IsDead())
			OutParams.AddActionState(n"Dead");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(!DeactivationParams.GetActionState(n"Dead"))
			KeyBird.StartRandomMovement();

		Owner.ClearSettingsByInstigator(this);
		KeyBird.bCustomFacingDirection = false;
	}
}
