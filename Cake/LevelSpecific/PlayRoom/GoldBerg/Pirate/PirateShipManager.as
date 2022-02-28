import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.PirateShipActor;
import Cake.LevelSpecific.PlayRoom.GoldBerg.Pirate.StaticCannonEnemyActor;

event void FOnAllShipsDestroyed();

UCLASS()
class APirateShipManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
    USceneComponent RootComp;

	UPROPERTY()
	TArray<APirateShipActor> AliveShips;

	UPROPERTY()
	TArray<AStaticCannonEnemyActor> EnemiesNearbyArena;

	UPROPERTY()
	FOnAllShipsDestroyed OnAllShipsDestroyed;

	TArray<APirateCannonBallActor> CannonBallsShotByShips;
	TArray<APirateCannonBallActor> CannonBallsShotByNearbyEnemies;

	float OnAllShipsDestroyedDelay = 1.5f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(APirateShipActor Ship : AliveShips)
		{
			Ship.OnPirateShipExploded.AddUFunction(this, n"OnShipExploded");
			Ship.ShootPirateCannonBallsComponent.OnCannonBallsLaunched.AddUFunction(this, n"OnShipCannonBallLaunched");
		}

		for(AStaticCannonEnemyActor Enemy : EnemiesNearbyArena)
		{
			Enemy.ShootPirateCannonBallsComponent.OnCannonBallsLaunched.AddUFunction(this, n"OnEnemyCannonBallLaunched");
		}
	}

	UFUNCTION()
	void WheelBoatEnteredArena()
	{
		for(APirateCannonBallActor CannonBall : CannonBallsShotByNearbyEnemies)
		{
			if(CannonBall != nullptr)
				CannonBall.EndCanonBallMovement(false, false);
		}

		for(AStaticCannonEnemyActor Enemy : EnemiesNearbyArena)
		{
			if(Enemy != nullptr)
				Enemy.BlockCapabilities(n"PirateCannonCapability", this);
		}
	}

	UFUNCTION()
	void OnShipExploded(APirateShipActor Ship)
	{
		AliveShips.Remove(Ship);
		if(AliveShips.Num() <= 0)
		{
			AllShipsDestroyed();
		}
	}

	void AllShipsDestroyed()
	{
		for(APirateCannonBallActor CannonBall : CannonBallsShotByShips)
		{
			if(CannonBall != nullptr)
			{
				// Force the canonball to land and destroy it
				CannonBall.EndCanonBallMovement(false, false);
				CannonBall.DestroyCannonBall();
			}
		}

		System::SetTimer(this, n"CallOnAllShipsDestroyed", OnAllShipsDestroyedDelay, false);
	}

	UFUNCTION()
	void CallOnAllShipsDestroyed()
	{
		OnAllShipsDestroyed.Broadcast();
	}

	UFUNCTION()
	void OnShipCannonBallLaunched(FVector LaunchLocation, FRotator LaunchRotation, APirateCannonBallActor CannonBall)
	{
		if(!CannonBallsShotByShips.Contains(CannonBall))
			CannonBallsShotByShips.Add(CannonBall);
	}

	UFUNCTION()
	void OnEnemyCannonBallLaunched(FVector LaunchLocation, FRotator LaunchRotation, APirateCannonBallActor CannonBall)
	{
		if(!CannonBallsShotByNearbyEnemies.Contains(CannonBall))
			CannonBallsShotByNearbyEnemies.Add(CannonBall);
	}
}