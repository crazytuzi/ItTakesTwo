import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonPathSpline;

UCLASS(HideCategories = "Rendering Debug Collision Replication Input LOD Cooking Actor")
class AMoonBaboonIntersectionPoint : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent BillboardComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USkeletalMeshComponent BaboonMesh;
	default BaboonMesh.bHiddenInGame = true;
	default BaboonMesh.bIsEditorOnly = true;
	default BaboonMesh.VisibilityBasedAnimTickOption = EVisibilityBasedAnimTickOption::OnlyTickPoseWhenRendered;

	UPROPERTY(Category = "PathData")
	TArray<FMoonBaboonPathData> Paths;

	UPROPERTY()
	AActor Moon;

	void ChooseNewSpline(AHazeActor InOwner)
	{
		int NewPathIndex = FMath::RandRange(0, Paths.Num() - 1);

		InOwner.SetCapabilityAttributeNumber(n"CurPathDirection", GetDirectionToIntersectionPoint(Paths[NewPathIndex]));
		InOwner.SetCapabilityAttributeObject(n"CurPathSpline", Paths[NewPathIndex].Path);
		InOwner.SetCapabilityAttributeObject(n"TargetIntersectionPoint", Paths[NewPathIndex].IntersectionPoint);
	}

	UFUNCTION(CallInEditor)
	void SnapToMoonSurface()
	{
		if (Moon != nullptr)
		{
			FVector DirectionToMoon = (ActorLocation - Moon.ActorLocation).GetSafeNormal();
			FRotator Rot = Math::MakeRotFromZ(DirectionToMoon);
			SetActorRotation(Rot);
			FHitResult Hit;
			TArray<AActor> ActorsToIgnore;
			System::LineTraceSingle(ActorLocation, Moon.ActorLocation, ETraceTypeQuery::Visibility, true, ActorsToIgnore, EDrawDebugTrace::ForDuration, Hit, true);

			if (Hit.bBlockingHit && Hit.Actor != nullptr)
				SetActorLocation(Hit.Location);
		}
	}

	UFUNCTION(CallInEditor)
	void SnapSplinePointsToIntersectionPoint()
	{
		for (FMoonBaboonPathData CurPathData : Paths)
		{
			int SplinePointToMove;

			float DistanceToStartPoint = ActorLocation.Distance(CurPathData.Path.Spline.GetLocationAtSplinePoint(0, ESplineCoordinateSpace::World));
			float DistanceToEndPoint = ActorLocation.Distance(CurPathData.Path.Spline.GetLocationAtSplinePoint(CurPathData.Path.Spline.NumberOfSplinePoints -1, ESplineCoordinateSpace::World));

			if (DistanceToStartPoint > DistanceToEndPoint)
				SplinePointToMove = CurPathData.Path.Spline.NumberOfSplinePoints - 1;
			else
				SplinePointToMove = 0;
			
			CurPathData.Path.Spline.SetLocationAtSplinePoint(SplinePointToMove, ActorLocation, ESplineCoordinateSpace::World, true);
		}
	}

	ETimelineDirection GetDirectionToIntersectionPoint(FMoonBaboonPathData PathData)
	{
		float DistanceToStartPoint = ActorLocation.Distance(PathData.Path.Spline.GetLocationAtSplinePoint(0, ESplineCoordinateSpace::World));
		float DistanceToEndPoint = ActorLocation.Distance(PathData.Path.Spline.GetLocationAtSplinePoint(PathData.Path.Spline.NumberOfSplinePoints -1, ESplineCoordinateSpace::World));

		if (DistanceToStartPoint > DistanceToEndPoint)
			return ETimelineDirection::Backward;
		
		return ETimelineDirection::Forward;
	}
}

struct FMoonBaboonPathData
{
	UPROPERTY()
	AMoonBaboonPathSpline Path;

	UPROPERTY()
	AMoonBaboonIntersectionPoint IntersectionPoint;
}