class USnowglobePlayerSkeletalMeshCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Snowglobe");
	default CapabilityTags.Add(n"SnowGlobeWinterOutfit");

	default TickGroupOrder = 1;

    UPROPERTY(NotEditable)
    AHazePlayerCharacter OwningPlayer;

	UPROPERTY()
	USkeletalMesh SnowglobePlayerMesh;
	
	USkeletalMesh OriginalPlayerMesh;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		OwningPlayer = Cast<AHazePlayerCharacter>(Owner);	
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        return EHazeNetworkActivation::ActivateLocal;
	}

    UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {
		if (SnowglobePlayerMesh != nullptr)
		{
			OriginalPlayerMesh = OwningPlayer.Mesh.SkeletalMesh;
			OwningPlayer.SetPlayerMesh(SnowglobePlayerMesh, true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{       
		if (OriginalPlayerMesh != nullptr)
			OwningPlayer.SetPlayerMesh(OriginalPlayerMesh, true);
	} 
}