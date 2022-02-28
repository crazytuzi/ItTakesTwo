import Cake.LevelSpecific.Music.LevelMechanics.Backstage.LightRoom.LightRoomSpotlightCharacterComponent;

class ULightRoomSpotlightCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LightRoomSpotlightCapability");

	default CapabilityDebugCategory = n"LightRoomSpotlightCapability";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ULightRoomSpotlightCharacterComponent SpotlightComp;

	UPROPERTY()
	UAnimSequence MaySpotlightAnim;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SpotlightComp = ULightRoomSpotlightCharacterComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (SpotlightComp == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (SpotlightComp.Spotlight == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (SpotlightComp.SpotlightController == nullptr)
			return EHazeNetworkActivation::DontActivate; 

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SpotlightComp == nullptr)
			EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		if (SpotlightComp.Spotlight == nullptr)
			EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (SpotlightComp.SpotlightController == nullptr)
			EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.PlaySlotAnimation(Animation = MaySpotlightAnim, bLoop = true);
		SpotlightComp.ChangeControlSide(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.StopAllSlotAnimations();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(!HasControl())
			return;
		
		SpotlightComp.Spotlight.CurrentInput(GetAttributeVector(AttributeVectorNames::LeftStickRaw), GetAttributeVector(AttributeVectorNames::RightStickRaw));
	}	
}