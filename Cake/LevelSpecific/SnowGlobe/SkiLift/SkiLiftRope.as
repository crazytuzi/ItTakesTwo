import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.SnowGlobe.SkiLift.SkiLiftGrip;

class ASkiLiftRope : AHazeActor
{
//	UPROPERTY(DefaultComponent, RootComponent)
//	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, RootComponent)
	UHazeSplineComponent Spline;

	UPROPERTY()
	TSubclassOf<ASkiLiftGrip> GripClass;

	UPROPERTY()
	float LiftSpeed = 100.f;

	UPROPERTY()
	int NumberOfGrips = 1;

	TMap<ASkiLiftGrip, float> Grips;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SpawnGrips();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MoveGrips();
	}

	void SpawnGrips()
	{
		float GripSpacing = Spline.GetSplineLength() / NumberOfGrips;

		for (int Index = 0, Count = NumberOfGrips; Index < Count; ++Index)
		{
			float Distance = Index * GripSpacing;
			FVector SpawnLocation = Spline.GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
			ASkiLiftGrip SpawnedGrip = Cast<ASkiLiftGrip>(SpawnActor(GripClass.Get(), SpawnLocation));
			SpawnedGrip.AttachToActor(this, AttachmentRule = EAttachmentRule::KeepWorld);
			Grips.Add(SpawnedGrip, Distance);
		}
	}

	void MoveGrips()
	{
		for(auto Grip : Grips)
		{
			float Distance = Grip.Value + LiftSpeed * GetActorDeltaSeconds();
			Distance = Math::FWrap(Distance, 0.f, Spline.GetSplineLength());

			FVector Location = Spline.GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);
			Grip.Key.SetActorLocation(Location);
			Grips.Add(Grip.Key, Distance);
		}
	}
}