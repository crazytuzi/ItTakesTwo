import Vino.Movement.Swinging.SwingPoint;

class ASpaceSwingPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent SwingRoot;

	UPROPERTY(DefaultComponent, Attach = SwingRoot)
	UStaticMeshComponent SwingMesh;

	UPROPERTY(DefaultComponent, Attach = SwingMesh)
	USwingPointComponent SwingPointComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 20000.f;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SwingPointSpotSoundEvent;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike WobbleTimeLike;
	default WobbleTimeLike.bLoop = true;

	UPROPERTY()
	float ConstantRotationRate = 50.f;

	UPROPERTY()
	float WobbleStartDelay = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		WobbleTimeLike.SetPlayRate(0.65f);
		WobbleTimeLike.BindUpdate(this, n"UpdateWobble");
		HazeAkComp.HazePostEvent(SwingPointSpotSoundEvent);
		
		if (WobbleStartDelay == 0.f)
			WobbleTimeLike.PlayFromStart();
		else
			System::SetTimer(this, n"StartWobbling", WobbleStartDelay, false);
	}

	UFUNCTION(NotBlueprintCallable)
	void StartWobbling()
	{
		WobbleTimeLike.PlayFromStart();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateWobble(float CurValue)
	{
		float CurWobbleRot = FMath::Lerp(0.f, 4.f, CurValue);
		SwingRoot.SetRelativeRotation(FRotator(0.f, 0.f, CurWobbleRot));

		float CurWobbleLoc = FMath::Lerp(0.f, 75.f, CurValue);
		SwingMesh.SetRelativeLocation(FVector(0.f, 0.f, CurWobbleLoc));
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		AddActorLocalRotation(FRotator(0.f, ConstantRotationRate * DeltaTime, 0.f));
	}
}