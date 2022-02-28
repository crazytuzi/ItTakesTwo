
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

UCLASS(NotBlueprintable, meta = ("SwarmNotifyOverlappingPlayers"))
class UAnimNotifyState_SwarmNotifyOverlappingPlayers : UAnimNotifyState
{
	UFUNCTION(BlueprintOverride)
	FString GetNotifyName() const
	{
		return "SwarmNotifyOverlappingPlayers";
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyBegin(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation, float TotalDuration) const
	{
		ASwarmActor Swarm = Cast<ASwarmActor>(MeshComp.GetOwner());

		if (Swarm == nullptr)
			return false;

		Swarm.VictimComp.bCanAttackVictim = true;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool NotifyEnd(USkeletalMeshComponent MeshComp, UAnimSequenceBase Animation) const
	{
		ASwarmActor Swarm = Cast<ASwarmActor>(MeshComp.GetOwner());

		if (Swarm == nullptr)
			return false;

		Swarm.VictimComp.bCanAttackVictim = false;

		return true;
	}

};