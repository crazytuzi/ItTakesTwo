import Vino.DoublePull.DoublePullComponent;

class UDoublePullGoBackCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DoublePull");
	default CapabilityTags.Add(n"DoublePullGoBack");
	default CapabilityDebugCategory = n"Gameplay";

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	double TickGroupOrder = 50;

	UPROPERTY()
	float GoBackDistancePerEffort = 150.f;

	UPROPERTY()
	UCurveFloat GoBackEffortCurve;

	UDoublePullComponent DoublePull;
	float EffortDuration = 1.f;

	float EffortTimer = 0.f;
	FVector EffortOriginPosition;
	FVector EffortTargetPosition;
	bool bEffortCompleted = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DoublePull = UDoublePullComponent::Get(Owner);

		// Figure out how long a pull effort is
		if (GoBackEffortCurve != nullptr)
		{
			float MinTime = 0.f;
			float MaxTime = 0.f;
			GoBackEffortCurve.GetTimeRange(MinTime, MaxTime);

			EffortDuration = FMath::Max(MaxTime, 0.01f);
		}
		else
		{
			EffortDuration = 1.f;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (DoublePull == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (DoublePull.Spline == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (DoublePull.IsAnyPlayerInteracting() && !IsActioning(n"DoublePullForceGoBack"))
			return EHazeNetworkActivation::DontActivate;

		if (Owner.IsAnyCapabilityActive(n"DoublePullEffort"))
			return EHazeNetworkActivation::DontActivate;

		FVector SplineStart = DoublePull.Spline.GetLocationAtSplinePoint(0, ESplineCoordinateSpace::World);
		if (SplineStart.Distance(Owner.ActorLocation) < 10.f)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (DoublePull == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (DoublePull.Spline == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (bEffortCompleted)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		FVector Origin = Owner.ActorLocation;
		FVector Target;

		FVector ClosestSplineLocation;
		float SplinePos = 0.f;
		DoublePull.Spline.FindDistanceAlongSplineAtWorldLocation(Origin, ClosestSplineLocation, SplinePos);

		float DestinationSplinePos = FMath::Max(SplinePos - GoBackDistancePerEffort, 0.f);
		FVector DestinationOnSpline = DoublePull.Spline.GetLocationAtDistanceAlongSpline(DestinationSplinePos, ESplineCoordinateSpace::World);

		FVector DestinationFromEffort = Origin + (DestinationOnSpline - Origin).GetClampedToMaxSize(GoBackDistancePerEffort);

		Target = DoublePull.ConstrainPointToSpline(DestinationFromEffort);

		ActivationParams.AddVector(n"Origin", Origin);
		ActivationParams.AddVector(n"Target", Target);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.SetAnimBoolParam(n"DoublePullGoingBack", true);
		Owner.BlockCapabilities(n"DoublePullEffort", this);

		EffortOriginPosition = ActivationParams.GetVector(n"Origin");
		EffortTargetPosition = ActivationParams.GetVector(n"Target");

		EffortTimer = 0.f;
		bEffortCompleted = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.SetAnimBoolParam(n"DoublePullGoingBack", false);
		Owner.UnblockCapabilities(n"DoublePullEffort", this);
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bool bIsAtStart = false;
		if (DoublePull != nullptr && DoublePull.Spline != nullptr)
		{
			FVector SplineStart = DoublePull.Spline.GetLocationAtSplinePoint(0, ESplineCoordinateSpace::World);
			bIsAtStart = SplineStart.Distance(Owner.ActorLocation) < 10.f;
		}

		Owner.SetAnimBoolParam(n"DoublePullIsAtStart", bIsAtStart);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		EffortTimer += DeltaTime;
		if(EffortTimer >= DoublePull.EffortDuration)
			bEffortCompleted = true;

		float Pct = FMath::Clamp(EffortTimer / DoublePull.EffortDuration, 0.f, 1.f);
		if (GoBackEffortCurve != nullptr)
			Pct = GoBackEffortCurve.GetFloatValue(Pct);

		FVector WantPosition = FMath::Lerp(EffortOriginPosition, EffortTargetPosition, Pct);
		FVector PrevPosition = Owner.ActorLocation;
		Owner.ActorLocation = WantPosition;

		// Calculate how much effort we actually expended animation wise
		float Speed = (WantPosition - PrevPosition).Size() / DeltaTime;
		float DoneEffort = Speed / (GoBackDistancePerEffort / EffortDuration);

		// Rotation should be the opposite of the direction we're moving, since we're going backwards
		FQuat Offset = DoublePull.RotationOffset.Quaternion();
		FQuat PullRotation = FRotator::MakeFromX(-(EffortTargetPosition - EffortOriginPosition).GetSafeNormal()).Quaternion() * Offset;

		FQuat NowRotation = FMath::QInterpConstantTo(Owner.ActorQuat, PullRotation, DeltaTime, 0.6f * DoneEffort);
		Owner.SetActorRotation(NowRotation);
	}
};