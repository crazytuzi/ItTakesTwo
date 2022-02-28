import Vino.PlayerHealth.PlayerHealthStatics;

class AClockworkLastBossFreeFallCogWheel : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent CogMeshRoot;

	UPROPERTY(DefaultComponent, Attach = CogMeshRoot)
	UStaticMeshComponent CogMesh;

	UPROPERTY(DefaultComponent, Attach = CogMesh)
	UBoxComponent CogKillCollision;
	
	UPROPERTY()
	FHazeTimeLike RotateFrefallCogTimeline;
	default RotateFrefallCogTimeline.Duration = 0.5f;

	UPROPERTY()
	bool bReverseRotation = false;

	UPROPERTY()
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	float CogWheelSpeed = 0.f;
	float SpawnedHeight = 0.f;

	bool bActive = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CogKillCollision.OnComponentBeginOverlap.AddUFunction(this, n"KillCollision");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bActive)
			return;

		CogMesh.AddRelativeRotation(FRotator(0.f, 0.f, 100.f * DeltaTime));
	} 

	UFUNCTION()
	void SetNewCogWheelSpeed(float NewSpeed)
	{
		CogWheelSpeed = NewSpeed;
	}

	UFUNCTION()
	void ActivateCogWheel()
	{
		bActive = true;
	}

	UFUNCTION()
	void KillCollision(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player != nullptr && Player.HasControl())
		{
			NetPlayerHitCog(Player);
		}
	}

	UFUNCTION(NetFunction)
	void NetPlayerHitCog(AHazePlayerCharacter Player)
	{
		Player.DamagePlayerHealth(0.25f, DamageEffect);
		DestroyActor();
	}
}