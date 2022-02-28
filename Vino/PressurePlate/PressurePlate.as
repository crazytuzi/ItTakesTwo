import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackGlobalBindFunctions;

event void FOnPressurePlateActivated();
event void FOnPressurePlateDeactivated();

UCLASS(Abstract)
class APressurePlate : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent RootComp;

    UPROPERTY(DefaultComponent, Attach = RootComp)
    UStaticMeshComponent PlateMesh;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent FrameMesh;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlateActivatedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlateDeactivatedAudioEvent;

	UPROPERTY(Category = "Movement")
	FHazeTimeLike MovePlateTimeLike;
	default MovePlateTimeLike.Duration = 0.25f;
	default MovePlateTimeLike.Curve.ExternalCurve = Asset("/Game/Blueprints/LevelMechanics/PressurePlateDefaultMovementCurve.PressurePlateDefaultMovementCurve");

	UPROPERTY(Category = "Movement")
	FVector TopLocation = FVector(0.f, 0.f, 0.f);
	UPROPERTY(Category = "Movement")
	FVector FullyPressedOffset = FVector(0.f, 0.f, -15.f);

	UPROPERTY(Category = "Movement")
	bool bPreviewOffset = false;

	/* Whether the pressure plate should stay down as soon as it's pressed.  */
	UPROPERTY(Category = "Pressure Plate")
	bool bSticky = false;

	/* Whether only the players can trigger the pressure plate, or any actor with a movement component. */
	UPROPERTY(Category = "Pressure Plate")
	bool bPlayersOnly = true;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect ActivatedForceFeedback;

    UPROPERTY()
    FOnPressurePlateActivated OnPressurePlateActivated;
    UPROPERTY()
    FOnPressurePlateDeactivated OnPressurePlateDeactivated;

	TArray<AHazeActor> ActorsOnPlate;
    bool bActiveLocal = false;

	UPROPERTY()
	bool bActiveControl = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		FActorImpactedDelegate OnPressurePlateImpacted;
		OnPressurePlateImpacted.BindUFunction(this, n"PressurePlateImpacted");
		BindOnDownImpacted(this, OnPressurePlateImpacted);

		FActorNoLongerImpactingDelegate OnPressurePlateNoLongerImpacted;
		OnPressurePlateNoLongerImpacted.BindUFunction(this, n"PressurePlateNoLongerImpacted");
		BindOnDownImpactEnded(this, OnPressurePlateNoLongerImpacted);

		MovePlateTimeLike.BindUpdate(this, n"UpdateMovePlate");
		MovePlateTimeLike.BindFinished(this, n"FinishMovePlate");
    }

    UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (bPreviewOffset)
			PlateMesh.SetRelativeLocation(FullyPressedOffset);
		else
			PlateMesh.SetRelativeLocation(TopLocation);

		PlateMesh.SetCullDistance(Editor::GetDefaultCullingDistance(PlateMesh) * CullDistanceMultiplier);
		FrameMesh.SetCullDistance(Editor::GetDefaultCullingDistance(FrameMesh) * CullDistanceMultiplier);
	}

	UFUNCTION()
	void PressurePlateImpacted(AHazeActor ImpactingActor, FHitResult Hit)
	{
		if (bPlayersOnly && Cast<AHazePlayerCharacter>(ImpactingActor) == nullptr)
			return;

		if (ImpactingActor.HasControl())
		{
			if(!ActorsOnPlate.Contains(ImpactingActor))
				NetSetActorOnPlate(ImpactingActor, true);
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSetActorOnPlate(AHazeActor ImpactingActor, bool bOnPlate)
	{
		if (bOnPlate)
		{
			if (ActorsOnPlate.Num() == 0)
			{
				if (HasControl())
					NetSetPlateActive(true);

				MovePlateTimeLike.Play();

				AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(ImpactingActor);
				if (Player != nullptr && ActivatedForceFeedback != nullptr && MovePlateTimeLike.Value <= 0.01f)
					Player.PlayForceFeedback(ActivatedForceFeedback, false, true, n"PressurePlate");
			}

			ActorsOnPlate.AddUnique(ImpactingActor);
		}
		else
		{
			ActorsOnPlate.Remove(ImpactingActor);

			if (ActorsOnPlate.Num() == 0)
			{
				if (!bSticky)
					MovePlateTimeLike.Reverse();

				if (HasControl())
					NetSetPlateActive(false);
			}
		}
	}

	UFUNCTION(NetFunction, NotBlueprintCallable)
	void NetSetPlateActive(bool bPlateActive)
	{
		if (bPlateActive)
		{
			ActivatePressurePlate();
		}
			
		else
		{
			DeactivatePressurePlate();
		}
			
	}

	UFUNCTION()
	void PressurePlateNoLongerImpacted(AHazeActor ImpactingActor)
	{
		if (bPlayersOnly && Cast<AHazePlayerCharacter>(ImpactingActor) == nullptr)
			return;

		if (ImpactingActor.HasControl())
		{
			if(ActorsOnPlate.Contains(ImpactingActor))
				NetSetActorOnPlate(ImpactingActor, false);
		}
	}

    void ActivatePressurePlate()
    {
        if(!bActiveControl)
        {
            bActiveControl = true;
            OnPressurePlateActivated.Broadcast();
			HazeAkComp.HazePostEvent(PlateActivatedAudioEvent);
        }
    }

    void DeactivatePressurePlate()
    {
        if(bActiveControl && !bSticky)
        {
            bActiveControl = false;
            OnPressurePlateDeactivated.Broadcast();
			HazeAkComp.HazePostEvent(PlateDeactivatedAudioEvent);
        }
    }

	UFUNCTION()
	void UpdateMovePlate(float CurValue)
	{
		FVector CurLoc = FMath::Lerp(TopLocation, FullyPressedOffset, CurValue);
		PlateMesh.SetRelativeLocation(CurLoc);
	}

	UFUNCTION()
	void FinishMovePlate()
	{

	}

	UFUNCTION(BlueprintPure)
	bool IsPressed()
	{
		return bActiveControl;
	}
}