import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Clockwork.VOBanks.ClockworkClockTowerUpperVOBank;

event void FClockworkLastBossPendulumSignature();

class AClockworkLastBossPendulum : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent Mesh;
	default Mesh.bHiddenInGame = true;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UBoxComponent BoxCollision;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UNiagaraComponent SparksFX;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent SparksCollision;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent PendulumHazeAkComp;

	UPROPERTY()
	int PendulumIndex = 0;

	UPROPERTY()
	FClockworkLastBossPendulumSignature PendulumLeftPlatform;

	UPROPERTY()
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	FHazeTimeLike SwingPendulumTimeline;
	default SwingPendulumTimeline.Duration = 4.f;

	FRotator StartingRot;
	FRotator TargetRot;

	bool bReverseMappedRange = false;

	bool bHasBeenSwung = false;
	bool bPlayingForward = false;

	UPROPERTY()
	UClockworkClockTowerUpperVOBank VoBank;

	bool bShouldTriggerVO = false;
	bool bHasTriggeredVO = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SwingPendulumTimeline.BindUpdate(this, n"SwingPendulumTimelineUpdate");
		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"DeathCollisionBeginOverlap");
		SparksCollision.OnComponentBeginOverlap.AddUFunction(this, n"TriggeredOnBeginOverlap");
		SparksCollision.OnComponentEndOverlap.AddUFunction(this, n"TriggeredOnEndOverlap");

		StartingRot = MeshRoot.RelativeRotation;
		TargetRot = StartingRot + FRotator(180.f, 0.f, 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
	
	}

	UFUNCTION()
	void SwingPendulum()
	{
		if (Mesh.bHiddenInGame)
			Mesh.SetHiddenInGame(false);

		if (bHasBeenSwung)
		{
			bHasBeenSwung = false;
			bPlayingForward = true;
			SwingPendulumTimeline.PlayFromStart();
		}
		else
		{
			bHasBeenSwung = true;
			bPlayingForward = false;
			SwingPendulumTimeline.ReverseFromEnd();
		}
	}

	UFUNCTION()
	void SetPendulumSwingRotation()
	{
		if (bHasBeenSwung)
		{
			bHasBeenSwung = false;
			MeshRoot.SetRelativeRotation(TargetRot);
		}
		else
		{
			bHasBeenSwung = true;
			MeshRoot.SetRelativeRotation(StartingRot);	
		}
	}

	UFUNCTION()
	void SwingPendulumTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeRotation(FMath::LerpShortestPath(StartingRot, TargetRot, CurrentValue));

		if (bShouldTriggerVO)
		{
			if (bCanTriggerVO(CurrentValue))
			{
				bHasTriggeredVO = true;
				bShouldTriggerVO = false;
				FVector CodyDelta = Game::GetCody().ActorLocation - ActorLocation;
				CodyDelta = CodyDelta.ConstrainToPlane(FVector::UpVector);
				if (CodyDelta.Size() <= 500.f)
					PlayFoghornVOBankEvent(VoBank, n"FoghornSBClockworkUpperTowerClockBossPendulumGenericCody");

				FVector MayDelta = Game::GetMay().ActorLocation - ActorLocation;
				MayDelta = MayDelta.ConstrainToPlane(FVector::UpVector);
				if (MayDelta.Size() <= 500.f)
					PlayFoghornVOBankEvent(VoBank, n"FoghornSBClockworkUpperTowerClockBossPendulumGenericMay");
			}
		}
	}

	bool bCanTriggerVO(float CurrentValue)
	{
		if (bPlayingForward)
		{
			if (CurrentValue >= 0.5f && !bHasTriggeredVO)
				return true;
		} 
		else
		{	
			if (CurrentValue <= 0.5f && !bHasTriggeredVO)
				return true;
		} 

		return false;
	}

	UFUNCTION()
	void DeathCollisionBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		{
			if (Player != nullptr)
			{
				DamagePlayerHealth(Player, 1.f, DamageEffect);
			}
		}
	}

	UFUNCTION()
    void TriggeredOnBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
    {
		AClockworkLastBossPendulum Pendulum = Cast<AClockworkLastBossPendulum>(OtherActor);

		if (Pendulum != nullptr)
		{
			SparksFX.Activate();
		}
    }

	UFUNCTION()
	void TriggeredOnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AClockworkLastBossPendulum Pendulum = Cast<AClockworkLastBossPendulum>(OtherActor);

		if (Pendulum != nullptr)
		{
			SparksFX.Deactivate();
			PendulumLeftPlatform.Broadcast();

			if (bReverseMappedRange)
				bReverseMappedRange = false;
			else
				bReverseMappedRange = true;
		}
	}

	void SetPendulumToVoTrigger()
	{
		bShouldTriggerVO = true;
		bHasTriggeredVO = false;
	}
}