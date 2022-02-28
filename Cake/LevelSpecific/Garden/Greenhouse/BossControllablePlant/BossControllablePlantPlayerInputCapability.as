import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlantPlayerComponent;
import Vino.Camera.Capabilities.CameraTags;

class UBossControllablePlantPlayerInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UBossControllablePlantPlayerComponent BossPlantsComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BossPlantsComp = UBossControllablePlantPlayerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IsActioning(n"InBossRoomSoil"))
		{
			return EHazeNetworkActivation::DontActivate;
		}
        	
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(n"InBossRoomSoil"))
		{
			return EHazeNetworkDeactivation::DeactivateLocal;
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		BossPlantsComp.bInSoil = true;
		Player.BlockCapabilities(CameraTags::Control, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		BossPlantsComp.bInSoil = false;
		Player.UnblockCapabilities(CameraTags::Control, this);
	}


	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector2D PlayerLeftStickInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
		FVector2D PlayerRightStickInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
		BossPlantsComp.UpdatePlayerLeftStickInput(PlayerLeftStickInput);
		BossPlantsComp.UpdatePlayerRightStickInput(PlayerRightStickInput);
		BossPlantsComp.UpdatePlayerTriggersInput(IsActioning(ActionNames::WeaponAim), IsActioning(ActionNames::WeaponFire));
	}
}
