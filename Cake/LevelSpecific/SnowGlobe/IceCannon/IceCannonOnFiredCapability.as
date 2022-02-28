import Cake.LevelSpecific.SnowGlobe.IceCannon.IceCannonActor;

class UIceCannonOnFiredCapability : UHazeCapability
{
	default CapabilityTags.Add(n"IceCannonOnFiredCapability");
	default CapabilityTags.Add(n"IceCannon");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AIceCannonActor IceCannon;

	bool bActive;

	int Stage;

	FHazeAcceleratedVector AccelVecScale;
	FVector StartingScale;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		IceCannon = Cast<AIceCannonActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IceCannon.bIceCannonFired)
        	return EHazeNetworkActivation::ActivateLocal;
        
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!bActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bActive = true;
		StartingScale = IceCannon.MeshCannon.GetRelativeScale3D();
		AccelVecScale.SnapTo(StartingScale);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Stage = 0;
		IceCannon.bIceCannonFired = false;
		IceCannon.MeshCannon.SetRelativeScale3D(FVector(1.f));
	}

	UFUNCTION()
	void IncreaseStage()
	{
		Stage++;
	}

	UFUNCTION()
	void SetInactive()
	{
		bActive = false;
	}
}