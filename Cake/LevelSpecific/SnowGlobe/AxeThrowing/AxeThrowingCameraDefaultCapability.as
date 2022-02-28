import Cake.LevelSpecific.SnowGlobe.AxeThrowing.AxeThrowingPlayerComp;

class UAxeThrowingCameraDefaultCapability : UHazeCapability
{
	default CapabilityTags.Add(n"AxeThrowingCameraDefaultCapability");
	default CapabilityTags.Add(n"AxeThrowing");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	UAxeThrowingPlayerComp PlayerComp;

	FVector Forward;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UAxeThrowingPlayerComp::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.AxePlayerGameState == EAxePlayerGameState::InPlay)
        	return EHazeNetworkActivation::ActivateLocal;

		if (PlayerComp.AxePlayerGameState == EAxePlayerGameState::BeforePlay)
        	return EHazeNetworkActivation::ActivateLocal;

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
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.5f;

		Player.ApplyCameraSettings(PlayerComp.DefaultSpringArmSettings, Blend, this);

		FHazeCameraClampSettings Clamp;
		Clamp.bUseCenterOffset = true;
		Clamp.CenterOffset = FRotator(0.f);
		Clamp.CenterType = EHazeCameraClampsCenterRotation::Component;
		Clamp.CenterComponent = PlayerComp.OurInteractionComp;
		
		Player.ApplyCameraClampSettings(Clamp, CameraBlend::Normal(3.5f), this);
		
		FHazePointOfInterest POI;
		
		POI.FocusTarget.Component = PlayerComp.OurInteractionComp;
		POI.FocusTarget.Actor = PlayerComp.OurInteractionComp.Owner;
		POI.bMatchFocusDirection = true;
		POI.Blend = CameraBlend::Normal(0.8f);
		POI.Duration = 2.5f;

		Player.ApplyClampedPointOfInterest(POI, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ClearCameraSettingsByInstigator(this, 3.5f);
		Player.ClearPointOfInterestByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!GetAttributeVector2D(AttributeVectorNames::CameraDirection).IsNearlyZero())
			Player.ClearPointOfInterestByInstigator(this);
	}
}