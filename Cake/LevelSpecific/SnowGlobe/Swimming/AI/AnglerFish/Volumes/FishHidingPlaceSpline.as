import Peanuts.Spline.SplineComponent;
import Vino.AI.Components.GentlemanFightingComponent;

import void AddHidingPlace(AActor, AFishHidingPlaceSpline) from "Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.UnderwaterHidingComponent";
import void RemoveHidingPlace(AActor, AFishHidingPlaceSpline) from "Cake.LevelSpecific.SnowGlobe.Swimming.UnderwaterMechanics.UnderwaterHidingComponent";

class AFishHidingPlaceSpline : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSplineComponent Spline;	

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent ProximityBox;
	default ProximityBox.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Ignore);
	default ProximityBox.SetCollisionResponseToChannel(ECollisionChannel::PlayerCharacter, ECollisionResponse::ECR_Overlap);

	UPROPERTY()
	float Radius;

	UPROPERTY()
	AActor POITarget;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{

		FVector SplineBoxExtents;
		FVector SplineCenter;
		GetSplineBoundingBox(SplineBoxExtents, SplineCenter, 50.f);

		ProximityBox.SetRelativeLocation(SplineCenter);
		ProximityBox.SetBoxExtent(SplineBoxExtents + FVector(Radius * 2.f), false);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProximityBox.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		ProximityBox.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
	}

	void GetSplineBoundingBox(FVector& Extents, FVector& Center, float IterationLength) const
	{
		if (Spline.SplineLength < SMALL_NUMBER)
			return;

		FVector Min = FVector::OneVector * BIG_NUMBER;
		FVector Max = FVector::OneVector * -BIG_NUMBER;

		int Steps = FMath::CeilToInt(Spline.SplineLength / IterationLength);
		for(int i=0; i<Steps; ++i)
		{
			float Distance = IterationLength * i;
			FVector Location = Spline.GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::Local);

			Min = Min.ComponentMin(Location);
			Max = Max.ComponentMax(Location);
		}

		Center = (Min + Max) / 2.f;
		Extents = (Max - Min) / 2.f;
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
    {
		AddHidingPlace(OtherActor, this);
    }

    UFUNCTION()
    void TriggeredOnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		RemoveHidingPlace(OtherActor, this);
    }
}