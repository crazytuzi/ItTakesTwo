event void FOnSetTimeDelegate(ATriggerableFX TriggerableFX, float NewTime);

class ATriggerableFX : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	UPROPERTY(DefaultComponent, RootComponent)
	UNiagaraComponent NiagaraComponent;
	default NiagaraComponent.bAutoActivate = false;

	UPROPERTY(DefaultComponent, Attach = Root)
	UArrowComponent Arrow;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DestructionEvent;
	
	
	UPROPERTY(Category = "zzInternal")
	float AngelscriptDelay;

	FOnSetTimeDelegate OnSetTime;

	UFUNCTION(BlueprintEvent, BlueprintCallable)
	void TriggerFX()
	{
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable, CallInEditor)
	void PreviewFX()
	{
	}
	
	UFUNCTION()
	void SetReversableEffectTime(float Time)
	{
		NiagaraComponent.SetNiagaraVariableFloat("User.Time", FMath::Max(Time - AngelscriptDelay, 0.001f));

		// TODO: Audio?
		OnSetTime.Broadcast(this, Time);
	}
}

UFUNCTION()
TArray<ATriggerableFX> GetAllTriggerableEffects(AActor InOwner)
{
	TArray<ATriggerableFX> Result = TArray<ATriggerableFX>();
	TArray<AActor> AllChildActors;
	InOwner.GetAttachedActors(AllChildActors);
	for(int i = 0; i < AllChildActors.Num(); i++)
	{
		ATriggerableFX FXSpawner = Cast<ATriggerableFX>(AllChildActors[i]);
		if(FXSpawner != nullptr)
		{
			Result.Add(FXSpawner);
		}
	}

	return Result;
}