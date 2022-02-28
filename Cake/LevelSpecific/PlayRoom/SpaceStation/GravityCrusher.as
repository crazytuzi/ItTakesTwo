import Peanuts.Audio.AudioStatics;
import Vino.PlayerHealth.PlayerHealthStatics;

class AGravityCrusher : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent LeftCrusherMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent RightCrusherMesh;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent KillTrigger;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ImpactEffectComp;

    UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 6000.f;

    UPROPERTY(Category = "Audio Events")
	UAkAudioEvent TriggerCrushAudioEvent;

	float MaxOffsetFromMiddle = 24.f;

    UPROPERTY()
    FHazeTimeLike CrushTimelike;
    default CrushTimelike.Duration = 2.5f;

	bool bPlayerInKillTrigger = false;
	bool bEffectTriggered = false;

	bool bCanKillPlayer = true;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        CrushTimelike.BindUpdate(this, n"UpdateCrush");
        CrushTimelike.BindFinished(this, n"FinishCrush");

		KillTrigger.OnComponentBeginOverlap.AddUFunction(this, n"CrushPlayer");
		KillTrigger.OnComponentEndOverlap.AddUFunction(this, n"UncrushPlayer");
    }

	UFUNCTION(NotBlueprintCallable)
	void CrushPlayer(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		bPlayerInKillTrigger = true;
	}

	UFUNCTION(NotBlueprintCallable)
    void UncrushPlayer(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		bPlayerInKillTrigger = false;
    }

    UFUNCTION()
    void TriggerCrush()
    {
		bEffectTriggered = false;
		bCanKillPlayer = true;
        CrushTimelike.PlayFromStart();
        HazeAkComp.HazePostEvent(TriggerCrushAudioEvent);
    }
    
    UFUNCTION()
    void UpdateCrush(float Value)
    {
        FVector CurLoc = FMath::Lerp(FVector(MaxOffsetFromMiddle, 0.f, 0.f), FVector::ZeroVector, Value);
        LeftCrusherMesh.SetRelativeLocation(CurLoc);
		RightCrusherMesh.SetRelativeLocation(-CurLoc);

		if (Value >= 0.5f)
			bCanKillPlayer = false;

		if (bPlayerInKillTrigger && bCanKillPlayer)
		{
			Game::GetCody().KillPlayer();
			bPlayerInKillTrigger = false;
		}

		if (!bEffectTriggered && Value == 1.f)
		{
			bEffectTriggered = true;
			ImpactEffectComp.Activate(true);
		}
    }

    UFUNCTION()
    void FinishCrush()
    {
		TriggerCrush();
    }

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		LeftCrusherMesh.SetRelativeLocation(FVector(MaxOffsetFromMiddle, 0.f, 0.f));
		RightCrusherMesh.SetRelativeLocation(FVector(-MaxOffsetFromMiddle, 0.f, 0.f));
    }
}