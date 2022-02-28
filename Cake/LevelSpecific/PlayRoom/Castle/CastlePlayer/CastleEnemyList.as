import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemy;
import Cake.LevelSpecific.PlayRoom.Castle.CastleEnemy.CastleEnemyKillVolume;

void RegisterEnemy(ACastleEnemy Enemy)
{
	auto Comp = UCastleEnemyListComponent::GetOrCreate(Game::GetMay());
	// If this is the first enemy we add, add persistent status to the component
	if (Comp.Enemies.Num() == 0)
		Reset::RegisterPersistentComponent(Comp);
	Comp.Enemies.AddUnique(Enemy);
}

void UnregisterEnemy(ACastleEnemy Enemy)
{
	auto Comp = UCastleEnemyListComponent::GetOrCreate(Game::GetMay());
	bool bHadEnemies = Comp.Enemies.Num() != 0;

	Comp.Enemies.Remove(Enemy);

	// If we had enemies before but no longer do now, remove the persistent status of the component
	if (bHadEnemies && Comp.Enemies.Num() == 0)
		Reset::UnregisterPersistentComponent(Comp);
}

void RegisterEnemyKillVolume(ACastleEnemyKillVolume Volume)
{
	auto Comp = UCastleEnemyListComponent::GetOrCreate(Game::GetMay());
	// If this is the first volume we add, add persistent status to the component
	if (Comp.KillVolumes.Num() == 0)
		Reset::RegisterPersistentComponent(Comp);
	Comp.KillVolumes.AddUnique(Volume);
}

void UnregisterEnemyKillVolume(ACastleEnemyKillVolume Volume)
{
	auto Comp = UCastleEnemyListComponent::GetOrCreate(Game::GetMay());
	bool bHadVolumes = Comp.KillVolumes.Num() != 0;

	Comp.KillVolumes.Remove(Volume);

	// If we had volumes before but no longer do now, remove the persistent status of the component
	if (bHadVolumes && Comp.KillVolumes.Num() == 0)
		Reset::UnregisterPersistentComponent(Comp);
}

class UCastleEnemyListComponent : UActorComponent
{
	TArray<ACastleEnemy> Enemies;
	TArray<ACastleEnemyKillVolume> KillVolumes;
}

const TArray<ACastleEnemy>& GetAllCastleEnemies()
{
	const TArray<ACastleEnemy>& AllEnemies = UCastleEnemyListComponent::GetOrCreate(Game::GetMay()).Enemies;
	return AllEnemies;
}

bool IsInCastleEnemyKillVolume(FVector Point)
{
	auto List = UCastleEnemyListComponent::Get(Game::GetMay());
	if (List == nullptr)
		return false;

	for (ACastleEnemyKillVolume Volume : List.KillVolumes)
	{
		if (Volume.EncompassesPoint(Point))
			return true;
	}

	return false;
}