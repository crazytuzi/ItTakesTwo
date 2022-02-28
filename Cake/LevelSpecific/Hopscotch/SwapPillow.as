import Cake.LevelSpecific.Hopscotch.SwapPuzzleCharacterClone;
import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

event void FSwapPillowEvent(bool bActivated);

class ASwapPillow : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent Mesh;

    UPROPERTY()
    FHazeTimeLike SwapTimeline;
    default SwapTimeline.Duration = 1.f;

    UPROPERTY()
    FSwapPillowEvent SwapPillowEvent;

    UPROPERTY()
    bool bCorrectPillows;

	UPROPERTY()
	bool bShouldFlipOnOverlap;
	default bShouldFlipOnOverlap = true;

	UPROPERTY()
	TArray<UMaterialInstance> MaterialArray;

	UPROPERTY()
	bool bHasConnectedSwapPillow = false;

	UPROPERTY(Meta = (EditCondition = "bShouldSpringUpwards"))
	ASwapPillow ConnectedSwapPillow;
    
	bool bCanBeChanged = true;

    int AmountOfPlayersOnPlatform;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bShouldFlipOnOverlap)
		{
			Mesh.SetMaterial(0, MaterialArray[0]); 
		} else
		{
			Mesh.SetMaterial(0, MaterialArray[1]);
		}
	}

	UFUNCTION(CallInEditor)
	void GatherConnectedSwapPillow()
	{
		TArray <AActor> ActorArray; 
		Gameplay::GetAllActorsWithTag(n"MiddleMirror", ActorArray);

		FVector2D OwnOffset = FVector2D(ActorLocation.X, ActorArray[0].ActorLocation.Y) - FVector2D(ActorLocation.X, ActorLocation.Y);

		FHazeTraceParams TraceParams;
		TraceParams.InitWithTraceChannel(ETraceTypeQuery::Camera);
		TraceParams.SetToLineTrace();
		FVector TraceFrom = FVector(ActorLocation.X, ActorArray[0].ActorLocation.Y, 500.f) + FVector(OwnOffset.X, OwnOffset.Y, ActorArray[0].ActorLocation.Z);
		TraceParams.From = TraceFrom;
		TraceParams.To = TraceFrom - FVector(0.f, 0.f, 1000.f);
		TraceParams.DebugDrawTime = 30.f;

		FHazeHitResult Hit;
		TraceParams.Trace(Hit);

		if (Hit.Actor != nullptr)
		{
			ASwapPillow Pillow = Cast<ASwapPillow>(Hit.Actor);
			if (Pillow != nullptr)
				ConnectedSwapPillow = Pillow;
		}
	}

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		FActorImpactedByPlayerDelegate ImpactDelegate;
		ImpactDelegate.BindUFunction(this, n"PlayerLandedOnActor");
		BindOnDownImpactedByPlayer(this, ImpactDelegate);

		FActorNoLongerImpactingByPlayerDelegate NoImpactDelegate;
		NoImpactDelegate.BindUFunction(this, n"PlayerLeftActor");
		BindOnDownImpactEndedByPlayer(this, NoImpactDelegate);

        SwapTimeline.BindUpdate(this, n"SwapTimelineUpdate");
        SwapTimeline.BindFinished(this, n"SwapTimelineFinished");
    }

	UFUNCTION()
	void PlayerLandedOnActor(AHazePlayerCharacter Player, const FHitResult& Hit)
	{		
		if (bShouldFlipOnOverlap)
		{
			AmountOfPlayersOnPlatform++;

			if (AmountOfPlayersOnPlatform == 1 && bCanBeChanged)
			{
				SwapTimeline.Play();
				AudioPillowSwappedColor(true);

				if (bHasConnectedSwapPillow)
					ConnectedSwapPillow.SwapTimeline.Play();
			}
		}
	}

	UFUNCTION()
	void PlayerLeftActor(AHazePlayerCharacter Player)
	{
		if (bShouldFlipOnOverlap)
		{
			AmountOfPlayersOnPlatform--;

			if (AmountOfPlayersOnPlatform == 0 && bCanBeChanged)
			{
				SwapTimeline.Reverse();
				AudioPillowSwappedColor(false);

				if (bHasConnectedSwapPillow)
					ConnectedSwapPillow.SwapTimeline.Reverse();
			}
		}
	}

    UFUNCTION()
    void SwapTimelineUpdate(float CurrentValue)
    {
        Mesh.SetScalarParameterValueOnMaterialIndex(0, n"Pattern", FMath::Lerp(1.f, -1.f, CurrentValue));
    }

    UFUNCTION()
    void SwapTimelineFinished(float CurrentValue)
    {
        CurrentValue >= 1.f ? SwapPillowEvent.Broadcast(true) : SwapPillowEvent.Broadcast(false);
    }

    UFUNCTION()
    void SwapPuzzleSolved()
    {
        bCanBeChanged = false;

        bCorrectPillows ? SwapTimeline.ReverseFromEnd() : SwapTimeline.PlayFromStart();
    }

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void AudioPillowSwappedColor(bool bSwappedToWhite)
	{
		
	}
}