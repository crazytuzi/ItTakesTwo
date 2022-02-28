import Cake.LevelSpecific.Music.Cymbal.CymbalImpactComponent;
import Peanuts.Aiming.AutoAimTarget;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Music.Singing.SongOfLife.SongOfLifeComponent;

class ASilentRoomMurderMicrophone : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// USphereComponent AttackOnSightRadius;

	UPROPERTY(DefaultComponent, Attach = Root)
	USphereComponent AttackOnSongRadius;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MicMeshRoot;

	UPROPERTY(DefaultComponent, Attach = MicMeshRoot)
	UStaticMeshComponent MicMesh;

	UPROPERTY(DefaultComponent, Attach = MicMesh)
	UCapsuleComponent KillCollision;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MicConnectorRoot;

	UPROPERTY(DefaultComponent, Attach = MicConnectorRoot)
	UStaticMeshComponent MicConnectorMesh;

	UPROPERTY(DefaultComponent, Attach = MicConnectorRoot)
	UHazeCableComponent CableComp;

	UPROPERTY(DefaultComponent)
	UAutoAimTargetComponent AutoAimComp;

	UPROPERTY(DefaultComponent)
	UCymbalImpactComponent CymbalImpactComp;

	UPROPERTY(DefaultComponent)
	USongOfLifeComponent SongOfLifeComp;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	UPROPERTY()
	float MicMoveSpeed = 500.f;

	UPROPERTY()
	TSubclassOf<AHazeActor> DummyMicrophoneToSpawn;

	FVector StartingLoc;
	FRotator StartingRot;

	AHazePlayerCharacter PlayerToChase;

	bool bCanBeKilled = false;
	bool bMayIsSinging = false;
	bool bMicIsDead = false;
	bool bMayWasFound = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CymbalImpactComp.OnCymbalHit.AddUFunction(this, n"CymbalImpact");

		KillCollision.OnComponentBeginOverlap.AddUFunction(this, n"KillCollisionOverlap");

		SongOfLifeComp.OnStartAffectedBySongOfLife.AddUFunction(this, n"StartSongOfLife");
		SongOfLifeComp.OnStopAffectedBySongOfLife.AddUFunction(this, n"StopSongOfLife");

		StartingLoc = MicMeshRoot.WorldLocation;
		StartingRot = MicMeshRoot.WorldRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bMicIsDead)
			return;
		
		if (bMayIsSinging)
		{
			TArray<AActor> IgnoreActors;
			FHitResult Hit;
			FVector StartLoc = GetActorLocation();
			FVector TargetLoc = Game::GetMay().GetActorLocation() + FVector(0.f, 0.f, 50.f);
			System::LineTraceSingle(StartLoc, TargetLoc, ETraceTypeQuery::Camera, false, IgnoreActors, EDrawDebugTrace::None, Hit, true);
	
			if(!Hit.bBlockingHit)
			{
				bMayWasFound = true;
				PlayerToChase = Game::GetMay();
			} else 
			{
				bMayWasFound = false;
			}
		}  
		
		if (!bMayWasFound || !bMayIsSinging)
		{
			{
				// TArray<AActor> OverlappingActors;
				// AttackOnSightRadius.GetOverlappingActors(OverlappingActors);
				
				TArray<EObjectTypeQuery> ObjectTypes;
				TSubclassOf<AActor> ActorClass;
				TArray<AActor> ActorsToIgnore;
				TArray<AActor> OverlappingActors;
				System::SphereOverlapActors(GetActorLocation() + FVector(0.f, 0.f, -700.f), 1540.f, ObjectTypes, ActorClass, ActorsToIgnore, OverlappingActors);

				if (!OverlappingActors.Contains(PlayerToChase))
				{
					AHazePlayerCharacter Player;
					for (AActor Actor : OverlappingActors)
					{
						Player = Cast<AHazePlayerCharacter>(Actor);
						if (Player != nullptr)
						{
							TArray<AActor> IgnoreActors;
							FHitResult Hit;
							FVector StartLoc = GetActorLocation();
							FVector TargetLoc = Player.GetActorLocation() + FVector(0.f, 0.f, 50.f);
							System::LineTraceSingle(StartLoc, TargetLoc, ETraceTypeQuery::Camera, false, IgnoreActors, EDrawDebugTrace::None, Hit, true);

							if (!Hit.bBlockingHit)
							{
								PlayerToChase = Player;
								return;
							}
						}
					}

					PlayerToChase = nullptr;
				}
			}
		} 
			
		if (PlayerToChase != nullptr)
		{
			FVector LocationDelta;
			LocationDelta = PlayerToChase.GetActorLocation() - MicMeshRoot.WorldLocation;
			LocationDelta.Normalize();

			MicMeshRoot.AddWorldOffset(LocationDelta * MicMoveSpeed * DeltaTime);
			MicMeshRoot.SetWorldRotation(FMath::RInterpTo(MicMeshRoot.GetWorldRotation(), LocationDelta.ToOrientationRotator(), DeltaTime, 2.f));
		} else 
		{
			MicMeshRoot.SetWorldLocation(FMath::VInterpTo(MicMeshRoot.GetWorldLocation(), StartingLoc, DeltaTime, 2.f));
			MicMeshRoot.SetWorldRotation(FMath::RInterpTo(MicMeshRoot.GetWorldRotation(), StartingRot, DeltaTime, 2.f));
		}
	}
	
	UFUNCTION()
	void CymbalImpact(FCymbalHitInfo HitInfo)
	{		
		if (HitInfo.HitComponent == MicConnectorMesh)
		{
			bMicIsDead = true;
			SpawnActor(DummyMicrophoneToSpawn, MicMesh.WorldLocation, MicMesh.WorldRotation, n"");
			DestroyActor();
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void StartSongOfLife(FSongOfLifeInfo Info)
	{
		bMayIsSinging = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void StopSongOfLife(FSongOfLifeInfo Info)
	{
		bMayIsSinging = false;
	}

	UFUNCTION()
	void KillCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

		if (Player == nullptr)
			return;

		KillPlayer(Player, DeathEffect);
	}
}