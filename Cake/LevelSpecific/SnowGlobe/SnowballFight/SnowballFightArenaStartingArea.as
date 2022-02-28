
event void FOnSnowballArenaPlayersReadySignature();

class ASnowballFightArenaStartingArea : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UNiagaraComponent AreaEffect;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent TriggerArea;

	bool CodyInPosition = false;
	bool MayInPosition = false;
	bool GameActive = false;

	float StartDelay = 3.f;
	float CurrentTimer = 0.f;

	FOnSnowballArenaPlayersReadySignature PlayersReadyEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TriggerArea.OnComponentBeginOverlap.AddUFunction(this, n"OnTriggerAreaOverlap");
		TriggerArea.OnComponentEndOverlap.AddUFunction(this, n"OnTriggerAreaEndOverlap");
	}

	UFUNCTION()
	void OnTriggerAreaOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
		UPrimitiveComponent OtherComponent, int OtherBodyIndex,
		bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
		{
			if(Player.IsCody())
				CodyInPosition = true;
			else
				MayInPosition = true;
		}
	}

	UFUNCTION()
	void OnTriggerAreaEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(Player != nullptr)
		{
			if(Player.IsCody())
				CodyInPosition = false;
			else
				MayInPosition = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(GameActive || !HasControl())
			return;

		if(CodyInPosition && MayInPosition)
		{
			CurrentTimer += DeltaTime;

			if(CurrentTimer >= StartDelay)
			{
				PlayersReadyEvent.Broadcast();
			}
		}
		else
		{
			CurrentTimer = 0.f;
		}
	}

	UFUNCTION(NetFunction)
	void ToggleVFX(bool Activate)
	{
		if(Activate)
			AreaEffect.Activate();
		else
			AreaEffect.Deactivate();
	}
}