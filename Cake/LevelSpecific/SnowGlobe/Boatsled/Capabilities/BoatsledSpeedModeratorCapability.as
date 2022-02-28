import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

class UBoatsledSpeedModeratorCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledSpeedModerator);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	default CapabilityDebugCategory = BoatsledTags::Boatsled;

	AHazePlayerCharacter PlayerOwner;
	UBoatsledComponent BoatsledComponent;

	float BaseSpeed;
	float GoalSpeed;

	float SpeedDelta;

	float ElapsedTime;
	float CapabilityDuration;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IsActioning(BoatsledTags::BoatsledSpeedModeratorActionState))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ConsumeAttribute(BoatsledTags::BoatsledSpeedModeratorDelta, SpeedDelta);
		ConsumeAttribute(BoatsledTags::BoatsledSpeedModeratorTime, CapabilityDuration);

		BaseSpeed = BoatsledComponent.GetBoatsledMaxSpeed(false);
		GoalSpeed = BaseSpeed + SpeedDelta;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ElapsedTime += DeltaTime;

		float Alpha = ElapsedTime / CapabilityDuration;
		BoatsledComponent.SetBoatsledMaxSpeed(BaseSpeed + SpeedDelta * BoatsledComponent.Boatsled.AccelerationCurve.GetFloatValue(Alpha));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ElapsedTime >= CapabilityDuration)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		BoatsledComponent.SetBoatsledMaxSpeed(GoalSpeed);

	 	BaseSpeed = 0.f;
		GoalSpeed = 0.f;

		SpeedDelta = 0.f;

		ElapsedTime = 0.f;
		CapabilityDuration = 0.f;
	}
}