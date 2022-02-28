import Cake.LevelSpecific.Clockwork.SplineBoat.TunnelRideDoors;

class UTunnelRideDoorsCapability : UHazeCapability
{
	default CapabilityTags.Add(n"TunnelRideDoorsCapability");
	default CapabilityTags.Add(n"SplineBoat");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ATunnelRideDoors TunnelDoors;

	float HingeYawTarget1 = 90.f;
	float HingeYawTarget2 = -90.f;

	FHazeAcceleratedFloat AccelHinge1;
	FHazeAcceleratedFloat AccelHinge2;
	float AccelTime = 8.f;

	bool bCanDeactivate;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TunnelDoors = Cast<ATunnelRideDoors>(Owner);

		AccelHinge1.SnapTo(TunnelDoors.DoorHinge1.RelativeRotation.Yaw);
		AccelHinge2.SnapTo(TunnelDoors.DoorHinge2.RelativeRotation.Yaw);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (TunnelDoors.bDoorsAreActivated)
        	return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TunnelDoors.AudioDoorsOpening();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		AccelHinge1.AccelerateTo(HingeYawTarget1, AccelTime, DeltaTime);
		AccelHinge2.AccelerateTo(HingeYawTarget2, AccelTime, DeltaTime);

		FRotator NewRot1 = FRotator(0.f, AccelHinge1.Value, 0.f);
		FRotator NewRot2 = FRotator(0.f, AccelHinge2.Value, 0.f);

		//PrintToScreen("NewRot1: " + NewRot1);
		//PrintToScreen("NewRot2: " + NewRot2);

		TunnelDoors.DoorHinge1.SetRelativeRotation(NewRot1);
		TunnelDoors.DoorHinge2.SetRelativeRotation(NewRot2);

		float Diff1 = TunnelDoors.DoorHinge2.RelativeRotation.Yaw - AccelHinge1.Value;
		Diff1 = FMath::Abs(Diff1);

		float Diff2 = TunnelDoors.DoorHinge2.RelativeRotation.Yaw - AccelHinge2.Value;
		Diff2 = FMath::Abs(Diff2);

		//PrintToScreen("Diff1: " + Diff1);
		//PrintToScreen("Diff2: " + Diff2);
	}
}