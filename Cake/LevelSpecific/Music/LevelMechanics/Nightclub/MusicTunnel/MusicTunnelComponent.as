UCLASS(HideCategories = "Activation Cooking Tags AssetUserData Collision")
class UMusicTunnelComponent : UActorComponent
{
	UPROPERTY(Category = "MusicTunnelComp")
	AHazeActor TargetSplineActor;

	UPROPERTY(Category = "MusicTunnelComp")
	float OffsetFromSpline = 600.f;

	UPROPERTY(Category = "MusicTunnelComp", meta = (InlineEditConditionToggle))
	bool bUseDistance = true;

	UPROPERTY(Category = "MusicTunnelComp", meta = (EditCondition = "bUseDistance"), meta = (ClampMin = "0.0", UIMin = "0.0"))
	float DistanceAlongSpline = 0.f;

	UPROPERTY(Category = "MusicTunnelComp", meta = (InlineEditConditionToggle))
	bool bUseFraction = false;

	UPROPERTY(Category = "MusicTunnelComp", meta = (EditCondition = "bUseFraction"), meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float FractionAlongSpline = 0.f;

	UPROPERTY(Category = "MusicTunnelComp", meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float RotationOffset = 0.f;

	USplineComponent TargetSplineComp;

	UPROPERTY(NotVisible)
	bool bDistanceUsedLast = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		/*if (!bUseDistance && !bUseFraction && bDistanceUsedLast)
			bUseDistance = true;

		if (!bUseDistance && !bUseDistance && !bDistanceUsedLast)
			bUseFraction = true;

		if (bUseDistance && bUseFraction && bDistanceUsedLast)
		{
			bDistanceUsedLast = false;
			bUseDistance = false;
			bUseFraction = true;
			
		}
		else if (bUseDistance && bUseFraction && !bDistanceUsedLast)
		{
			bDistanceUsedLast = true;
			bUseDistance = true;
			bUseFraction = false;
		}*/

		if (TargetSplineActor == nullptr)
			return;

		TargetSplineComp = USplineComponent::Get(TargetSplineActor);
		if (TargetSplineActor == nullptr)
			return;

		float TargetDistance = 0.f;
		FVector TargetLocation = Owner.ActorLocation;
		FRotator TargetRotation = Owner.ActorRotation;

		if (bUseDistance)
		{
			if (DistanceAlongSpline > TargetSplineComp.SplineLength)
				DistanceAlongSpline = TargetSplineComp.SplineLength;
			TargetDistance = DistanceAlongSpline;
			TargetLocation = TargetSplineComp.GetLocationAtDistanceAlongSpline(TargetDistance, ESplineCoordinateSpace::World);
			FractionAlongSpline = DistanceAlongSpline/TargetSplineComp.SplineLength;
			bUseFraction = false;
		}
		else if (bUseFraction)
		{
			TargetDistance = TargetSplineComp.SplineLength * FractionAlongSpline;
			TargetLocation = TargetSplineComp.GetLocationAtDistanceAlongSpline(TargetDistance, ESplineCoordinateSpace::World);
			DistanceAlongSpline = TargetDistance;
		}

		FVector DirectionAtDistance = TargetSplineComp.GetDirectionAtDistanceAlongSpline(TargetDistance, ESplineCoordinateSpace::World);

		DirectionAtDistance *= -1;
		TargetRotation = DirectionAtDistance.Rotation();
		float Rot = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 1.f), FVector2D(0.f, 360.f), RotationOffset);
		TargetRotation.Roll += Rot;
		// Owner.SetActorRotation(TargetRotation);

		TargetLocation -= (Owner.ActorUpVector * OffsetFromSpline);

		// Owner.SetActorLocation(TargetLocation);
	}
}