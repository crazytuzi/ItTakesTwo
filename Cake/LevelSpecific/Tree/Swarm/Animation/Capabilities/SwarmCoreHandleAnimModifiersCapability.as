
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Swarm.Animation.AnimNotifies.AnimNotify_SwarmSettingsModifier;

class USwarmCoreHandleAnimModifersCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::PostWork;

	ASwarmActor SwarmActor = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SwarmActor = Cast<ASwarmActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

 	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		for(USwarmSkeletalMeshComponent SkelMeshIter : SwarmActor.SwarmSkelMeshes)
		{
			SkelMeshIter.ProcessPendingAnimModifers();
		}
	}

    /* Used by the Capability debug menu to show Custom debug info */
	UFUNCTION(BlueprintOverride)
	FString GetDebugString() const
	{
		FString Str = "Swarm Debug AnimModifier";
		Str += "\n";
		Str += "\n";
		for (USwarmSkeletalMeshComponent SkelMeshIter : SwarmActor.SwarmSkelMeshes)
		{
			Str += "\n";
			Str += SkelMeshIter.GetName();
			Str += "\n";
			Str += "----------------------------------------------";
			Str += DebugAnimModifier(SkelMeshIter);
		}
		return Str;
	}

	FString DebugAnimModifier(USwarmSkeletalMeshComponent InSkelMesh) const
	{
		FString Str = "";
		FSwarmAnimModifierSettings& AM = InSkelMesh.DebugModifierSettingsFromAnimThread;
		FSwarmAnimationSettings& AS = InSkelMesh.GetSwarmAnimSettingsDataAsset().Settings;

		UHazeSwarmAnimInstance HazeSwarmAnimInstance = Cast<UHazeSwarmAnimInstance>(InSkelMesh.GetAnimInstance());
		const float CorrectCurrentTime = HazeSwarmAnimInstance.GetCurrentSwarmAnimationTime(InSkelMesh.GetCurrentlyPlayingAnimation()); 
		Str += "Current Animation PlayTime: <Green>";
		Str += CorrectCurrentTime;
		Str += "</>";
		Str += "\n";

		Str += "\n";

		Str += "AnimModifer.Stiffness:";
		Str += AM.bOverrideStiffness ? " <Yellow>" : " <Red>";
		Str += AM.bOverrideStiffness ? AM.Stiffness : AS.Stiffness;
		Str += "</>";

		Str += "\n";

		Str += "AnimModifer.Damping:";
		Str += AM.bOverrideDamping ? " <Yellow>" : " <Red>";
		Str += AM.bOverrideDamping ? AM.Damping : AS.Damping;
		Str += "</>";

		Str += "\n";

		Str += "AnimModifer.NoiseScale:";
		Str += AM.bOverrideNoiseScale ? " <Yellow>" : " <Red>";
		Str += AM.bOverrideNoiseScale ? AM.NoiseScale : AS.NoiseScale;
		Str += "</>";

		Str += "\n";

		Str += "AnimModifer.NoiseGain:";
		Str += AM.bOverrideNoiseGain ? " <Yellow>" : " <Red>";
		Str += AM.bOverrideNoiseGain ? AM.NoiseGain : AS.NoiseGain;
		Str += "</>";
		Str += "\n";

		Str += "AnimModifer.Alpha: <Yellow>";
		Str += AM.Alpha;
		Str += "</>";
		Str += "\n";

		if(InSkelMesh.ActiveAnimModifierSettings.Num() != 0)
		{
			Str += "\n";
			Str += "PendingSwarmAnimModifiers: ";
			for (auto& AnimModifier : InSkelMesh.ActiveAnimModifierSettings)
			{
				Str += "\n";

				auto SwarmAnimSettingsMod = Cast<AnimNotify_SwarmAnimSettingsModifier>(AnimModifier.Instigator);

				if(SwarmAnimSettingsMod.DebugName != NAME_None)
				{
					Str += "<Blue>";
					Str += SwarmAnimSettingsMod.DebugName;
					Str += "</>";
				}
				else
				{
					Str += SwarmAnimSettingsMod;
				}
			}
		}

		Str += "\n";
		if(InSkelMesh.PendingAnimModifierSettings.Num() != 0)
		{
			Str += "\n";
			Str += "PendingSwarmAnimModifiers: ";
			for (auto& PendingModifier : InSkelMesh.PendingAnimModifierSettings)
			{
				Str += "\n";
				Str += PendingModifier.Instigator;
			}
		}

		Str += "\n";

        return Str;

	}
}
