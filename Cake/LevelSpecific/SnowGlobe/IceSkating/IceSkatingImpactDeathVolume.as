import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;

class AIceSkatingImpactDeathVolume : AVolume
{
    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
    	auto Player = Cast<AHazePlayerCharacter>(OtherActor);
    	if (Player == nullptr)
    		return;

    	auto SkateComp = UIceSkatingComponent::Get(Player);
    	if (SkateComp == nullptr)
    		return;

    	SkateComp.bInstantImpactDeath = true;
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
    	auto Player = Cast<AHazePlayerCharacter>(OtherActor);
    	if (Player == nullptr)
    		return;

    	auto SkateComp = UIceSkatingComponent::Get(Player);
    	if (SkateComp == nullptr)
    		return;

    	SkateComp.bInstantImpactDeath = false;
    }
}