import Peanuts.Spline.SplineComponent;

class APopcornStack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent, Attach = Root)
	USplineMeshComponent SplineMesh;
	default SplineMesh.Mobility = EComponentMobility::Movable;

	float TimeSinceStarted;

	UPROPERTY(Meta = (MakeEditWidget))
	FVector SplinePosition01;

	UPROPERTY(Meta = (MakeEditWidget))
	FVector SplinePosition02;

	UPROPERTY(DefaultComponent)
	UBoxComponent TopCollider;

	UPROPERTY(DefaultComponent)
	UBoxComponent Toptrigger;

	bool bShouldUpdate = true;

	bool bIsStanding = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		SplineMesh.AttachToComponent(Root, NAME_None, EAttachmentRule::SnapToTarget);
		SplineMesh.RelativeLocation = FVector();

		UpdateSplineMesh();
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
        Toptrigger.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
        Toptrigger.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");
    }

    UFUNCTION()
    void TriggeredOnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
    {
		if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
		{
			Print("Overlapping with component: "+OtherComponent.Name);
		}
    }

    UFUNCTION()
    void TriggeredOnEndOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		if (Cast<AHazePlayerCharacter>(OtherActor) != nullptr)
		{
			Print("No longer overlapping with component: "+OtherComponent.Name);
		}
        
    }

	void UpdateSplineMesh()
	{
		FVector StartLoc;
		FVector Endloc;
		FVector StartTangent;
		FVector EndTangent;

		Spline.GetLocationAndTangentAtSplinePoint(0, StartLoc, StartTangent, ESplineCoordinateSpace::World);
		Spline.GetLocationAndTangentAtSplinePoint(1, Endloc, EndTangent, ESplineCoordinateSpace::World);

		StartLoc = SplineMesh.WorldTransform.InverseTransformPosition(StartLoc);
		Endloc = SplineMesh.WorldTransform.InverseTransformPosition(Endloc);

		StartTangent = SplineMesh.WorldTransform.InverseTransformVector(StartTangent);
		EndTangent = SplineMesh.WorldTransform.InverseTransformVector(EndTangent);

		SplineMesh.SetStartAndEnd(StartLoc, StartTangent, Endloc, EndTangent, true);
	}

	void UpdateLiveMesh(FVector EndLoc)
	{
		FVector StartLoc;
		FVector Endlocation;
		FVector StartTangent;
		FVector EndTangent;

		Spline.GetLocationAndTangentAtSplinePoint(0, StartLoc, StartTangent, ESplineCoordinateSpace::World);
		Spline.GetLocationAndTangentAtSplinePoint(1, Endlocation, EndTangent, ESplineCoordinateSpace::World);

		Endlocation = EndLoc;

		TopCollider.SetWorldLocation(Endlocation);
		TopCollider.SetWorldRotation(EndTangent.Rotation());
		Toptrigger.SetWorldLocation(Endlocation);
		Toptrigger.SetWorldRotation(EndTangent.Rotation());

		StartLoc = SplineMesh.WorldTransform.InverseTransformPosition(StartLoc);
		Endlocation = SplineMesh.WorldTransform.InverseTransformPosition(Endlocation);

		StartTangent = SplineMesh.WorldTransform.InverseTransformVector(StartTangent);
		EndTangent = SplineMesh.WorldTransform.InverseTransformVector(EndTangent);

		SplineMesh.SetStartAndEnd(StartLoc, StartTangent, Endlocation, EndTangent, true);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(bShouldUpdate)
		{
			TimeSinceStarted += DeltaTime;
			FVector Endlocation = FMath::Lerp(SplinePosition01, SplinePosition02, (FMath::Sin(TimeSinceStarted) + 1) * 0.5f);

			Endlocation = ActorTransform.TransformPosition(Endlocation);
			UpdateLiveMesh(Endlocation);

			FRotator Rotationo = GetActorRotation();
			Rotationo.RotateVector(FVector::UpVector);
			SetActorRotation(Rotationo);
		}
	}
}