import Vino.Movement.Components.MovementComponent;

class USequenceCapability : UHazeCapability
{
    UHazeMovementComponent MovementComponent;

	//default TickGroup = ECapabilityTickGroups::VeryEarly;
    //default CapabilityTags.Add(n"Movement");
	//default CapabilityTags.Add(n"Jump");
	default CapabilityTags.Add(n"Sequence");

	UPROPERTY()
	FTransform SequenceTransform;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		//MovementComponent = UHazeMovementComponent::GetOrCreate(Owner);
		//SetMutuallyExclusive(n"Jump", true);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (WasActionStarted(n"LeftFaceButton"))
			return EHazeNetworkActivation::ActivateFromControl;
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(n"LeftFaceButton"))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SetMutuallyExclusive(n"Jump", true);
	}
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetMutuallyExclusive(n"Jump", false);
	}



	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Print("Sequence is active for " + Owner.Name, 0.f);
	}

}