import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateCannonBallActor;

event void FOnPirateCannonBallLaunched(FVector LaunchLocation, FRotator LaunchRotation, APirateCannonBallActor  CannonBall);  // ADD REF TO CANNONBALL??

class UShootPirateCannonBallsComponent : UActorComponent
{
	UPROPERTY(Category = "Properties")
	TSubclassOf<APirateCannonBallActor> CannonBallClass;

	UPROPERTY()
    FOnPirateCannonBallLaunched OnCannonBallsLaunched;

	UPROPERTY(Category = "Properties")
	EPirateCannonBallShootPattern ShootPattern = EPirateCannonBallShootPattern::Random;

	UPROPERTY(Category = "Properties")
	bool bRandomizeLaunchDelay = false;

	UPROPERTY(Category = "Properties")
    float LaunchDelay = 1.f;
	UPROPERTY(Category = "Properties")
    float MinLaunchDelay = 1.f;
	UPROPERTY(Category = "Properties")
    float MaxLaunchDelay = 3.f;

	UPROPERTY(Category = "Properties")
	float AttackSequencePause = 3.f;
	
	UPROPERTY(Category = "Properties")
	int AmountOfContainedCannonBalls = 4;

	UPROPERTY(Category = "Properties")
	int AmountOfCannonBallsToShoot = 1;

	UPROPERTY(Category = "Properties")
    float BetweenCannonBallsDelay = 1.0f;

	UPROPERTY(Category = "Properties")
	float MaxTargetOffsetDistance = 1000.0f;

	UPROPERTY(Category = "Properties")
	UNiagaraSystem FireEffect;

	UPROPERTY(EditDefaultsOnly)
	UGoldbergVOBank VOBank;
	default VOBank = Asset("/Game/Blueprints/LevelSpecific/PlayRoom/VOBanks/GoldbergVOBank.GoldbergVOBank");

	UPROPERTY(NotEditable)
	TArray<APirateCannonBallActor> CannonBallContainer;

	UPROPERTY()
	FVector SpawnEffectLocationOffset = FVector::ZeroVector;

	USceneComponent SpawnLocationComponent;

	bool bShooting;

	void SpawnCannonBalls()
	{
		if(CannonBallContainer.Num() <= 0)
		{
			for(int i = 0; i < AmountOfContainedCannonBalls; i++)
			{
				APirateCannonBallActor CannonBall = Cast<APirateCannonBallActor>(SpawnActor(CannonBallClass, Level = Owner.GetLevel(), bDeferredSpawn = true));
				CannonBallContainer.Add(CannonBall);
				CannonBall.MakeNetworked(Owner, i);
				CannonBall.SetControlSide(Owner);
				CannonBall.TraceIgnoreActors.Add(Owner);

				if(Owner.AttachParentActor != nullptr)
					CannonBall.TraceIgnoreActors.Add(Owner.AttachParentActor);

				FinishSpawningActor(CannonBall);
				CannonBall.Initialize(Owner);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		for(APirateCannonBallActor CannonBall : CannonBallContainer)
		{
			if(CannonBall != nullptr)
			{
				CannonBall.DestroyCannonBall();	
			}
		}

		CannonBallContainer.Empty();
	}

	void SetupExplosionEvent(UObject Instigator, FName FunctionName)
	{
		for(APirateCannonBallActor CannonBall : CannonBallContainer)
		{
			if(CannonBall != nullptr)
			{
				CannonBall.OnCannonBallExploded.AddUFunction(Instigator, FunctionName);
			}
		}
	}

	UFUNCTION()
	float GetRandomizedLaunchDelay()
	{
		float NewLaunch = FMath::RandRange(MinLaunchDelay, MaxLaunchDelay);
		LaunchDelay = NewLaunch;
		return LaunchDelay;
	}
};

enum EPirateCannonBallShootPattern
{
    Random, 
	Line,
};