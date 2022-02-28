import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;

event void FCastleTeleporterChangedPhase(int PhaseNumber);

struct FCastleEnemyTeleporterPhase
{
	UPROPERTY()
	float HealthThreshold = 0.f;
	UPROPERTY()
	AActor TargetLocation;
	UPROPERTY()
	TArray<ACastleEnemy> EnemiesToTeleportIn;
};

struct FCastleEnemyTeleportingIn
{
	ACastleEnemy Enemy;
	float Timer = 0.f;
	bool bStarted = false;
}

class UCastleEnemyTeleporterComponent : UActorComponent
{
	UPROPERTY()
	TArray<FCastleEnemyTeleporterPhase> Phases;

	UPROPERTY()
	FCastleTeleporterChangedPhase OnTeleporterChangedPhase;

	UPROPERTY(Category = "FX")
	UNiagaraSystem TeleporterVanishEffect;
	UPROPERTY(Category = "FX")
	UNiagaraSystem TeleporterAppearEffect;
	UPROPERTY(Category = "FX")
	UNiagaraSystem TeleporterSpawnEnemyEffect;
	UPROPERTY(Category = "FX")
	bool bRiseOutOfFloor = true;
	
	int CurrentPhase = -1;
	TArray<FCastleEnemyTeleportingIn> TeleportingEnemies;

	const float Time_StartTeleport = 2.7f;
	const float Time_FinishTeleport = 3.2f;
	const float VerticalOffset = 250.f;

	void TeleportInEnemy(ACastleEnemy Enemy)
	{
		FCastleEnemyTeleportingIn Teleport;
		Teleport.Enemy = Enemy;
		TeleportingEnemies.Add(Teleport);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		if (Reason == EEndPlayReason::Destroyed)
		{
			for (int i = TeleportingEnemies.Num() - 1; i >= 0; --i)
			{
				FCastleEnemyTeleportingIn& Teleport = TeleportingEnemies[i];
				if (Teleport.Enemy == nullptr)
					continue;

				if (!Teleport.bStarted)
					StartSpawning(Teleport.Enemy);
				FinishSpawning(Teleport.Enemy);
			}
		}
	}

	void StartSpawning(ACastleEnemy Enemy)
	{
		Enemy.EnableActor(nullptr);
		Enemy.SetActorEnableCollision(false);
		Enemy.BlockCapabilities(n"CastleEnemyAI", this);
		Enemy.BlockCapabilities(n"CastleEnemyMovement", this);
		Enemy.bUnhittable = true;

		if (TeleporterSpawnEnemyEffect != nullptr)
			Niagara::SpawnSystemAtLocation(TeleporterSpawnEnemyEffect, Enemy.ActorLocation, Enemy.ActorRotation);
	}

	void FinishSpawning(ACastleEnemy Enemy)
	{
		Enemy.UnblockCapabilities(n"CastleEnemyAI", this);
		Enemy.UnblockCapabilities(n"CastleEnemyMovement", this);
		Enemy.SetActorEnableCollision(true);
		Enemy.bUnhittable = false;
		Enemy.MeshOffsetComponent.ResetLocationWithTime(0.f);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		for (int i = TeleportingEnemies.Num() - 1; i >= 0; --i)
		{
			FCastleEnemyTeleportingIn& Teleport = TeleportingEnemies[i];
			if (Teleport.Enemy == nullptr)
			{
				TeleportingEnemies.RemoveAt(i);
				continue;
			}

			Teleport.Timer += DeltaTime;

			// Start and finish teleporting at the appropriate times
			if (Teleport.Timer >= Time_FinishTeleport)
			{
				FinishSpawning(Teleport.Enemy);
				TeleportingEnemies.RemoveAt(i);
				continue;
			}
			else if (Teleport.Timer >= Time_StartTeleport && !Teleport.bStarted)
			{
				Teleport.bStarted = true;
				StartSpawning(Teleport.Enemy);
			}

			// Apply the enemy movement during the teleport
			if (Teleport.Timer >= Time_StartTeleport)
			{
				float Pct = FMath::Clamp((Teleport.Timer - Time_StartTeleport) / (Time_FinishTeleport - Time_StartTeleport), 0.f, 1.f);
				if (bRiseOutOfFloor)
				{
					Teleport.Enemy.MeshOffsetComponent.OffsetLocationWithTime(
						Teleport.Enemy.ActorLocation - FVector(0.f, 0.f, VerticalOffset * (1.f - Pct)),
						0.f
					);
				}
			}
		}
	}
};