import Vino.Movement.Components.GroundPound.GroundpoundedCallbackComponent;

event void FTimeDimensionRuneSignature(int RuneNumber);

class ATimeDimensionRune : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RuneMesh;

	UPROPERTY(DefaultComponent)
    UGroundPoundedCallbackComponent GroundPoundComp;

	UPROPERTY()
	FHazeTimeLike RunePressedTimeline;

	UPROPERTY()
	bool UsedRune = false;

	UPROPERTY()
	UMaterialInstance NewRuneMat;

	UPROPERTY()
	UMaterialInstance UsedRuneMat;

	UPROPERTY()
	int RuneNumber;
	default RuneNumber = -1;

	UPROPERTY()
	FTimeDimensionRuneSignature RunePressedEvent;

	FVector RuneStartingLocation;
	FVector RuneTargetLocation;

	bool bCanBePressed = true;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (UsedRune)
			RuneMesh.SetMaterial(0, UsedRuneMat);
		else
			RuneMesh.SetMaterial(0, NewRuneMat);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		RunePressedTimeline.BindUpdate(this, n"RunePressedTimelineUpdate");
		GroundPoundComp.OnActorGroundPounded.AddUFunction(this, n"RuneGroundPounded");

		RuneStartingLocation = RuneMesh.RelativeLocation;
		RuneTargetLocation = RuneStartingLocation - FVector(0.f, 0.f, 50.f);
	}

	UFUNCTION(NotBlueprintCallable)
    void RuneGroundPounded(AHazePlayerCharacter Player)
    {
        PressRune();
    }

	void PressRune()
	{
		if (!bCanBePressed)
			return;
		
		RunePressedEvent.Broadcast(RuneNumber);
		RunePressedTimeline.PlayFromStart();
	}

	UFUNCTION()
	void RunePressedTimelineUpdate(float CurrentValue)
	{
		RuneMesh.SetRelativeLocation(FMath::Lerp(RuneStartingLocation, RuneTargetLocation, CurrentValue));
	}

	void SetRuneEnabled(bool bEnabled)
	{
		bCanBePressed = bEnabled;
	}
}