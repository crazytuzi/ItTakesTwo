import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;
class AGroundPoundableScrews : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
    UGroundPoundedCallbackComponent GroundPoundComp;

	UPROPERTY()
	float GroundPoundTargetHeight = 0.f;

	float StartingHeight = 0.f;

	UPROPERTY()
	bool bShowTargetHeight = false;

	UPROPERTY()
	float ScrewMoveDuration = 0.1f;

	UPROPERTY()
	UAkAudioEvent AudioEvent;

	float ScrewMoveTimer = 0.f;
	bool bHasBeenGroundPounded = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"ButtonGroundPounded");
		MeshRoot.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bShowTargetHeight)
			MeshRoot.SetRelativeLocation(FVector(0.f, 0.f, GroundPoundTargetHeight));
		else
			MeshRoot.SetRelativeLocation(FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(FVector(0.f, 0.f, StartingHeight), FVector(0.f, 0.f, GroundPoundTargetHeight), FMath::Min(ScrewMoveTimer/ScrewMoveDuration, 1.f)));

		if (ScrewMoveTimer >= ScrewMoveDuration)
			SetActorTickEnabled(false);
		
		ScrewMoveTimer += DeltaTime;
	}

	UFUNCTION(NotBlueprintCallable)
    void ButtonGroundPounded(AHazePlayerCharacter Player)
    {
		if (bHasBeenGroundPounded)
			return;

		bHasBeenGroundPounded = true;
		UHazeAkComponent::Get(Player).HazePostEvent(AudioEvent);

		SetActorTickEnabled(true);
	}
}