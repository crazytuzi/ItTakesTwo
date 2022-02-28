import Cake.LevelSpecific.Basement.LevelActors.SeekingEye.SeekingEye;

class USeekingEyePostFollowCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ASeekingEye SeekingEye;

	float MaxIdleTime = 1.5f;
	float CurrentIdleTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SeekingEye = Cast<ASeekingEye>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SeekingEye.bFollowingPlayers)
        	return EHazeNetworkActivation::DontActivate;

		if (SeekingEye.bScanningAllowed)
			return EHazeNetworkActivation::DontActivate;

		if (!SeekingEye.bActive)
			return EHazeNetworkActivation::DontActivate;
        
		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SeekingEye.bFollowingPlayers)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (CurrentIdleTime >= MaxIdleTime)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentIdleTime = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (SeekingEye.bActive)
			SeekingEye.AllowScanning();
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		CurrentIdleTime += DeltaTime;
		Print("" + CurrentIdleTime);
	}
}