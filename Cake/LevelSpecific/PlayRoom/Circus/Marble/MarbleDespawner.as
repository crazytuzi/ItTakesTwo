import Cake.LevelSpecific.PlayRoom.Circus.Marble.MarbleCheckpointTube;
import Cake.LevelSpecific.PlayRoom.GoldBerg.MarbleBall.MarbleBall;

event void FMarbleDespawnerEventSignature();
class AMarbleDespawner : AVolume
{
	UPROPERTY()
	AMarbleCheckpointTube LinkedCheckpointTube;

	UPROPERTY()
	FMarbleDespawnerEventSignature OnMarbleDestroyed;

	UPROPERTY()
	bool bEnabled = true;

	UFUNCTION(BlueprintOverride)
    void ActorBeginOverlap(AActor OtherActor)
    {
		if (!bEnabled)
		return;
		
		AMarbleBall Marble = Cast<AMarbleBall>(OtherActor);

		if (Marble != nullptr)
		{
			if (Marble.HasControl())
			{
				Marble.SetMarbleDestroyed(LinkedCheckpointTube);
				OnMarbleDestroyed.Broadcast();
			}
		}
    }
}