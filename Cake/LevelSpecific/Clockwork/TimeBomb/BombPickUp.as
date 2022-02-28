import Vino.Pickups.PickupActor;

class ABombPickUp : APickupActor
{
	UPROPERTY(DefaultComponent)
	UNiagaraComponent PuffSystem;

	FVector BombStartLoc;

	float NewTime;
	float Rate = 1.f;

	bool bDONT;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		PuffSystem.SetActive(false);
		OnPutDownEvent.AddUFunction(this, n"Disappear");
		BombStartLoc = ActorLocation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (NewTime <= System::GameTimeInSeconds)
		{
			if (!bDONT)
			{
				ResetBomb();
				bDONT = true;
			}
		}
	}

	UFUNCTION()
	void Disappear(AHazePlayerCharacter PlayerCharacter, APickupActor PickupActor)
	{
		PuffSystem.SetActive(true);
		PuffSystem.Activate(true);
		Mesh.SetHiddenInGame(true);
		NewTime = System::GameTimeInSeconds + Rate;
		bDONT = false;
	}

	UFUNCTION()
	void DisappearFromManager()
	{
		PuffSystem.SetActive(true);
		PuffSystem.Activate(true);
		Mesh.SetHiddenInGame(true);
	}

	UFUNCTION()
	void ResetBomb()
	{
		ActorLocation = BombStartLoc;
		PuffSystem.Activate(true);
		Mesh.SetHiddenInGame(false); 
		System::SetTimer(this, n"SetPuffInactive", 1.f, false);
	}

	UFUNCTION()
	void SetPuffInactive()
	{
		PuffSystem.SetActive(false);
	}
}