import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingDoors;

class UAxeThrowingDoorsCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AxeThrowingDoorsCapability");
	default CapabilityTags.Add(n"AxeThrowing");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AAxeThrowingDoors Doors;

	FHazeAcceleratedVector AccelVector;

	float AccelSpeed = 1.5f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Doors = Cast<AAxeThrowingDoors>(Owner);
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

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		AccelVector.SnapTo(Doors.ClosedPos);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (Doors.bDoorsAreOpen)
			AccelVector.AccelerateTo(Doors.OpenPos, AccelSpeed * 2.f, DeltaTime);
		else
			AccelVector.AccelerateTo(Doors.ClosedPos, AccelSpeed, DeltaTime);

		Doors.FenceMesh.SetRelativeLocation(AccelVector.Value);
	}
}