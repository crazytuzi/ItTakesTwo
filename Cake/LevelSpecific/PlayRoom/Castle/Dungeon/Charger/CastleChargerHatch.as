class AChargerHatch : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent Hatch1Root;

	UPROPERTY(DefaultComponent, Attach = Hatch1Root)
	USceneComponent Hatch1Rotation;

	UPROPERTY(DefaultComponent, Attach = Hatch1Rotation)
	UStaticMeshComponent Mesh1;

	UPROPERTY(DefaultComponent)
	USceneComponent Hatch2Root;

	UPROPERTY(DefaultComponent, Attach = Hatch2Root)
	USceneComponent Hatch2Rotation;

	UPROPERTY(DefaultComponent, Attach = Hatch2Rotation)
	UStaticMeshComponent Mesh2;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent HatchOpenEvent;

	UPROPERTY()
	FHazeTimeLike OpenTimelike;
	default OpenTimelike.Duration = 0.5f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenTimelike.BindUpdate(this, n"OnOpenTimelikeUpdate");
		OpenTimelike.BindFinished(this, n"OnOpenTimelikeFinished");
	}

	UFUNCTION()
	void OpenHatch()
	{
		OpenTimelike.PlayFromStart();
		UHazeAkComponent::HazePostEventFireForget(HatchOpenEvent, GetActorTransform());
	}

	UFUNCTION()
	void OnOpenTimelikeUpdate(float Value)
	{
		FRotator Rotation(-90.f * Value, 0.f, 0.f);
		Hatch1Rotation.SetRelativeRotation(Rotation);
		Hatch2Rotation.SetRelativeRotation(Rotation);
	}

	UFUNCTION()
	void OnOpenTimelikeFinished()
	{
		Mesh1.SetCollisionEnabled(ECollisionEnabled::NoCollision);
		Mesh2.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}
}