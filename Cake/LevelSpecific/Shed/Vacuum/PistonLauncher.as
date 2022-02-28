UCLASS(Abstract)
class APistonLauncher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent PistonRoot;

	UPROPERTY(DefaultComponent, Attach = PistonRoot)
	UStaticMeshComponent PistonMesh;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PistonActivateAudioEvent;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike LaunchTimeLike;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LaunchTimeLike.BindUpdate(this, n"UpdateLaunch");
	}

	UFUNCTION()
	void ActivatePiston()
	{
		LaunchTimeLike.PlayFromStart();
		UHazeAkComponent::HazePostEventFireForget(PistonActivateAudioEvent, this.GetActorTransform());
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateLaunch(float CurValue)
	{
		float CurHeight = FMath::Lerp(0.f, 800.f, CurValue);
		PistonRoot.SetRelativeLocation(FVector(0.f, 0.f, CurHeight));
	}
}