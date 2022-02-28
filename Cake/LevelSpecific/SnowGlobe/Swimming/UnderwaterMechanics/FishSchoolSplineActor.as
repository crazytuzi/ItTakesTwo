import Peanuts.Spline.SplineComponent;

class AFishSchoolSplineActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FishFXSmallComp;
	default FishFXSmallComp.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent FishFXMediumComp;
	default FishFXMediumComp.bHiddenInGame = true;

	UPROPERTY()
	bool FishSmall;

	UPROPERTY()
	AActor ActorWithSpline; 

	UPROPERTY()
	UHazeSplineComponent SplineToFollow;

	UPROPERTY()
	UNiagaraComponent ActiveNiagaraComp;

	UPROPERTY()
	float Speed = 1000.f;
	
	float FishSpreadRadious = 1.f; 
	float TotalDistance = 0.f; 
	float CurrentDistance = 0.f;
			
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ActiveNiagaraComp = (FishSmall ? FishFXSmallComp : FishFXMediumComp);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ActiveNiagaraComp = (FishSmall ? FishFXSmallComp : FishFXMediumComp);

		ActiveNiagaraComp.SetHiddenInGame(false);

		SplineToFollow = Cast<UHazeSplineComponent>(ActorWithSpline.GetComponentByClass(UHazeSplineComponent::StaticClass()));

		CurrentDistance = SplineToFollow.GetDistanceAlongSplineAtWorldLocation(GetActorLocation());
		TotalDistance = SplineToFollow.GetSplineLength(); 		
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime) 
	{
		CurrentDistance += Speed * DeltaTime; 

		CurrentDistance = Math::FWrap(CurrentDistance, 0.f, SplineToFollow.GetSplineLength());

		FTransform FishTransform = SplineToFollow.GetTransformAtDistanceAlongSpline(CurrentDistance, ESplineCoordinateSpace::World); 

		SetActorLocationAndRotation(FishTransform.Location, FishTransform.Rotation);
	
		ActiveNiagaraComp.SetNiagaraVariableFloat("FishSwarmRadiusMultiplier", SplineToFollow.GetScaleAtDistanceAlongSpline(CurrentDistance).Y);
	}
		
}
