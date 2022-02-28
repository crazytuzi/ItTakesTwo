import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;

class AIceSkatingCheerEnableVolume : AVolume
{
	UPROPERTY(Category = "Cheer")
	FName EnableName = n"EnableVolume";

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
    	auto SkateComp = UIceSkatingComponent::Get(OtherActor);
    	if (SkateComp == nullptr)
    		return;

    	SkateComp.EnableCheering(EnableName);
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
    	auto SkateComp = UIceSkatingComponent::Get(OtherActor);
    	if (SkateComp == nullptr)
    		return;

    	SkateComp.DisableCheering(EnableName);
    }
}

class AIceSkatingCheerBlockVolume : AVolume
{
	UPROPERTY(Category = "Cheer")
	FName BlockName = n"BlockVolume";

    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
    	auto SkateComp = UIceSkatingComponent::Get(OtherActor);
    	if (SkateComp == nullptr)
    		return;

    	SkateComp.BlockCheering(BlockName);
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
    	auto SkateComp = UIceSkatingComponent::Get(OtherActor);
    	if (SkateComp == nullptr)
    		return;

    	SkateComp.UnblockCheering(BlockName);
    }
}