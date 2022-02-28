import Cake.LevelSpecific.SnowGlobe.Magnetic.Underwater.MagneticBuoy;
import Cake.LevelSpecific.SnowGlobe.Swimming.SnowGlobeLakeDisableComponent;

class AMagneticUnderwaterBuoy : AMagneticBuoy
{
	default OffsetComponent.DefaultTime = 0.1f;
	default DisableComp.bAutoDisable = false;
	default DisableComp.AutoDisableRange = 2500.f;
	default DisableComp.bActorIsVisualOnly = false;

	UPROPERTY(DefaultComponent, Attach = RootComponent)
	USnowGlobeLakeDisableComponentExtension HazeDisableCompExtension;
	default HazeDisableCompExtension.ActiveType = ESnowGlobeLakeDisableType::ActiveUnderSurfaceInWater;
	default HazeDisableCompExtension.DisableRange = FHazeMinMax(6000.f, 12000.f);

	// Used to attach chain spline mesh
	UPROPERTY(DefaultComponent)
	USceneComponent SplineMeshSocket;
	default SplineMeshSocket.SetRelativeLocation(FVector::ZeroVector);

	UPROPERTY(Category = "AnchorChain")
	UStaticMesh AnchorChainMesh;

	// Use buoy movement component to play idle animation
	// default MagneticBuoyMovementComponent.bPlayIdleMovementProgrammatically = true;

	// Spline used to aid spline mesh component creation
	UHazeSplineComponent SplineComponent;

	// Spline mesh segment info
	TArray<USplineMeshComponent> ChainSplineMeshList;
	float SplineMeshLength = 2000.f;
	FVector2D SplineMeshScale = FVector2D(0.06f, 0.06f);
	UStaticMeshComponent BuoyMesh;
	FVector AnchorPoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SplineComponent = UHazeSplineComponent::GetOrCreate(this, n"ChainSplineComponent");
		BuoyMesh = UStaticMeshComponent::Get(this);

		CalculateAnchorPoint();

		// SplineComponent.ClearSplinePoints();
		// SplineComponent.AddSplinePoint(BuoyMesh.WorldLocation, ESplineCoordinateSpace::World, false);
		// SplineComponent.AddSplinePoint(AnchorPoint, ESplineCoordinateSpace::World);

		// // Create spline mesh
		// int SplineMeshCount = (SplineComponent.GetSplineLength() / SplineMeshLength);
		// for(int i = 0; i < SplineMeshCount; i++)
		// {
		// 	USplineMeshComponent SplineMeshComponent = Cast<USplineMeshComponent>(SceneComponent::CreateAttachedSceneComponent(USplineMeshComponent::StaticClass(), SplineMeshSocket, EAttachmentRule::SnapToTarget, EComponentMobility::Movable, FName("SplineMesh_" + String::Conv_IntToString(i))));

		// 	SplineMeshComponent.SetCollisionProfileName(n"NoCollision");
		// 	SplineMeshComponent.SetForwardAxis(ESplineMeshAxis::Z);
		// 	SplineMeshComponent.StaticMesh = AnchorChainMesh;

		// 	float StartDistanceAlongSpline = i * SplineMeshLength;
		// 	float EndDistanceAlongSpline = i == (SplineMeshCount - 1) ? SplineComponent.SplineLength : (i + 1) * SplineMeshLength;
		// 	SplineMeshComponent.SetStartAndEnd(SplineComponent.GetLocationAtDistanceAlongSpline(StartDistanceAlongSpline, ESplineCoordinateSpace::Local), SplineComponent.GetTangentAtDistanceAlongSpline(StartDistanceAlongSpline, ESplineCoordinateSpace::Local).GetClampedToSize(0, SplineMeshLength),
		// 									   SplineComponent.GetLocationAtDistanceAlongSpline(EndDistanceAlongSpline, ESplineCoordinateSpace::Local), SplineComponent.GetTangentAtDistanceAlongSpline(EndDistanceAlongSpline, ESplineCoordinateSpace::Local).GetClampedToSize(0, SplineMeshLength));

		// 	SplineMeshComponent.SetStartScale(SplineMeshScale);
		// 	SplineMeshComponent.SetEndScale(SplineMeshScale);

		// 	ChainSplineMeshList.Add(SplineMeshComponent);
		// }
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		// // Update anchor point world location and add a little bit of slack
		// SplineComponent.SetLocationAtSplinePoint(0, BuoyMesh.WorldLocation, ESplineCoordinateSpace::World);
		// SplineComponent.SetLocationAtSplinePoint(1, AnchorPoint, ESplineCoordinateSpace::World);
		// SplineComponent.SetTangentAtSplinePoint(0, ((AnchorPoint - BuoyMesh.WorldLocation) * 0.5f) - MagneticBuoyMovementComponent.Velocity * 8.f, ESplineCoordinateSpace::World);

		// // Update world location of anchor chain spline mesh
		// UpdateChainSpline();
	}

	void CalculateAnchorPoint()
	{
		FHazeTraceParams TraceParams;
		TraceParams.InitWithTraceChannel(ETraceTypeQuery::TraceTypeQuery1);
		TraceParams.IgnoreActor(this);

		TraceParams.From = ActorLocation;
		TraceParams.To = ActorLocation - FVector::UpVector * 30000.f;
		TraceParams.SetToLineTrace();

		FHazeHitResult HitResult;
		TraceParams.Trace(HitResult);

		if(HitResult.Actor != nullptr && HitResult.Actor.Name.ToString().Contains("Buoy_"))
		{
			TraceParams.IgnoreActor(HitResult.Actor);
			TraceParams.Trace(HitResult);
		}

		AnchorPoint = HitResult.GetImpactPoint();
	}

	void UpdateChainSpline()
	{
		for(int i = 0; i < ChainSplineMeshList.Num(); i++)
		{
			float StartDistanceAlongSpline = i * SplineMeshLength;
			float EndDistanceAlongSpline = i == (ChainSplineMeshList.Num() - 1) ? SplineComponent.SplineLength : (i + 1) * SplineMeshLength;
			ChainSplineMeshList[i].SetStartAndEnd(SplineComponent.GetLocationAtDistanceAlongSpline(StartDistanceAlongSpline, ESplineCoordinateSpace::Local), SplineComponent.GetTangentAtDistanceAlongSpline(StartDistanceAlongSpline, ESplineCoordinateSpace::Local).GetClampedToSize(0, SplineMeshLength),
											   	  SplineComponent.GetLocationAtDistanceAlongSpline(EndDistanceAlongSpline, ESplineCoordinateSpace::Local), SplineComponent.GetTangentAtDistanceAlongSpline(EndDistanceAlongSpline, ESplineCoordinateSpace::Local).GetClampedToSize(0, SplineMeshLength));
		}
	}
}