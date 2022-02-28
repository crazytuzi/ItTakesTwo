import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;
import Cake.LevelSpecific.SnowGlobe.Boatsled.Triggers.BoatsledSpeedModifier;

class UBoatsledMovementReplicationPrediction : UHazeReplicationLocationCalculator
{
	ABoatsled Boatsled;
	UHazeCrumbComponent CrumbComponent;

	UBoatsledComponent BoatsledComponent;
	UHazeSplineComponent BoatsledTrack;

	FHazeAcceleratedFloat AcceleratedPredictionLag;

	TArray<AActor> TraceIgnores;

	FVector LastPrediction;

	UFUNCTION(BlueprintOverride)
	void OnSetup(AHazeActor Owner, USceneComponent RelativeComponent)
	{
		Boatsled = Cast<ABoatsled>(Owner);
		CrumbComponent = UHazeCrumbComponent::Get(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Boatsled.CurrentBoatsledder);
		BoatsledTrack = BoatsledComponent.TrackSpline;

		// Pre-fill array with trace ignores
		TraceIgnores.Add(Boatsled);
		TraceIgnores.Add(Boatsled.CurrentBoatsledder);

		if(Boatsled.OtherBoatsled != nullptr)
		{
			TraceIgnores.Add(Boatsled.OtherBoatsled);
			TraceIgnores.Add(Boatsled.OtherBoatsled.CurrentBoatsledder);
		}

		AcceleratedPredictionLag.SnapTo(BoatsledComponent.GetFramePredictionLag());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime, FHazeActorReplicationFinalized CurrentParams)
	{
		// Struct is only used on remote side; blend to smoothen latency variance
		if(!HasControl())
			AcceleratedPredictionLag.AccelerateTo(BoatsledComponent.GetFramePredictionLag(), 0.5f, DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationSend(FHazeActorReplicationCustomizable& OutTargetParams) const
	{
		OutTargetParams.CustomCrumbVector = Boatsled.MovementComponent.Velocity;

		// Handle rotation
		if(BoatsledComponent.IsSleddingOnTunnel())
		{
			float DistanceAlongSpline = BoatsledTrack.GetDistanceAlongSplineAtWorldLocation(Boatsled.ActorLocation);
			FVector TunnelCenterLocation = BoatsledTrack.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World) + BoatsledTrack.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World) * BoatsledComponent.TrackRadius;
			OutTargetParams.CustomCrumbRotator = (TunnelCenterLocation - Boatsled.ActorLocation).Rotation();
		}
		else
		{
			OutTargetParams.CustomCrumbRotator = Boatsled.MeshComponent.WorldRotation;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ProcessActorReplicationReceived(FHazeActorReplicationFinalized FromParams, FHazeActorReplicationCustomizable& TargetParams)
	{
		float ControlDistanceAlongSpline = BoatsledTrack.GetDistanceAlongSplineAtWorldLocation(TargetParams.Location);
		float PredictedDistanceAlongSpline = ControlDistanceAlongSpline + TargetParams.CustomCrumbVector.Size() * AcceleratedPredictionLag.Value;

		// This is just predicted location on spline, calculate YZ axes by tracing from above this point
		FVector PredictedLocation = BoatsledTrack.GetLocationAtDistanceAlongSpline(PredictedDistanceAlongSpline, ESplineCoordinateSpace::World);
		FRotator PredictedRotation = BoatsledTrack.GetRotationAtDistanceAlongSpline(PredictedDistanceAlongSpline, ESplineCoordinateSpace::World);

		// Get center of track
		FVector TraceOrigin = GetGuidelineLocation(PredictedDistanceAlongSpline);

		FVector TraceDirection;
		if(BoatsledComponent.IsSleddingOnTunnel())
		{
			// Just use direction towards center of tunnel
			TraceDirection = -TargetParams.CustomCrumbRotator.Vector() * (PredictedLocation - TraceOrigin).Size();
		}
		else
		{
			// Get vector from track center to predicted location and then rotate by control's roll
			TraceDirection = PredictedLocation - TraceOrigin;
			TraceDirection = TraceDirection.RotateAngleAxis(PredictedRotation.Roll - TargetParams.CustomCrumbRotator.Roll, BoatsledTrack.GetDirectionAtDistanceAlongSpline(PredictedDistanceAlongSpline, ESplineCoordinateSpace::World));
		}

		FVector TraceTo = TraceOrigin + TraceDirection * 2.f;

		// System::DrawDebugSphere(PredictedLocation, 80.f, 12, FLinearColor::Green, 3.f);
		// System::DrawDebugSphere(Boatsled.ActorLocation, 80.f, 12, FLinearColor::LucBlue, 3.f);

		// Trace towards predicted spline location with rotation to get ground position
		TArray<FHitResult> HitResults;
		if(System::LineTraceMulti(TraceOrigin, TraceTo, ETraceTypeQuery::TraceTypeQuery1, false, TraceIgnores, EDrawDebugTrace::None, HitResults, true, DrawTime = 20.f))
		{
			for(FHitResult HitResult : HitResults)
			{
				if(!HitResult.bBlockingHit)
					continue;

				if(HitResult.Actor != BoatsledComponent.TrackSpline.Owner && !HitResult.Actor.IsA(ABoatsledSpeedModifier::StaticClass()))
					continue;

				TargetParams.CustomLocation = LastPrediction = HitResult.ImpactPoint;
			}
		}

		// Fallback in case previous trace didn't hit track
		if(TargetParams.CustomLocation == FVector::ZeroVector)
		{
			// Get predicted location
			TargetParams.CustomLocation = TargetParams.Location + BoatsledTrack.GetDirectionAtDistanceAlongSpline(ControlDistanceAlongSpline, ESplineCoordinateSpace::World) * TargetParams.CustomCrumbVector.Size() * AcceleratedPredictionLag.Value;

			// Trace from predicted location instead of guideline
			FHitResult HitResult;
			if(System::LineTraceSingle(TargetParams.CustomLocation, TargetParams.CustomLocation + TraceDirection.GetSafeNormal() * 200.f, ETraceTypeQuery::TraceTypeQuery1, false, TraceIgnores, EDrawDebugTrace::None, HitResult, true, DrawTime = 10.f))
				TargetParams.CustomLocation = HitResult.ImpactPoint;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ProcessFinalReplicationTarget(FHazeActorReplicationCustomizable& TargetParams) const
	{
		// Handle other crumbs without custom info
		if(!TargetParams.CustomLocation.IsZero())
			TargetParams.Location = TargetParams.CustomLocation;
	}

	FVector GetGuidelineLocation(float DistanceAlongSpline) const
	{
		return BoatsledTrack.GetLocationAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World) + BoatsledTrack.GetUpVectorAtDistanceAlongSpline(DistanceAlongSpline, ESplineCoordinateSpace::World) * BoatsledComponent.TrackRadius;
	}
}