
class ACastleSinkingPlatform : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MovingRoot;

	UPROPERTY(meta = (MakeEditWidget))
	FVector EndLocation;
	FVector StartLocation;
	UPROPERTY()
	float MovementDuration = 0.6f;


	FHazeTimeLike PlatformMovement;
	default PlatformMovement.Duration = MovementDuration;

#if EDITOR
    default bRunConstructionScriptOnDrag = true;
#endif	

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PlatformMovement.BindUpdate(this, n"OnMovementUpdate");
		StartLocation = MovingRoot.RelativeLocation;
	}

	UFUNCTION(DevFunction)
	void StartMovement()
	{
		PlatformMovement.Play();
	}

	UFUNCTION(DevFunction)
	void ReturnMovement()
	{
		PlatformMovement.Reverse();
	}

	UFUNCTION()
	void OnMovementUpdate(float CurrentValue)
	{
		FVector NewLocation = FMath::Lerp(StartLocation, EndLocation, CurrentValue);

		MovingRoot.SetRelativeLocation(NewLocation);
	}
}