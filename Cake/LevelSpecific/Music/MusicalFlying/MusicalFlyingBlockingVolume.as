
class UMusicalFlyingBlockingVolumeContainer : UActorComponent
{
	TArray<AMusicalFlyingBlockingVolume> FlyingBlockers;
}

void OnInfiniteFlyingEnabled()
{
	UMusicalFlyingBlockingVolumeContainer Comp = UMusicalFlyingBlockingVolumeContainer::GetOrCreate(Game::GetMay());

	for(AMusicalFlyingBlockingVolume BlockingVolume : Comp.FlyingBlockers)
		BlockingVolume.OnInfiniteFlyingEnabled();
}

void OnInfiniteFlyingDisabled()
{
	UMusicalFlyingBlockingVolumeContainer Comp = UMusicalFlyingBlockingVolumeContainer::GetOrCreate(Game::GetMay());

	for(AMusicalFlyingBlockingVolume BlockingVolume : Comp.FlyingBlockers)
		BlockingVolume.OnInfiniteFlyingDisabled();
}

class AMusicalFlyingBlockingVolume : ABlockingVolume
{
	default BrushComponent.bGenerateOverlapEvents = false;
	FName DefaultCollisionPreset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DefaultCollisionPreset = BrushComponent.CollisionProfileName;

		UMusicalFlyingBlockingVolumeContainer Comp = UMusicalFlyingBlockingVolumeContainer::GetOrCreate(Game::GetMay());
		Comp.FlyingBlockers.Add(this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		UMusicalFlyingBlockingVolumeContainer Comp = UMusicalFlyingBlockingVolumeContainer::GetOrCreate(Game::GetMay());
		Comp.FlyingBlockers.Remove(this);
	}

	void OnInfiniteFlyingEnabled()
	{
		BrushComponent.SetCollisionProfileName(n"NoCollision");
	}

	void OnInfiniteFlyingDisabled()
	{
		BrushComponent.SetCollisionProfileName(DefaultCollisionPreset);
	}

}
