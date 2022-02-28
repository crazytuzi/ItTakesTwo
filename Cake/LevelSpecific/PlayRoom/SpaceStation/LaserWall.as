import Vino.PlayerHealth.PlayerHealthStatics;

event void FLaserWallEvent(AHazePlayerCharacter Player);

class ALaserWall : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent LaserWallMesh;
    default LaserWallMesh.CollisionProfileName = n"PlayerCharacterOverlapOnly";

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 6000.f;

    UPROPERTY(EditDefaultsOnly)
    TSubclassOf<UPlayerDeathEffect> DeathEffect;

	bool bActive = true;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartLaserWallLoopingEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopLaserWallLoopingEvent;

	UPROPERTY()
	FLaserWallEvent OnKilledByLaserWall;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        LaserWallMesh.OnComponentBeginOverlap.AddUFunction(this, n"KilledByLaser");

		ActivateLaserWall();
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
		FVector OutMayPos;
		FVector OutCodyPos;

		LaserWallMesh.GetClosestPointOnCollision(Game::GetMay().GetActorLocation(), OutMayPos);
		LaserWallMesh.GetClosestPointOnCollision(Game::GetCody().GetActorLocation(), OutCodyPos);

		TArray<FTransform> EmitterPositions;

		EmitterPositions.Add(FTransform(OutMayPos));
		EmitterPositions.Add(FTransform(OutCodyPos));

		HazeAkComp.HazeSetMultiplePositions(EmitterPositions);
    }

    UFUNCTION()
    void KilledByLaser(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

        if (Player != nullptr)
        {
			if (Player.HasControl())
			{
				NetPlayerKilled(Player);
			}
        }
    }

	UFUNCTION(NetFunction)
	void NetPlayerKilled(AHazePlayerCharacter Player)
	{
		KillPlayer(Player, DeathEffect);
		OnKilledByLaserWall.Broadcast(Player);
	}

	UFUNCTION()
	void ActivateLaserWall()
	{
		bActive = true;
		SetActorEnableCollision(true);
		SetActorHiddenInGame(false);

		if(StartLaserWallLoopingEvent != nullptr)
		{			
			HazeAkComp.HazePostEvent(StartLaserWallLoopingEvent);
		}
	}

	UFUNCTION()
	void DeactivateLaserWall()
	{
		bActive = false;
		SetActorEnableCollision(false);
		SetActorHiddenInGame(true);

		if(StopLaserWallLoopingEvent != nullptr)
		{
			HazeAkComp.HazePostEvent(StopLaserWallLoopingEvent);
		}
	}
}