import Cake.LevelSpecific.Hopscotch.FidgetSpinner;

class AFidgetspinnerSpawner : AHazeActor 
{
    UPROPERTY(RootComponent, DefaultComponent)
    UBillboardComponent Root;

    UPROPERTY()
    FHazeTimeLike ScaleTimeline;
    default ScaleTimeline.Duration = .5f; 

    UPROPERTY()
    TSubclassOf<AFidgetSpinner> ClassToSpawn;

    UPROPERTY()
    float ZForceMultiplier;
    default ZForceMultiplier = 13000.f;

	UPROPERTY()
	float FidgetSpinnerGravity;
	default FidgetSpinnerGravity = 450.f;

	UPROPERTY()
	FVector FidgetSpinnerScale;
	default FidgetSpinnerScale = FVector(.5f, .5f, .5f);

    AActor CurrentFidgetSpinner;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        ScaleTimeline.BindUpdate(this, n"ScaleTimelineUpdate");
        SpawnFidgetSpinner();
    }

    void SpawnFidgetSpinner()
    {
        CurrentFidgetSpinner = SpawnActor(ClassToSpawn, GetActorLocation(), GetActorRotation());
        CurrentFidgetSpinner.OnDestroyed.AddUFunction(this, n"FidgetspinnerDestroyed");
        Cast<AFidgetSpinner>(CurrentFidgetSpinner).ZForceMultiplier = ZForceMultiplier;
		Cast<AFidgetSpinner>(CurrentFidgetSpinner).FidgetSpinnerGravity = FidgetSpinnerGravity;
        ScaleFidgetspinner(CurrentFidgetSpinner);
    }

    UFUNCTION()
    void FidgetspinnerDestroyed(AActor DestroyedActor)
    {
        CurrentFidgetSpinner.OnDestroyed.Unbind(this, n"FidgetspinnerDestroyed");
        CurrentFidgetSpinner = nullptr;
        SpawnFidgetSpinner();
    }

    void ScaleFidgetspinner(AActor FidgetspinnerToScale)
    {
        FidgetspinnerToScale.SetActorScale3D(FVector::ZeroVector);
        ScaleTimeline.PlayFromStart();
    }

    UFUNCTION()
    void ScaleTimelineUpdate(float CurrentValue)
    {
        CurrentFidgetSpinner.SetActorScale3D(FMath::VLerp(FVector(0.f, 0.f, 0.f), FidgetSpinnerScale, FVector(CurrentValue, CurrentValue, CurrentValue)));
    }
}