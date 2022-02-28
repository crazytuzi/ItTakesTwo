import Cake.LevelSpecific.Music.MusicalFlying.MusicalFlyingComponent;

enum EMusicalFlyingInfiniteTriggerType
{
	EnableFlying,
	DisableFlying
}

UCLASS(HideCategories = "Cooking Replication Collision Debug Actor Tags HLOD Mobile AssetUserData Input LOD Rendering")
class AMusicalFlyingInfiniteTrigger : AVolume
{
	UPROPERTY()
	EMusicalFlyingInfiniteTriggerType TriggerType = EMusicalFlyingInfiniteTriggerType::EnableFlying;

	default BrushComponent.CollisionProfileName = n"TriggerOnlyPlayer";

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if(TriggerType == EMusicalFlyingInfiniteTriggerType::EnableFlying)
		{
			Shape::SetVolumeBrushColor(this, FLinearColor::Green);
		}
		else if(TriggerType == EMusicalFlyingInfiniteTriggerType::DisableFlying)
		{
			Shape::SetVolumeBrushColor(this, FLinearColor::Red);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BrushComponent.OnComponentBeginOverlap.AddUFunction(this, n"BrushBeginOverlap");
	}

	UFUNCTION()
	void BrushBeginOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, const FHitResult&in Hit)
	{
#if !RELEASE
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if(!devEnsure(Player != nullptr, "This object should only register overlaps from the player."))
			return;
#endif // !RELEASE

		UMusicalFlyingComponent FlyingComp = UMusicalFlyingComponent::Get(OtherActor);

		if(FlyingComp != nullptr)
		{
			if(TriggerType == EMusicalFlyingInfiniteTriggerType::EnableFlying)
				FlyingComp.SetInfiniteFlying(true);
			else if(TriggerType == EMusicalFlyingInfiniteTriggerType::DisableFlying)
				FlyingComp.SetInfiniteFlying(false);
		}
	}
}
