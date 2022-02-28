import Cake.Environment.BreakableComponent;
import Cake.LevelSpecific.Music.Singing.SongReactionComponent;

// This component will attempt to locate a BreakableComponent and call Break on it when PowerFulSong impacts the object.
class UPowerfulSongBreakableImpactComponent : USongReactionComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OnPowerfulSongImpact.AddUFunction(this, n"HandleBreakableImpact");
	}

	UFUNCTION()
	void HandleBreakableImpact(FPowerfulSongInfo Info)
	{
		UBreakableComponent BreakableComponent = UBreakableComponent::Get(Owner);
		devEnsure(BreakableComponent != nullptr);
		FBreakableHitData HitData;
		BreakableComponent.Break(HitData);
	}
}
