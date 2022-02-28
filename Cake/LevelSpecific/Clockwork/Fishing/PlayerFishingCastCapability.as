import Cake.LevelSpecific.Clockwork.Fishing.PlayerFishingComponent;
import Cake.LevelSpecific.Clockwork.Fishing.RodBase;

class UPlayerFishingCastCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerFishingCastCapability");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UPlayerFishingComponent PlayerComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerFishingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.FishingState == EFishingState::Casting)
	        return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.FishingState != EFishingState::Casting)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerComp.EventSlackValue.Broadcast(PlayerComp.CastSlackTarget);
		
		ARodBase RodBase = Cast<ARodBase>(PlayerComp.RodBase);
		RodBase.AudioCastLine();
	}
}