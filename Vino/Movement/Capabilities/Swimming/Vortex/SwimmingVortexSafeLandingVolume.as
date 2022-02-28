import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;

class ASwimmingVortexSafeLandingVolume : AVolume
{
    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		
		USnowGlobeSwimmingComponent SwimmingComp = USnowGlobeSwimmingComponent::Get(OtherActor);
		if (SwimmingComp == nullptr)
			return;

		SwimmingComp.VortexSafeVolumeCount += 1;
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;
		
		USnowGlobeSwimmingComponent SwimmingComp = USnowGlobeSwimmingComponent::Get(OtherActor);
		if (SwimmingComp == nullptr)
			return;

		SwimmingComp.VortexSafeVolumeCount -= 1;
    }
}