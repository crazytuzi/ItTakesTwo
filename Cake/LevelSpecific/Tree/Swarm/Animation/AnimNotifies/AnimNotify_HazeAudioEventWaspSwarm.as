import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Vino.Audio.Movement.AnimNotify_HazeAudioEvent;

/* Same as HazeAudioEvent but with extra (swarm specific) activation requirements
	Adding audio notifies to swarm animations? Then use this one!  */ 

UCLASS(NotBlueprintable, meta = (DisplayName = "Haze Audio Event WaspSwarm"))
class UAnimNotify_HazeAudioEventWaspSwarm : UAnimNotify_HazeAudioEvent
{
	UFUNCTION(BlueprintOverride)
	bool Notify(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		// (don't return false upon nullptr -- we need it to work during preview)
		const ASwarmActor Swarm = Cast<ASwarmActor>(MeshComp.Owner);
		if(Swarm != nullptr && (Swarm.IsAboutToDie() || Swarm.IsDead()))
			return false;

		return Super::Notify(MeshComp, Animation);
	}
}