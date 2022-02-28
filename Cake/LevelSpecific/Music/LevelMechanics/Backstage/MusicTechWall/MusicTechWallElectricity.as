import Vino.PlayerHealth.PlayerHealthStatics;

class AMusicTechWallElectricity : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent ElectricityFX;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ActivateElectricityAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DeactivateElectricityAudioEvent;

	UPROPERTY()
	bool bAlwaysOn = false;

	UPROPERTY()
	float OnDuration = 1.5f;

	UPROPERTY()
	float OffDuration = 3.f; 

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	TArray<AHazePlayerCharacter> PlayerArray;

	float OnDurationDefault = 0.f;
	float OffDurationDefault = 0.f;

	bool bIsOn = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnDurationDefault = OnDuration;
		OffDurationDefault  = OffDuration;

		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"BoxOnOverlap");
		BoxCollision.OnComponentEndOverlap.AddUFunction(this, n"BoxOnEndOverlap");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bAlwaysOn)
		{
			bIsOn = true;
			return;
		}

		if (OnDuration > 0.f)
		{
			OnDuration -= DeltaTime;
			if (!bIsOn)
			{
				bIsOn = true;
				OffDuration = OffDurationDefault;
				TurnedOn(true);
			}
		} else if (OffDuration > 0.f)
		{
			OffDuration -= DeltaTime; 
			if (bIsOn)
			{
				bIsOn = false;
				TurnedOn(false);
			}
		} else
		{
			OnDuration = OnDurationDefault;
		} 
	}

	void TurnedOn(bool bOn)
	{
		if (bOn)
		{
			ElectricityFX.Activate();
			HazeAkComp.HazePostEvent(ActivateElectricityAudioEvent);
			if (PlayerArray.Num() > 0)
			{
				for (AHazePlayerCharacter Player : PlayerArray)
				{
					KillPlayer(Player, DeathEffect);
				}
			}
		}
		else
		{
			ElectricityFX.Deactivate();
			HazeAkComp.HazePostEvent(DeactivateElectricityAudioEvent);
		}
	}

	UFUNCTION()
	void BoxOnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if (bIsOn)
		{
			KillPlayer(Player, DeathEffect);
			return;
		}

		PlayerArray.AddUnique(Player);
	}

	UFUNCTION()
	void BoxOnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		PlayerArray.Remove(Player);
	}
}