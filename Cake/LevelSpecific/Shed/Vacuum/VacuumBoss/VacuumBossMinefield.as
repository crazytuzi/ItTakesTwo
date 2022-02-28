import Vino.Trajectory.TrajectoryStatics;
import Vino.Projectile.ProjectileMovement;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Camera.Components.WorldCameraShakeComponent;

event void FVacuumBossMinefieldDestroyedEvent(AVacuumBossMinefield Minefield);
event void FVacuumBossMinefieldFullyLaunchedEvent(AVacuumBossMinefield Minefield, bool bLeft);

UCLASS(Abstract)
class AVacuumBossMinefield : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UArrowComponent DirectionArrow;
	default DirectionArrow.ArrowSize = 5.f;

	UPROPERTY(DefaultComponent)
	UForceFeedbackComponent ForceFeedbackComp;

	UPROPERTY(DefaultComponent)
	UWorldCameraShakeComponent CameraShakeComp;
	
	UPROPERTY(DefaultComponent)
	UHazeAkComponent MineFieldLandHazeAkComp;
	
	UPROPERTY(DefaultComponent)
	UHazeAkComponent MineFieldExplodeHazeAkComp;

	FVector Extents = FVector(300.f, 2400.f, 5.f);

	UPROPERTY()
	UStaticMesh MineMesh;

	UPROPERTY(NotEditable)
	TArray<UStaticMeshComponent> Mines;
	TArray<UStaticMeshComponent> AvailableMines;
	TArray<UStaticMeshComponent> FiredMines;
	TArray<FProjectileMovementData> MovementDatas;
	TArray<FVector> StartPositions;

	UPROPERTY()
	int Rows = 16;

	UPROPERTY()
	int Columns = 3;

	UPROPERTY()
	float Width = 300.f;

	UPROPERTY()
	float Height = 315.f;

	FTimerHandle FireMineTimerHandle;
	FTimerHandle ExplodeMineTimerHandle;

	UPROPERTY()
	FVacuumBossMinefieldDestroyedEvent OnMinefieldDestroyed;

	UPROPERTY()
	FVacuumBossMinefieldFullyLaunchedEvent OnAllMinesLaunched;

	float MineVerticalOffset = 22.f;

	UHazeSkeletalMeshComponentBase CurrentBossMesh;

	UPROPERTY()
	bool bLeft = true;
	FName SpawnSocket;

	float DelayUntilExplosion = 4.5f;

	int ExplodedMineIndex = 0;
	int ExplosionEffectIndex = 0;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem BigExplosionSystem;

	UPROPERTY(EditDefaultsOnly)
	UNiagaraSystem FuseSystem;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UPlayerDamageEffect> DamageEffect;

	bool bAllMinesLanded = false;
	bool bCanStartMinesLandingAudio = true;
	bool bCanStartMinesExplodingAudio = true;

	UPROPERTY(NotEditable)
	TArray<UNiagaraComponent> FuseComps;

	UPROPERTY()
	UAkAudioEvent OnStartMinesLandEvent;

	UPROPERTY()
	UAkAudioEvent OnStopMinesLandEvent;

	UPROPERTY()
	UAkAudioEvent OnStartMinesExplodeEvent;

	UPROPERTY()
	UAkAudioEvent OnStopMinesExplodeEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AvailableMines = Mines;

		SpawnSocket = bLeft ? n"LeftHand" : n"RightHand";

		for (UStaticMeshComponent CurMine : Mines)
		{
			StartPositions.Add(CurMine.WorldLocation);
		}

		SetActorTickEnabled(false);
	}

	void SetBossMesh(UHazeSkeletalMeshComponentBase Mesh)
	{
		CurrentBossMesh = Mesh;
	}

	UFUNCTION()
	void FireMines()
	{
		FireMineTimerHandle = System::SetTimer(this, n"FireMine", 0.02f, true);
	}

	void ActivateMinefield()
	{
		SetActorTickEnabled(true);
		ExplodedMineIndex = 0;
		ExplosionEffectIndex = 0;
		AvailableMines = Mines;
		FiredMines.Empty();
		MovementDatas.Empty();
		FireMineTimerHandle = System::SetTimer(this, n"FireMine", 0.02f, true);
		ExplodeMineTimerHandle = System::SetTimer(this, n"ExplodeMine", 0.02f, true, DelayUntilExplosion);
	}

	UFUNCTION(NotBlueprintCallable)
	void FireMine()
	{
		UStaticMeshComponent MineToFire = AvailableMines[0];
		FVector TargetLocation = StartPositions[Mines.FindIndex(MineToFire)];
		FVector StartLoc = CurrentBossMesh.GetSocketLocation(SpawnSocket) + (CurrentBossMesh.GetSocketRotation(SpawnSocket).UpVector * 200.f);
		FVector Velocity = CalculateVelocityForPathWithHeight(StartLoc, TargetLocation, 980.f, 500.f);
		FProjectileMovementData MoveData;
		MoveData.Velocity = Velocity;
		MineToFire.SetWorldLocation(StartLoc);
		MineToFire.SetHiddenInGame(false);
		MovementDatas.Add(MoveData);
		FiredMines.Add(MineToFire);

		AvailableMines.Remove(MineToFire);
		FuseComps[FiredMines.Num() - 1].Activate(true);
		
		if (AvailableMines.Num() == 0)
		{
			System::ClearAndInvalidateTimerHandle(FireMineTimerHandle);
			OnAllMinesLaunched.Broadcast(this, bLeft);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void ExplodeMine()
	{
		UStaticMeshComponent MineToExplode = Mines[ExplodedMineIndex];
		UNiagaraComponent FuseToDeactivate = FuseComps[ExplodedMineIndex];

		if (ExplodedMineIndex >= ExplosionEffectIndex)
		{
			ExplosionEffectIndex += 10;
			Niagara::SpawnSystemAtLocation(BigExplosionSystem, MineToExplode.WorldLocation);
			ForceFeedbackComp.SetWorldLocation(MineToExplode.WorldLocation);
			CameraShakeComp.SetWorldLocation(MineToExplode.WorldLocation);
			ForceFeedbackComp.Play();
			CameraShakeComp.Play();
		}

		for (AHazePlayerCharacter CurPlayer : Game::GetPlayers())
		{
			FVector MidLoc = ActorLocation + (-DirectionArrow.RightVector * Width);
			FVector DistanceToPlayer = MidLoc - CurPlayer.ActorLocation;
			DistanceToPlayer = DistanceToPlayer.ConstrainToDirection(DirectionArrow.RightVector);

			FVector DistanceToMine = MineToExplode.WorldLocation - CurPlayer.ActorLocation;
			DistanceToMine = DistanceToMine.ConstrainToPlane(FVector::UpVector);

			if (DistanceToPlayer.Size() < Width * 2 && DistanceToMine.Size() < Width)
			{
				DamagePlayerHealth(CurPlayer, 0.5f, DamageEffect);
			}
		}

		MineToExplode.SetHiddenInGame(true);
		MineFieldExplodeHazeAkComp.SetWorldLocation(MineToExplode.GetWorldLocation());
		FuseToDeactivate.Deactivate();
		

		if (ExplodedMineIndex >= Mines.Num() - 1)
		{
			System::ClearAndInvalidateTimerHandle(ExplodeMineTimerHandle);
			OnMinefieldDestroyed.Broadcast(this);
			SetActorTickEnabled(false);
			MineFieldExplodeHazeAkComp.HazePostEvent(OnStopMinesExplodeEvent);
		}

		ExplodedMineIndex++;
		if(bCanStartMinesExplodingAudio)
		{
			bCanStartMinesExplodingAudio = false;
			MineFieldExplodeHazeAkComp.HazePostEvent(OnStartMinesExplodeEvent);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		HandleMineMovement(DeltaTime);
	}

	void HandleMineMovement(float DeltaTime)
	{
		if (FiredMines.Num() == 0)
			return;

		for (int Index = FiredMines.Num() - 1; Index >= 0; --Index)
		{
			UStaticMeshComponent CurMine = FiredMines[Index];
			FProjectileUpdateData UpdateData = CalculateProjectileMovement(MovementDatas[Index], DeltaTime * 2.f);
			MovementDatas[Index] = UpdateData.UpdatedMovementData;

			if (CurMine.WorldLocation.Z != ActorLocation.Z + MineVerticalOffset)
			{
				FVector DeltaToAdd = UpdateData.DeltaMovement;
				FVector NewLoc = CurMine.WorldLocation + DeltaToAdd;
				NewLoc.Z = FMath::Clamp(NewLoc.Z, ActorLocation.Z + MineVerticalOffset, ActorLocation.Z + 50000.f);
				CurMine.SetWorldLocation(NewLoc);
				CurMine.AddWorldRotation(FRotator(0.f, 2500.f, 0.f) * DeltaTime);
				if (NewLoc.Z == ActorLocation.Z + MineVerticalOffset)
				{
					MovementDatas.RemoveAt(Index);
					FiredMines.RemoveAt(Index);					
					MineFieldLandHazeAkComp.SetWorldLocation(CurMine.GetWorldLocation());		

					if(bCanStartMinesLandingAudio)
					{
						bCanStartMinesLandingAudio = false;
						MineFieldLandHazeAkComp.HazePostEvent(OnStartMinesLandEvent);
						bCanStartMinesExplodingAudio = true;

					}			
				}	
			}
		}

		if (FiredMines.Num() == 0)
		{
			MineFieldLandHazeAkComp.HazePostEvent(OnStopMinesLandEvent);
			bAllMinesLanded = true;
			bCanStartMinesLandingAudio = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		System::FlushPersistentDebugLines();
		System::DrawDebugBox(ActorLocation + (DirectionArrow.ForwardVector * Extents.Y) + (-DirectionArrow.RightVector * Extents.X), Extents, FLinearColor::DPink, FRotator::ZeroRotator, 5.f, 10.f);

		Mines.Empty();
		FuseComps.Empty();

		for (int HeightIndex = 0; HeightIndex < Rows; ++ HeightIndex)
		{
			for (int Index = 0; Index < Columns; ++ Index)
			{
				FVector Loc = ActorLocation + DirectionArrow.ForwardVector * (Height * HeightIndex);
				Loc += DirectionArrow.ForwardVector * 100.f;
				Loc += -DirectionArrow.RightVector * (Width * Index);
				if (Index == 0)
					Loc += -DirectionArrow.RightVector * 80.f;
				if (Index == Columns - 1)
					Loc += DirectionArrow.RightVector * 80.f;
				float RandomXOffset = FMath::RandRange(-15.f, 15.f);
				float RandomYOffset = FMath::RandRange(-15.f, 15.f);
				Loc += FVector(RandomXOffset, RandomYOffset, 23.f);

				TArray<AActor> ActorsToIgnore;
				FHitResult Hit;
				System::LineTraceSingle(Loc, Loc - FVector(0.f, 0.f, 250.f), ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::ForDuration, Hit, true);
				if (!Hit.bBlockingHit)
					continue;

				UStaticMeshComponent CurMine = UStaticMeshComponent::Create(this);
				CurMine.SetStaticMesh(MineMesh);
				CurMine.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				CurMine.SetHiddenInGame(true);
				CurMine.SetCastShadow(false);
				CurMine.SetWorldLocation(Loc);
				float Pitch = FMath::RandRange(-10.f, 10.f);
				CurMine.SetWorldRotation(FRotator(Pitch, 0.f, 0.f));
				Mines.Add(CurMine);

				UNiagaraComponent FuseComp = UNiagaraComponent::Create(this);
				FuseComp.SetAsset(FuseSystem);
				FuseComp.AttachToComponent(CurMine);
				FuseComp.SetRelativeLocation(FVector(0.f, -7.f, 55.f));
				FuseComp.SetAutoActivate(false);
				FuseComps.Add(FuseComp);
			}
		}
	}
}