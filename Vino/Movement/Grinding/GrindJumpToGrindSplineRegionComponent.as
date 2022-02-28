import Vino.Movement.Grinding.GrindingReasons;
import Vino.Trajectory.TrajectoryStatics;
import Vino.Movement.Grinding.GrindingBaseRegionComponent;
import Vino.Movement.Grinding.GrindSpline;

class UGrindJumpToGrindSplineRegionComponent : UGrindingBaseRegionComponent
{
	UPROPERTY(NotEditable, Meta = (MakeEditWidget))
	FVector DummyLocationVector;

	UPROPERTY()
	float TargetDistance = 0;

	UPROPERTY()
	float JumpHeight = 500.f;

	UPROPERTY()
	bool bForceJumpAtEnd = true;

	UPROPERTY()
	AGrindspline TargetSpline = nullptr;

	UPROPERTY()
	EGrindSplineTravelDirection TravelDirectionWhenLanded = EGrindSplineTravelDirection::Forwards;

	FTransform GetJumpToLocation() property
	{
		if (TargetSpline == nullptr)
			return FTransform::Identity;

		return TargetSpline.Spline.GetTransformAtDistanceAlongSpline(TargetDistance, ESplineCoordinateSpace::World, false);
	}

	UFUNCTION(BlueprintOverride)
	FLinearColor GetTypeColor() const property
	{
		return FLinearColor::Teal;
	}

	UFUNCTION(BlueprintOverride)
	bool CanActorEnterRegion(AHazeActor ActivateActor, float CurrDistance, float PrevDistance, bool bTravelingForward) const
	{
		if (TargetSpline == nullptr)
			return false;

		return Super::CanActorEnterRegion(ActivateActor, CurrDistance, PrevDistance, bTravelingForward);
	}

	UFUNCTION(BlueprintOverride)
	void OnRegionInitialized()
	{
		Super::OnRegionInitialized();

#if Editor
		TargetClosestSpline();
#endif
	}

#if EDITOR
	void UpdateDistanceFromDummyLocation()
	{
		TargetDistance = TargetSpline.Spline.GetDistanceAlongSplineAtWorldLocation(WorldTransform.TransformPosition(DummyLocationVector));
		DummyLocationVector = WorldTransform.InverseTransformPosition(GetJumpToLocation().Location);
	}

	void UpdateTargetGrindDirection()
	{
		if (TargetSpline.TravelDirection != EGrindSplineTravelDirection::Bidirectional)
		{
			TravelDirectionWhenLanded = TargetSpline.TravelDirection;
			return;
		}

		FVector DirectionTo = (JumpToLocation.Location - GetEndPointLocation()).GetSafeNormal();
		FVector TargetTangent = TargetSpline.Spline.GetTangentAtDistanceAlongSpline(TargetDistance, ESplineCoordinateSpace::World).GetSafeNormal();
		
		TravelDirectionWhenLanded = EGrindSplineTravelDirection::Forwards;
		if (DirectionTo.DotProduct(TargetTangent) < 0.f)
			TravelDirectionWhenLanded = EGrindSplineTravelDirection::Backwards;
	}

	UFUNCTION(CallInEditor, Category = "Helpers")
	void TargetClosestSpline()
	{
		AGrindspline BestTarget = nullptr;
		float DistanceOnTarget = 0.f;
		FVector ClosestPointOnTarget = FVector::OneVector * 9999999999999.f;
		FVector BestTargetLocationOnSpline = FVector::ZeroVector;
		
		FVector FromLocation = EndPointLocation;
		if (ActivationDirection == EGrindSplineTravelDirection::Backwards)
			FromLocation = StartPointLocation;

		TArray<AActor> GrindSplines;
		Gameplay::GetAllActorsOfClass(AGrindspline::StaticClass(), GrindSplines);
		for (AActor Actor : GrindSplines)
		{
			if (Actor == Owner)
				continue;

			AGrindspline SplineActor = Cast<AGrindspline>(Actor);
			if (SplineActor == nullptr)
				continue;

			FVector ClosestPoint = FVector::ZeroVector;
			float PotentionalTargetDistance = 0.f;
			SplineActor.Spline.FindDistanceAlongSplineAtWorldLocation(FromLocation, ClosestPoint, PotentionalTargetDistance);
			FVector ToSpline = ClosestPoint - FromLocation;

			if (ToSpline.SizeSquared() >= ClosestPointOnTarget.SizeSquared())
				continue;

			BestTarget = SplineActor;
			DistanceOnTarget = PotentionalTargetDistance;
			ClosestPointOnTarget = ToSpline;
			BestTargetLocationOnSpline = ClosestPoint;
		}

		if (BestTarget != nullptr)
		{
			TargetSpline = BestTarget;
			TargetDistance = DistanceOnTarget;
			DummyLocationVector = Owner.ActorTransform.InverseTransformPosition(BestTargetLocationOnSpline);
		}
	}
#endif
}

#if EDITOR
class UGrindJumpToGrindSplineRegionComponentVisualiser : UHazeScriptComponentVisualizer
{
	default VisualizedClass = UGrindJumpToGrindSplineRegionComponent::StaticClass();

    UFUNCTION(BlueprintOverride)
    void VisualizeComponent(const UActorComponent Component)
	{
		UGrindJumpToGrindSplineRegionComponent Comp = Cast<UGrindJumpToGrindSplineRegionComponent>(Component);
		if (Comp == nullptr)
			return;

		if (Comp.TargetSpline == nullptr)
			return;

		Comp.UpdateDistanceFromDummyLocation();
		Comp.UpdateTargetGrindDirection();

		FVector RegionStartPos = Comp.GetStartPointLocation();
		FVector RegionEndPos = Comp.GetEndPointLocation();

		float Gravity = 980.f * 6.1f;
		float ActorMaxFallSpeed = 1800.f;
		float CurveHeight = Comp.JumpHeight;

		FVector Velocity = CalculateParamsForPathWithHeight(RegionEndPos, Comp.JumpToLocation.Location, Gravity, CurveHeight, ActorMaxFallSpeed).Velocity;
		FTrajectoryPoints TrajectoryPoints = CalculateTrajectory(RegionEndPos, 7000.f, Velocity, Gravity, 1.f, ActorMaxFallSpeed);
		
		FVector PrevPoint = RegionEndPos;
		int IPoint = 0;
		for (FVector Point : TrajectoryPoints.Positions)
		{
			if (IPoint++ == 0)
				continue;
			
			DrawDashedLine(PrevPoint, Point, FLinearColor::Green);
			PrevPoint = Point;
		}
	}
}
#endif
