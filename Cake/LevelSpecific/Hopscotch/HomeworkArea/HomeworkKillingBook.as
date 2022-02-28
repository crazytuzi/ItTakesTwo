import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkChallenge;
import Peanuts.Triggers.PlayerTrigger;
import Cake.LevelSpecific.Hopscotch.HomeworkArea.HomeworkPen;

class AHomeworkKillingBook : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent BookMesh;
	default BookMesh.bHiddenInGame = true;
	default BookMesh.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = BookMesh)
	UBoxComponent DeathCollision;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MoveKillingBookAudioEvent;

	UPROPERTY()
	UNiagaraSystem SlamVFX;
	default SlamVFX = Asset("/Game/Effects/Niagara/GameplayBookSlam_01.GameplayBookSlam_01");

	UPROPERTY()
	FHazeTimeLike MoveBookTimeline;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY()
	AHomeworkChallenge ConnectedChallenge;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	UPROPERTY()
	APlayerTrigger ConnectedTrigger;

	UPROPERTY()
	TArray<UStaticMesh> MeshArray;

	UPROPERTY()
	TArray<UMaterialInterface> MatArray;

	bool bHasPlayedCamShake = false;

	FVector StartLocation = FVector::ZeroVector;
	FVector TargetLocation = FVector(0.f, 0.f, -2000.f);

	bool bKillingCollisionEnabled = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveBookTimeline.BindUpdate(this, n"MoveBookTimelineUpdate");
		MoveBookTimeline.BindFinished(this, n"MoveBookTimelineFinished");
		DeathCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnDeathCompOverlap");
		
		if (ConnectedChallenge != nullptr)
			ConnectedChallenge.ChallengeFailed.AddUFunction(this, n"ChallengeFailed");

		if (ConnectedTrigger != nullptr)
			ConnectedTrigger.OnPlayerEnter.AddUFunction(this, n"OnPlayerEnter");
	}

	UFUNCTION()
	void StartMovingBook()
	{
		BookMesh.SetHiddenInGame(false);
		bKillingCollisionEnabled = true;
		MoveBookTimeline.PlayFromStart();

		SetRandomMeshAndMaterial();

		UHazeAkComponent::HazePostEventFireForget(MoveKillingBookAudioEvent, this.GetActorTransform());
	}
	
	UFUNCTION()
	void OnDeathCompOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player != nullptr && bKillingCollisionEnabled) 
		{
			KillPlayer(Player, DeathEffect);
			UNiagaraComponent NiagaraComponent = Niagara::SpawnSystemAtLocation(SlamVFX, BookMesh.WorldLocation);
		}	

		AHomeworkPen Pen = Cast<AHomeworkPen>(OtherActor);
		if (Pen != nullptr && Pen.bIsResetting)
		{
			Pen.SetActorLocation(Pen.StartingLoc);
			Pen.SetActorHiddenInGame(true);
			Pen.SetPenCollisionEnabled(false);
			Pen.DecalTrail.ClearTrailImmediate();
			Pen.SetTrailActive(false);
		}
	}

	UFUNCTION()
	void MoveBookTimelineUpdate(float CurrentValue)
	{
		MeshRoot.SetRelativeLocation(FMath::Lerp(StartLocation, TargetLocation, CurrentValue));

		if (CurrentValue > 0.5 && !bHasPlayedCamShake)
		{
			bHasPlayedCamShake = true;
			Game::GetMay().PlayCameraShake(CamShake);
		}
	}

	UFUNCTION()
	void MoveBookTimelineFinished(float CurrentValue)
	{
		BookMesh.SetHiddenInGame(true);
		bKillingCollisionEnabled = false;
		bHasPlayedCamShake = false;
	}

	UFUNCTION()
	void ChallengeFailed(AHomeworkChallenge Challenge)
	{
		StartMovingBook();
	}

	UFUNCTION()
	void OnPlayerEnter(AHazePlayerCharacter Player)
	{
		StartMovingBook();
	}

	UFUNCTION()
	void SetRandomMeshAndMaterial()
	{
		BookMesh.SetStaticMesh(MeshArray[FMath::RandRange(0, MeshArray.Num() - 1)]);
		BookMesh.SetMaterial(0, MatArray[FMath::RandRange(0, MatArray.Num() - 1)]);
	}
}