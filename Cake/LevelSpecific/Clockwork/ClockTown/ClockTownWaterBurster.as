import Vino.Interactions.InteractionComponent;
import Peanuts.Spline.SplineComponent;

event void FOnWaterReachedEnd();

UCLASS(Abstract)
class AClockTownWaterBurster : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BursterRoot;

	UPROPERTY(DefaultComponent, Attach = BursterRoot)
	UStaticMeshComponent BursterMesh;

	UPROPERTY(DefaultComponent, Attach = BursterRoot)
	UArrowComponent BursterNozzle;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent InteractionComp;

	UPROPERTY(DefaultComponent, Attach = BursterNozzle)
	USceneComponent WaterRoot;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation;
	FVector StartLocation;

	UPROPERTY()
	FOnWaterReachedEnd OnWaterReachedEnd;

	bool bBursting = false;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		InteractionComp.OnActivated.AddUFunction(this, n"InteractionActivated");

		StartLocation = WaterRoot.WorldLocation;
		EndLocation = ActorTransform.TransformPosition(EndLocation);
    }

    UFUNCTION()
    void InteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		InteractionComp.Disable(n"BurstActive");
		bBursting = true;
    }

	UFUNCTION(NotBlueprintCallable)
	void EnableBurster()
	{
		if (InteractionComp.IsDisabled(n"BurstActive"))
			InteractionComp.Enable(n"BurstActive");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		FVector TargetLoc = bBursting ? EndLocation : StartLocation;
		float InterpSpeed = bBursting ? 800.f : 200.f;
		FVector CurrentLoc = FMath::VInterpConstantTo(WaterRoot.WorldLocation, TargetLoc, DeltaTime, InterpSpeed);
		WaterRoot.SetWorldLocation(CurrentLoc);

		if (bBursting)
		{
			if (CurrentLoc == TargetLoc)
			{
				bBursting = false;
				OnWaterReachedEnd.Broadcast();
			}
		}
		else if (CurrentLoc == TargetLoc)
			EnableBurster();
	}
}