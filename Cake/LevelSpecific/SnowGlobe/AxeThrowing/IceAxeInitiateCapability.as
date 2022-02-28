import Cake.LevelSpecific.SnowGlobe.AxeThrowing.IceAxeActor;
import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingStatics;

class UIceAxeInitiateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"IceAxeInitiateCapability");
	default CapabilityTags.Add(n"AxeThrowing");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AIceAxeActor IceAxe;

	FVector TargetLoc;

	FHazeAcceleratedVector AccelVector;

	FIceAxeSettings IceAxeSettings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		IceAxe = Cast<AIceAxeActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IceAxe.IceAxeState == EIceAxeState::Initiating)
       		return EHazeNetworkActivation::ActivateLocal;
       
	    return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IceAxe.IceAxeState == EIceAxeState::Initiating)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetLoc = IceAxe.ActorLocation + (IceAxe.ActorForwardVector * IceAxeSettings.OriginOffset);
		AccelVector.SnapTo(IceAxe.ActorLocation);
	}
}