

class UDebugPlayerLocationCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(n"Debug");
	default CapabilityDebugCategory = n"Debug";

	AHazePlayerCharacter PlayerOwner;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		DebugValues.AddDebugSettingsFlag(n"PrintDebugLocation", ">0; will print the players location to the screen.");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!PlayerOwner.GetDebugFlag(n"PrintDebugLocation"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
    {
		if(!PlayerOwner.GetDebugFlag(n"PrintDebugLocation"))
       		return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
    }	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
	}
}