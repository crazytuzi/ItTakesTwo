import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.WheelBoat.WheelBoatActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.StaticCannonEnemyActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.StreamTentacleArmActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateShipActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateStaticMine;

event void FOnWheelBoatCheckpointReached();

enum EWheelBoatCheckpointEnemyType
{
	Cannon,
	StreamArm,
	Ship,
	Mine,
}

struct FWheelBoatCheckpointEnemy
{
	UPROPERTY()
	EWheelBoatCheckpointEnemyType Type;

	UPROPERTY(meta = (EditCondition="Type == EWheelBoatCheckpointEnemyType::Cannon", EditConditionHides))
	AStaticCannonEnemyActor Cannon;

	UPROPERTY(meta = (EditCondition="Type == EWheelBoatCheckpointEnemyType::StreamArm", EditConditionHides))
	AStreamTentacleArmActor StreamArm;

	UPROPERTY(meta = (EditCondition="Type == EWheelBoatCheckpointEnemyType::Ship", EditConditionHides))
	APirateShipActor PirateShip;

	UPROPERTY(meta = (EditCondition="Type == EWheelBoatCheckpointEnemyType::Mine", EditConditionHides))
	APirateStaticMine Mine;

	AHazeActor GetEnemyActor() const
	{
		if(Type == EWheelBoatCheckpointEnemyType::Cannon)
			return Cannon;
		else if(Type == EWheelBoatCheckpointEnemyType::StreamArm)
			return StreamArm;
		else if(Type == EWheelBoatCheckpointEnemyType::Ship)
			return PirateShip;
		else if(Type == EWheelBoatCheckpointEnemyType::Mine)
			return Mine;
		else
			return nullptr;
	}
}


UCLASS(Abstract)
class AWheelBoatCheckpointActor : AHazeActor
{
	UPROPERTY(DefaultComponent, Attach = RootComponent)
	UBoxComponent Trigger;

	UPROPERTY()
	FOnWheelBoatCheckpointReached OnCheckpointReached;

	// ALl these enemies will be destroyed when this checkpoint is used
	UPROPERTY()
	TArray<FWheelBoatCheckpointEnemy> EnemiesLinkedToCheckpoint;

	UPROPERTY(NotEditable)
	bool bEnabled = true;

	UPROPERTY()
	bool bRestoreHealth = true;

	// The checkpoint before this one
	UPROPERTY()
	AWheelBoatCheckpointActor EarlierCheckpoint;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(HasControl())
			Trigger.OnComponentBeginOverlap.AddUFunction(this, n"EnterTrigger");

		if(!bEnabled)
			DisableWheelboatCheckpoint();
	}

	UFUNCTION()
	void EnableWheelboatCheckpoint()
	{
		if(bEnabled)
			return;

		Trigger.SetCollisionEnabled(ECollisionEnabled::QueryOnly);

		bEnabled = true;
	}

	UFUNCTION()
	void DisableWheelboatCheckpoint()
	{
		if(!bEnabled)
			return;

		Trigger.SetCollisionEnabled(ECollisionEnabled::NoCollision);

		bEnabled = false;
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		if(!bEnabled)
			return;
		if(!HasControl())
			return;
			
		AWheelBoatActor Boat = Cast<AWheelBoatActor>(OtherActor);

		if (Boat == nullptr)
			return;
			
		DisableWheelboatCheckpoint();
		NetReachedCheckpoint(Boat);
	}

	UFUNCTION()
	void DisableEarlierWheelboatCheckpoints()
	{
		if(EarlierCheckpoint != nullptr)
		{
			if(EarlierCheckpoint.bEnabled)
				EarlierCheckpoint.DisableWheelboatCheckpoint();

			// Disable recursively backwards
			EarlierCheckpoint.DisableEarlierWheelboatCheckpoints();
		}
	}

	UFUNCTION(NetFunction)
	void NetReachedCheckpoint(AWheelBoatActor Boat)
	{
		if(bRestoreHealth)
			Boat.RestoreHealth();

		OnCheckpointReached.Broadcast();
	}

	UFUNCTION()
	void SpawnAtCheckpoint(AWheelBoatActor Boat)
	{	
		DestroyEnemiesBeforeCheckpoint();
		DisableWheelboatCheckpoint();
		Boat.SetActorLocationAndRotation(ActorLocation, ActorRotation);
		DisableEarlierWheelboatCheckpoints();
	}

	UFUNCTION()
	void DestroyEnemiesBeforeCheckpoint()
	{
		// We remove all the eneies here
		for(FWheelBoatCheckpointEnemy EnemyData : EnemiesLinkedToCheckpoint)
		{
			auto Enemy = EnemyData.GetEnemyActor();
			if(Enemy != nullptr)
			{
				Enemy.DestroyActor();
				if(EnemyData.Cannon != nullptr && EnemyData.Cannon.LinkedPlatform != nullptr)
				{
					EnemyData.Cannon.LinkedPlatform.DestroyActor();
				}
			}
		}

		if(EarlierCheckpoint != nullptr)
		{
			// Destroy recursively backwards
			EarlierCheckpoint.DestroyEnemiesBeforeCheckpoint();
		}
	}
}