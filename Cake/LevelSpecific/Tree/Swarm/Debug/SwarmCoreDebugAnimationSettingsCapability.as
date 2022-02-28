
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;

class USwarmCoreDebugAnimationSettingsCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Swarm");
	default CapabilityTags.Add(n"SwarmCore");
	default CapabilityTags.Add(n"SwarmDebug");

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	ASwarmActor Swarm = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Swarm = Cast<ASwarmActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

    /* Used by the Capability debug menu to show Custom debug info */
	UFUNCTION(BlueprintOverride)
	FString GetDebugString() const
	{
		FString Str = "Swarm State";
		Str += "\n";
		Str += "\n";
		for (USwarmSkeletalMeshComponent SkelMeshIter : Swarm.SwarmSkelMeshes)
		{
			Str += "\n";
			Str += SkelMeshIter.GetName();
			Str += "\n";
			Str += "----------------------------------------------";
			Str += GetDebugParticleLifeString(SkelMeshIter);
		}
		return Str;

	}

	FString GetDebugParticleLifeString(USwarmSkeletalMeshComponent InSwarmSkelMesh) const
	{
		FString Str = "";
		Str += "Num Particles Alive: <Yellow>";
		Str += InSwarmSkelMesh.GetNumParticlesAlive();
		Str += "</>";

		Str += "\n";

		Str += "Num Particles Dead: <Red>";
		Str += InSwarmSkelMesh.GetNumParticlesDead();
		Str += "</>";

		Str += "\n";
		Str += "\n";
		Str += "\n";

        return Str;

	}

}