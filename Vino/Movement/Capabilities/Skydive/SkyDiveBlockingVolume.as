import Vino.Movement.MovementSystemTags;

class ASkyDiveBlockingVolume : AVolume
{
    UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter player = Cast<AHazePlayerCharacter>(OtherActor);
		if (player != nullptr)
		{
			player.BlockCapabilities(MovementSystemTags::SkyDive, this);
		}
    }

    UFUNCTION(BlueprintOverride)
    void ActorEndOverlap(AActor OtherActor)
    {
		AHazePlayerCharacter player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (player != nullptr)
		{
			player.UnblockCapabilities(MovementSystemTags::SkyDive, this);
		}
    }
};