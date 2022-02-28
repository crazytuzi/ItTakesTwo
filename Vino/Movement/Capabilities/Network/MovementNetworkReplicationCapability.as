class UMovementNetworkReplicationCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NetworkReplication");
	default CapabilityTags.Add(n"MovementNetworkReplication");

	default CapabilityDebugCategory = CapabilityTags::Movement;


	int Blocks = 0;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagAdded(FName Tag)
	{
		Owner.TriggerMovementTransition(this);
		if (Blocks == 0)
			Owner.BlockMovementSyncronization(this);
		Blocks += 1;
	}

	UFUNCTION(BlueprintOverride)
	void OnBlockTagRemoved(FName Tag)
	{
		Blocks -= 1;
		if (Blocks == 0)
			Owner.UnblockMovementSyncronization(this);
	}
};
