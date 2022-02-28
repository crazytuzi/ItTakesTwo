import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;
import Peanuts.Spline.SplineComponent;

class UWaspBehaviourFleeAlongSplineCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Flee;
    default SetPriority(EWaspBehaviourPriority::High);

	UHazeSplineComponent FleeSpline = nullptr;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
    		return EHazeNetworkActivation::DontActivate;
		if (BehaviourComponent.FleeSplines.Num() == 0)
			return EHazeNetworkActivation::DontActivate;	

	  	return EHazeNetworkActivation::ActivateUsingCrumb; 
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() != EHazeNetworkDeactivation::DontDeactivate)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Check if flee spline is still valid
		if (!System::IsValid(FleeSpline)) 
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		if (!BehaviourComponent.FleeSplines.Contains(FleeSpline))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		UHazeSplineComponent Spline = GetFleeingSpline();
		ActivationParams.AddObject(n"Spline", Spline);
		ActivationParams.AddValue(n"EntryDistance", GetBestEntryDistance(Spline));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		FleeSpline = Cast<UHazeSplineComponent>(ActivationParams.GetObject(n"Spline")); 
		BehaviourComponent.DistanceAlongMoveSpline = ActivationParams.GetValue(n"EntryDistance");
		BehaviourComponent.bSnapToMoveSpline = false;
		HealthComp.RemoveHealthBars();
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
		if (BehaviourComponent.DistanceAlongMoveSpline < 10.f)
		{
			// We're at the end of the line, disable ourselves
			CrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbFlightComplete"), FHazeDelegateCrumbParams());
			return;
		}

		// Keep moving backwards along spline
		BehaviourComponent.MoveAlongSpline(FleeSpline, Settings.FleeAcceleration, false);
    }

	UFUNCTION(NotBlueprintCallable)
	void CrumbFlightComplete(const FHazeDelegateCrumbData& CrumbData)
	{
		Owner.DisableActor(Owner);
	}

	UHazeSplineComponent GetFleeingSpline()
	{
		float ClosestDistSqr = BIG_NUMBER;
		float ClearClosestDistSqr = BIG_NUMBER;
		UHazeSplineComponent BestSpline = nullptr;
		UHazeSplineComponent BackupSpline = nullptr;
		TArray<FVector> PlayerLocs;
		PlayerLocs.Add(Game::GetCody().GetActorLocation());
		PlayerLocs.Add(Game::GetMay().GetActorLocation());
		for (UHazeSplineComponent Spline : BehaviourComponent.FleeSplines)
		{
			if (Spline == nullptr)
				continue;

			// Always flee towards start of spline, so select the spline 
			// which ends closest to us without players in the way (if possible)
			FVector EndLoc = Spline.GetLocationAtSplinePoint(Spline.GetNumberOfSplinePoints() - 1, ESplineCoordinateSpace::World);
			float DistSqr = Owner.GetActorLocation().DistSquared2D(EndLoc);
			if (DistSqr < ClosestDistSqr)			
			{
				ClosestDistSqr = DistSqr;
				BackupSpline = Spline;
			}
			if ((DistSqr < ClearClosestDistSqr) && !IsLocationObstructed(EndLoc, PlayerLocs))
			{
				ClearClosestDistSqr = DistSqr;
				BestSpline = Spline;
			}
		}
		if (BestSpline == nullptr)
			return BackupSpline;
		return BestSpline;
	}

	bool IsLocationObstructed(const FVector& Location, const TArray<FVector>& Obstructions)
	{
		FVector OwnLoc = Owner.GetActorLocation();
		FVector2D ToLoc = FVector2D(Location - OwnLoc);
		for (const FVector& Obstruction : Obstructions)
		{
			FVector2D ToObstruction = FVector2D(Obstruction - OwnLoc);
			if (ToLoc.DotProduct(ToObstruction) > 0.f)
				return true;
		}
		return false;
	}

	float GetBestEntryDistance(UHazeSplineComponent Spline)
	{
		// Find a point near the end of the spline with a tangent close to our 
		// current direction to the point. 
		FVector OwnLoc = Owner.GetActorLocation();
		float SplineLength = Spline.GetSplineLength();
		float MinDistance = SplineLength * 0.8f;
		float Interval = FMath::Max(500.f, SplineLength * 0.09f);
		float BestDot = -2.f;
		float BestDistance = SplineLength;
		for (float Distance = SplineLength; Distance > MinDistance; Distance -= Interval)
		{
			FTransform SplineTransform = Spline.GetTransformAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
			FVector ToSplineDir = (SplineTransform.GetLocation() - OwnLoc).GetSafeNormal();
			FVector SplineDir = SplineTransform.GetRotation().GetForwardVector();

			// Note that as we will follow the spline backwards, we use the reverse of the tangent
			float Dot = ToSplineDir.DotProduct(-SplineDir);
			if (Dot > BestDot)
			{
				BestDot = Dot;
				BestDistance = Distance;
			}
		}

		return BestDistance;
	}
}
