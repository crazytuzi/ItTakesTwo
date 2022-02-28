class UHideCharacterCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Visibility");

    AHazeCharacter OwningCharacter;

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        OwningCharacter = Cast<AHazeCharacter>(Owner);
        OwningCharacter.Mesh.SetVisibility(false);
	}

    UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        OwningCharacter.Mesh.SetVisibility(true);
    }
    UFUNCTION(BlueprintOverride)
    FString GetDebugString() const
    {
        return "As long as this capability is on the character, it will be hidden.";    
    }
}