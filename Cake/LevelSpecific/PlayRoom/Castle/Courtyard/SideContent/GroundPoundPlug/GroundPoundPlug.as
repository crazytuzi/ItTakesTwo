import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;

event void FOnGroundPoundPlugComplete(AHazePlayerCharacter Player);

class AGroundPoundPlug : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	USceneComponent PlugRoot;

	UPROPERTY(DefaultComponent, Attach = PlugRoot)
	UStaticMeshComponent PlugMesh;

	UPROPERTY(DefaultComponent)
	UGroundPoundedCallbackComponent GroundPoundCallbackComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlugInAudioEvent;

	UPROPERTY()
	FOnGroundPoundPlugComplete OnGroundPoundPlugComplete;

	UPROPERTY()
	FHazeTimeLike MovementTimelike;
	default MovementTimelike.Duration = 0.1f;

	FVector StartLocation;

	bool bPlugActivated;

	AHazePlayerCharacter PlayerInstigator;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GroundPoundCallbackComp.OnActorGroundPounded.AddUFunction(this, n"OnGroundPounded");
		MovementTimelike.BindUpdate(this, n"OnMovementUpdate");
		MovementTimelike.BindFinished(this, n"OnMovementFinished");

		StartLocation = PlugRoot.GetRelativeLocation();
	}

	UFUNCTION()
	void OnGroundPounded(AHazePlayerCharacter Player)
	{
		if (bPlugActivated)
			return;

		PlayerInstigator = Player;
		bPlugActivated = true;
		MovementTimelike.PlayFromStart();
		UHazeAkComponent::HazePostEventFireForget(PlugInAudioEvent, GetActorTransform());
	}

	UFUNCTION()
	void OnMovementUpdate(float Value)
	{
		FVector NewLocation = FMath::Lerp(StartLocation, FVector::ZeroVector, Value);
		PlugRoot.SetRelativeLocation(NewLocation);
	}

	UFUNCTION()
	void OnMovementFinished()
	{
		OnGroundPoundPlugComplete.Broadcast(PlayerInstigator);
	}
}