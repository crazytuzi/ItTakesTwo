import Vino.PlayerHealth.PlayerHealthStatics;

UCLASS(Abstract)
class AMoonBaboonLaser : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent LaserRoot;

	UPROPERTY(DefaultComponent, Attach = LaserRoot)
	UStaticMeshComponent LaserMesh;

	UPROPERTY()
	bool bActive = true;

	float CurrentLength = 0.f;
	float CurrentRotationSpeed;
	UPROPERTY()
	float RotationSpeed = 20.f;
	UPROPERTY()
	float ScaleSpeed = 15.f;
	

	UPROPERTY()
	bool bScaleX = false;
	UPROPERTY()
	bool bScaleY = false;
	UPROPERTY()
	bool bScaleZ = true;

	UPROPERTY()
	bool bRandomlyChangeDirection = false;
	UPROPERTY()
	FVector2D ChangeDirectionInverval = FVector2D(4.5f, 9.f);

	FTimerHandle ChangeDirectionTimer;

	UPROPERTY()
	bool bDamageOverTime = false;

	TArray<AHazePlayerCharacter> DamagedPlayers;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bActive)
		{
			SetActorHiddenInGame(true);
		}

		if (bRandomlyChangeDirection && bActive)
		{
			float ChangeDirTime = FMath::RandRange(ChangeDirectionInverval.Min, ChangeDirectionInverval.Max);
			ChangeDirectionTimer = System::SetTimer(this, n"ChangeDirection", ChangeDirTime, false);
		}

		LaserMesh.OnComponentBeginOverlap.AddUFunction(this, n"EnterLaser");
		LaserMesh.OnComponentEndOverlap.AddUFunction(this, n"LeaveLaser");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		CurrentRotationSpeed = FMath::FInterpTo(CurrentRotationSpeed, RotationSpeed, DeltaTime, 0.75f);
		AddActorWorldRotation(FRotator(0.f, CurrentRotationSpeed * DeltaTime, 0.f));

		if (bActive)
		{
			if (CurrentLength <= 100.f)
			{
				CurrentLength += (ScaleSpeed * DeltaTime);
				float XScale = bScaleX ? CurrentLength : 1.f;
				float YScale = bScaleY ? CurrentLength : 1.f;
				float ZScale = bScaleZ ? CurrentLength : 1.f;
				SetActorScale3D(FVector(XScale, YScale, ZScale));
			}
			
			for (AHazePlayerCharacter CurPlayer : DamagedPlayers)
			{
				CurPlayer.DamagePlayerHealth(0.025f, DamageEffect);
			}
		}
	}

	UFUNCTION()
	void ActivateLaser()
	{
		SetActorHiddenInGame(false);
		bActive = true;
	}

	UFUNCTION()
	void DeactivateLaser()
	{
		StopRandomlyChangingDiretion();
		SetActorHiddenInGame(true);
		bActive = false;
	}

	UFUNCTION()
    void EnterLaser(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

        if (Player != nullptr)
        {
            if (bDamageOverTime)
				DamagedPlayers.AddUnique(Player);
			else
				Player.DamagePlayerHealth(0.1f, DamageEffect);
        }
    }

    UFUNCTION()
    void LeaveLaser(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

        if (Player != nullptr)
        {
            if (bDamageOverTime)
				DamagedPlayers.Remove(Player);
        }
    }

	UFUNCTION()
	void ChangeDirection()
	{
		RotationSpeed *= -1.f;
		float ChangeDirTime = FMath::RandRange(ChangeDirectionInverval.Min, ChangeDirectionInverval.Max);
		ChangeDirectionTimer = System::SetTimer(this, n"ChangeDirection", ChangeDirTime, false);
	}

	UFUNCTION()
	void StopRandomlyChangingDiretion()
	{
		System::ClearAndInvalidateTimerHandle(ChangeDirectionTimer);
	}
}