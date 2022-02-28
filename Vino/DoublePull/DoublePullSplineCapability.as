import Vino.DoublePull.DoublePullComponent;

class UDoublePullSplineCapability : UHazeCapability
{
	default CapabilityTags.Add(n"DoublePull");
	default CapabilityTags.Add(n"DoublePullEffort");
	default CapabilityDebugCategory = n"Gameplay";

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	UDoublePullComponent DoublePull;

	float EffortTimer = 0.f;
	FVector EffortOriginPosition;
	FVector EffortTargetPosition;
	FQuat EffortStartRotation;
	FQuat EffortPullRotation;
	bool bEffortCompleted = false;

	bool bWillCompleteSpline = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		DoublePull = UDoublePullComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (DoublePull == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (DoublePull.Spline == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (DoublePull.bCompleted)
			return EHazeNetworkActivation::DontActivate;

		if (!DoublePull.AreBothPlayersInteracting())
			return EHazeNetworkActivation::DontActivate;
		if (IsActioning(n"DoublePullForceGoBack"))
			return EHazeNetworkActivation::DontActivate;

		// Only activate if both players are inputting a direction
		for(auto& State : DoublePull.PullState)
		{
			if (State.bWantsToCancel)
				return EHazeNetworkActivation::DontActivate;
			if (!DoublePull.IsValidPullDirection(State.SyncPullInput.Value))
				return EHazeNetworkActivation::DontActivate;
		}

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (DoublePull == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (DoublePull.Spline == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (DoublePull.bCompleted)
			return EHazeNetworkDeactivation::DeactivateLocal;
		if (bEffortCompleted)
			return EHazeNetworkDeactivation::DeactivateLocal;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		// First massage the input to within the cone of allowed input
		FVector AverageInput;
		for (auto& State : DoublePull.PullState)
			AverageInput += DoublePull.GetConstrainedPullDirection(State.SyncPullInput.Value);
		AverageInput = AverageInput.GetClampedToMaxSize(1.f);

		FVector Origin = Owner.ActorLocation;
		FVector Target = Origin + (AverageInput * DoublePull.DistancePerPullEffort);

		// We need to make sure the target stays within the spline's tube
		Target = DoublePull.ConstrainPointToSpline(Target);

		// Check if we're going to reach the end of the spline
		FVector ClosestSplineLocation;
		float SplinePos = 0.f;
		DoublePull.Spline.FindDistanceAlongSplineAtWorldLocation(Target, ClosestSplineLocation, SplinePos);

		int LastPointIndex = DoublePull.Spline.NumberOfSplinePoints - 1;

		float SplineLength = DoublePull.Spline.GetSplineLength();
		if (SplinePos >= SplineLength - DoublePull.PullEndDistanceMargin)
		{
			ActivationParams.AddActionState(n"CompletesSpline");
			Target = DoublePull.Spline.GetLocationAtSplinePoint(LastPointIndex, ESplineCoordinateSpace::World);
			SplinePos = SplineLength;
		}

		FQuat TargetRotation = FRotator::MakeFromX((Target - Origin).GetSafeNormal()).Quaternion() * DoublePull.RotationOffset.Quaternion();

		// If we're reaching the end and the final spline point has 0 scale,
		// then we should make sure our final rotation exactly matches the wanted rotation
		if (LastPointIndex > 0)
		{
			float PenultimatePointSplinePos = DoublePull.Spline.GetDistanceAlongSplineAtSplinePoint(LastPointIndex - 1);
			if (SplinePos >= PenultimatePointSplinePos)
			{
				FVector FinalScale = DoublePull.Spline.GetScaleAtSplinePoint(LastPointIndex);
				if (FinalScale.IsNearlyZero())
				{
					FRotator FinalRotation = DoublePull.Spline.GetRotationAtSplinePoint(LastPointIndex, ESplineCoordinateSpace::World);

					float LastSegmentLength = (SplineLength - PenultimatePointSplinePos);
					if (LastSegmentLength > 0)
					{
						TargetRotation = FQuat::Slerp(
							TargetRotation,
							FinalRotation.Quaternion() * DoublePull.RotationOffset.Quaternion(),
							(SplinePos - PenultimatePointSplinePos) / LastSegmentLength
						);
					}
					else
					{
						TargetRotation = FinalRotation.Quaternion() * DoublePull.RotationOffset.Quaternion();
					}
				}
			}
		}

		ActivationParams.AddVector(n"Origin", Origin);
		ActivationParams.AddVector(n"Target", Target);
		ActivationParams.AddVector(n"TargetRotation", TargetRotation.ForwardVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		EffortOriginPosition = ActivationParams.GetVector(n"Origin");
		EffortTargetPosition = ActivationParams.GetVector(n"Target");

		EffortStartRotation = Owner.ActorQuat;
		EffortPullRotation = FRotator::MakeFromX(ActivationParams.GetVector(n"TargetRotation")).Quaternion();

		EffortTimer = 0.f;
		bEffortCompleted = false;
		bWillCompleteSpline = ActivationParams.GetActionState(n"CompletesSpline");

		DoublePull.bIsExertingPullEffort = true;
		DoublePull.OnStartedEffort.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (bWillCompleteSpline)
			DoublePull.CompletedDoublePull();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{	
		DoublePull.bIsExertingPullEffort = IsActive();
		if (!DoublePull.bIsExertingPullEffort)
			DoublePull.CurrentEffort = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		EffortTimer += DeltaTime;
		if(EffortTimer >= DoublePull.EffortDuration)
			bEffortCompleted = true;

		float Pct = FMath::Clamp(EffortTimer / DoublePull.EffortDuration, 0.f, 1.f);
		if (DoublePull.EffortCurve != nullptr)
			Pct = DoublePull.EffortCurve.GetFloatValue(Pct);

		FVector WantPosition = FMath::Lerp(EffortOriginPosition, EffortTargetPosition, Pct);
		FVector PrevPosition = Owner.ActorLocation;
		Owner.ActorLocation = WantPosition;

		// Calculate how much effort we actually expended animation wise
		float Speed = (WantPosition - PrevPosition).Size() / DeltaTime;
		DoublePull.CurrentEffort = Speed / (DoublePull.DistancePerPullEffort / DoublePull.EffortDuration);

		// Rotate actor in the direction of the spline, and then also slightly towards the actual spline
		FQuat Offset = DoublePull.RotationOffset.Quaternion();

		FQuat NowRotation = FQuat::Slerp(EffortStartRotation, EffortPullRotation, Pct);
		Owner.SetActorRotation(NowRotation);
	}
};