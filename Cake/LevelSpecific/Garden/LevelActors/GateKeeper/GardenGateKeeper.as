import Cake.LevelSpecific.Garden.LevelActors.GateKeeper.GardenGateKeeperLever;
import Cake.LevelSpecific.Garden.LevelActors.GateKeeper.GardenGateKeeperGate;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;

UCLASS(Abstract)
class AGardenGateKeeper : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UStaticMeshComponent GateKeeperMesh;

	UPROPERTY(DefaultComponent)
	USphereComponent TomatoTrigger;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveToTomatoTimeLike;
	default MoveToTomatoTimeLike.Duration = 0.25f;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem TomatoExplosionEffect;

	UPROPERTY()
	AGardenGateKeeperLever TargetLever;

	UPROPERTY()
	AGardenGateKeeperGate TargetGate;

	bool bEatingTomato = false;

	FTimerHandle EatTomatoTimerHandle;
	
	FVector DefaultLocation;
	FVector TomatoLocation;
	FRotator DefaultRotation;

	ATomato CurrentTomato;

	float TomatoExplosionTime = 0.f;
	float TomatoExplosionThreshold = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TomatoTrigger.OnComponentBeginOverlap.AddUFunction(this, n"TomatoEntered");

		MoveToTomatoTimeLike.BindUpdate(this, n"UpdateMoveToTomato");
		MoveToTomatoTimeLike.BindFinished(this, n"FinishMoveToTomato");

		DefaultLocation = ActorLocation;
		DefaultRotation = ActorRotation;
	}

	UFUNCTION()
	void UpdateMoveToTomato(float CurValue)
	{
		FVector CurDir = (TomatoLocation - DefaultLocation).GetSafeNormal();
		FVector CurLoc = FMath::Lerp(DefaultLocation, TomatoLocation - (CurDir * 800.f), CurValue);
		FRotator CurRot = FMath::LerpShortestPath(DefaultRotation, CurDir.Rotation(), CurValue);
		FRotator CurMeshRot = FMath::LerpShortestPath(FRotator::ZeroRotator, FRotator(-60.f, 0.f, 0.f), CurValue);

		SetActorLocation(CurLoc);
		SetActorRotation(CurRot);
		GateKeeperMesh.SetRelativeRotation(CurMeshRot);
	}

	UFUNCTION()
	void FinishMoveToTomato()
	{
		if (bEatingTomato)
		{
			EatTomatoTimerHandle = System::SetTimer(this, n"TomatoEaten", 3.f, false);
		}
		else
		{
			
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (TargetGate == nullptr)
			return;

		if (bEatingTomato)
		{
			TomatoExplosionTime += DeltaTime;
			if (TomatoExplosionTime >= TomatoExplosionThreshold)
			{
				Niagara::SpawnSystemAtLocation(TomatoExplosionEffect, TomatoLocation);
				TomatoExplosionThreshold += 0.5f;
			}
			return;
		}

		if (TargetGate.bPlayerTooClose && !TargetGate.bGateClosed)
		{
			StartPullingLever();
		}
		else if (!TargetGate.bPlayerTooClose && TargetGate.bGateClosed)
		{
			StopPullingLever();
		}
	}

	UFUNCTION()
	void StartPullingLever()
	{
		TargetLever.ActivateLever();
		TargetGate.CloseGate();
	}

	UFUNCTION()
	void StopPullingLever()
	{
		TargetLever.DeactivateLever();
		TargetGate.OpenGate();
	}

	UFUNCTION(NotBlueprintCallable)
	void TomatoEntered(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		CurrentTomato = Cast<ATomato>(OtherActor);
		if (CurrentTomato == nullptr)
			return;

		TomatoLocation = CurrentTomato.ActorLocation;
		TomatoExplosionThreshold = 0.f;
		TomatoExplosionTime = 0.f;
			
		bEatingTomato = true;
		StopPullingLever();

		MoveToTomatoTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void TomatoEaten()
	{
		bEatingTomato = false;
		MoveToTomatoTimeLike.ReverseFromEnd();
	}
}