import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;

class UBoatsledCameraRotationResetCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledCameraRotationReset);

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	default CapabilityDebugCategory = n"Boatsled";

	AHazePlayerCharacter PlayerOwner;
	UBoatsledComponent BoatsledComponent;

	float CapabilityDuration;
	float ElapsedTime;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		BoatsledComponent = UBoatsledComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BoatsledComponent.bMustResetCameraRotation)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CapabilityDuration = BoatsledComponent.CameraResetTime;

		BoatsledComponent.bMustResetCameraRotation = false;
		BoatsledComponent.CameraResetTime = 0.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ElapsedTime += DeltaTime;
		BoatsledComponent.RotateCameraRollOverTime(PlayerOwner.MovementWorldUp, CapabilityDuration, DeltaTime);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ElapsedTime >= CapabilityDuration)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ElapsedTime = 0.f;
		CapabilityDuration = 0.f;
	}
}