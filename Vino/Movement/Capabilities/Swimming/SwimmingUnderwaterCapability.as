import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingTags;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Swimming.Core.SwimmingTags;

class USwimmingUnderwaterCapability : UHazeCapability
{
	default CapabilityTags.Add(MovementSystemTags::Swimming);

	default CapabilityDebugCategory = n"Movement Swimming";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 25;

	AHazePlayerCharacter Player;
	USnowGlobeSwimmingComponent SwimComp;
	UPlayerHazeAkComponent HazeAkComp;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		SwimComp = USnowGlobeSwimmingComponent::GetOrCreate(Player);
		HazeAkComp = UPlayerHazeAkComponent::Get(Owner);
		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Player.IsAnyCapabilityActive(SwimmingTags::Underwater))
        	return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!Player.IsAnyCapabilityActive(SwimmingTags::Underwater))
        	return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		SwimComp.bIsUnderwater = true;
		SwimComp.CallOnEnteredUnderwater();

		if (SwimComp.AudioData[Player].PlayerSubmerged != nullptr)
		{
			HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].PlayerSubmerged);
			HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].PlayerStartUnderwaterVOEvent);
		}

		// Never ice skate while underwater!
		Owner.BlockCapabilities(IceSkatingTags::IceSkating, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SwimComp.bIsUnderwater = false;
		SwimComp.CallOnExitedUnderwater();

		if (SwimComp.AudioData[Player].PlayerSubmerged != nullptr)
		{
			HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].PlayerSurfaced);
			HazeAkComp.HazePostEvent(SwimComp.AudioData[Player].PlayerStopUnderwaterVOEvent);
		}

		Owner.UnblockCapabilities(IceSkatingTags::IceSkating, this);
	}
}