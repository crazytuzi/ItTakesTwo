import Cake.LevelSpecific.Tree.GliderSquirrel.EscapeSquirrelProjectile;

const FStatID STAT_UpdateSquirrelProjectiles(n"UpdateSquirrelProjectiles");

AEscapeManager GetEscapeManager()
{
	auto ManagerComp = UEscapeManagerComponent::GetOrCreate(Game::May);
	if (ManagerComp.Manager == nullptr)
	{
		TArray<AEscapeManager> Managers;
		GetAllActorsOfClass(Managers);

		ManagerComp.Manager = Managers[0];
	}

	return ManagerComp.Manager;
}

UFUNCTION(Category = "Escape")
void EscapeDestroyAllProjectiles()
{
	auto Manager = GetEscapeManager();
	for(auto Element : Manager.TypePools)
	{
		auto& Pool = Element.Value;
		for(auto Projectile : Pool.Pool)
		{
			if (!Projectile.bActive)
				continue;

			Projectile.Deactivate();
		}
	}

	for(auto Projectile : Manager.FlakPool)
	{
		if (!Projectile.bIsActive)
			continue;

		Projectile.DeactivateProjectile();
	}
}

class UEscapeManagerComponent : UActorComponent
{
	AEscapeManager Manager;
}

struct FEscapeSquirrelProjectilePool
{
	TArray<AEscapeSquirrelProjectile> Pool;
}
class AEscapeManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(Category = "Escape", EditInstanceOnly)
	AFlyingMachine TargetMachine;

	// Squirrel projectiles
	UPROPERTY(Category = "Escape", EditInstanceOnly)
	int PoolSize = 30;

	TMap<TSubclassOf<AEscapeSquirrelProjectile>, FEscapeSquirrelProjectilePool> TypePools;
	int FrameNumber = 0;

	// Flak projectiles
	UPROPERTY(Category = "Escape", EditInstanceOnly)
	int FlakPoolSize = 10;

	UPROPERTY(Category = "Escape", EditInstanceOnly)
	TSubclassOf<AFlyingMachineFlakProjectile> FlakType;

	TArray<AFlyingMachineFlakProjectile> FlakPool;
	int FlakIndex = 0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for(int i=0; i<FlakPoolSize; ++i)
		{
			auto Flak = Cast<AFlyingMachineFlakProjectile>(SpawnActor(FlakType, Level = GetLevel()));
			Flak.MakeNetworked(this, i);
			Flak.SetControlSide(Game::May);
			FlakPool.Add(Flak);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
#if TEST
		FScopeCycleCounter EntryCounter(STAT_UpdateSquirrelProjectiles);
#endif

		FrameNumber++;
		int NumUpdated = 0;

		for(auto Element : TypePools)
		{
			auto& Pool = Element.Value;
			for(int i=0; i<Pool.Pool.Num(); ++i)
			{
				auto Projectile = Pool.Pool[i];
				if (!Projectile.bActive)
					continue;

				Projectile.AccumTime += DeltaTime;

				// Stagger every other projectile
				if ((i % 2) != (FrameNumber % 2))
					continue;

				NumUpdated++;
				Projectile.UpdateMovement();
			}
		}
	}

	AEscapeSquirrelProjectile GetOrCreateSquirrelProjectile(TSubclassOf<AEscapeSquirrelProjectile> Type)
	{
		if (!TypePools.Contains(Type))
			TypePools.Add(Type, FEscapeSquirrelProjectilePool());

		auto& Pool = TypePools[Type];
		if (Pool.Pool.Num() == PoolSize)
		{
			for(auto Projectile : Pool.Pool)
			{
				if (Projectile.bActive)
					continue;

				return Projectile;
			}

			return nullptr;
		}
		else
		{
			auto Projectile = Cast<AEscapeSquirrelProjectile>(SpawnActor(Type, Level = GetLevel()));
			Projectile.TargetMachine = TargetMachine;
			Pool.Pool.Add(Projectile);

			return Projectile;
		}
	}

	AFlyingMachineFlakProjectile GetFlakProjectile()
	{
		for(int i=0; i<FlakPoolSize; ++i)
		{
			FlakIndex = (FlakIndex + 1) % FlakPoolSize;
			auto Flak = FlakPool[FlakIndex];

			if (!Flak.bIsActive)
				return Flak;
		}

		// No available projectiles... Just force increment and grab the first one
		FlakIndex = (FlakIndex + 1) % FlakPoolSize;
		return FlakPool[FlakIndex];
	}
}

UFUNCTION(Category = "Escape|Squirrels")
AEscapeSquirrelProjectile SpawnEscapeSquirrelProjectile(TSubclassOf<AEscapeSquirrelProjectile> Type, FVector Origin, FVector Direction, FVector InheritedVelocity)
{
	auto Manager = GetEscapeManager();
	auto Projectile = Manager.GetOrCreateSquirrelProjectile(Type);
	if (Projectile == nullptr)
		return nullptr;

	Projectile.InitializeProjectile(Origin, Direction, InheritedVelocity);
	return Projectile;
}