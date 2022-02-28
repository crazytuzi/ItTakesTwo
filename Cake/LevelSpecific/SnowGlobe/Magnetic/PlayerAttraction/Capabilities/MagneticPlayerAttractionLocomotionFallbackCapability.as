import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;
class UMagneticPlayerAttractionLocomotionFallbackCapabiilty : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttraction);
	default CapabilityTags.Add(FMagneticTags::MagneticPlayerAttractionLocomotionFallbackCapability);

	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 120;

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	AHazePlayerCharacter PlayerOwner;
	UMagneticPlayerAttractionComponent MagneticPlayerAttraction;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!PlayerOwner.IsAnyCapabilityActive(FMagneticTags::MagneticPlayerAttractionMasterCapability))
			return EHazeNetworkActivation::DontActivate;

		if(UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer) == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MagneticPlayerAttraction = UMagneticPlayerAttractionComponent::Get(PlayerOwner.OtherPlayer);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!PlayerOwner.MovementComponent.CanCalculateMovement())
			return;

		FName LocomotionRequestTag = n"MagnetAttract";
		if(IsActioning(n"MPA_MovementUnblockedAfterStun"))
		{
			LocomotionRequestTag = PlayerOwner.MovementComponent.IsGrounded() ?
				n"Movement" :
				n"AirMovement";
		}

		FHazeRequestLocomotionData LocomotionRequest;
		LocomotionRequest.AnimationTag = LocomotionRequestTag;
		PlayerOwner.RequestLocomotion(LocomotionRequest);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!PlayerOwner.IsAnyCapabilityActive(FMagneticTags::MagneticPlayerAttractionMasterCapability))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MagneticPlayerAttraction = nullptr;
	}
}