class ASnowFallOffRoof : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent) 
	UNiagaraComponent NiagaraSnowFallSystem;
	default NiagaraSnowFallSystem.SetAutoActivate(false);

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;
	default DisableComp.AutoDisableRange = 8000.f;

	FHazeMinMax MinMax = FHazeMinMax(5.f, 8.f);

	float Timer;
	float MaxTimeToDeactive = 1.5f;
	float TimeToDeactive;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		Timer -= DeltaTime;

		if (Timer <= 0.f)
		{
			if (!NiagaraSnowFallSystem.IsActive())
				NiagaraSnowFallSystem.Activate();

			TimeToDeactive -= DeltaTime;

			if (TimeToDeactive <= 0.f)
			{
				Timer = MinMax.GetRandomValue();
				TimeToDeactive = MaxTimeToDeactive;
				
				if (NiagaraSnowFallSystem.IsActive())
					NiagaraSnowFallSystem.Deactivate();
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	bool OnActorDisabled()
	{
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActorEnabled()
	{
		Timer = MinMax.GetRandomValue();
		TimeToDeactive = MaxTimeToDeactive;
	}
}