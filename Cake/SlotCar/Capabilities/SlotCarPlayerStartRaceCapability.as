import Cake.SlotCar.SlotCarTrackActor;
import Cake.SlotCar.Capabilities.SlotCarRaceStage;

class USlotCarPlayerStartRaceCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SlotCar");
	default CapabilityTags.Add(n"SlotCarStartRace");

	default CapabilityDebugCategory = n"SlotCar";
	
	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ASlotCarTrackActor SlotCarTrack;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (SlotCarTrack == nullptr)
			SlotCarTrack = Cast<ASlotCarTrackActor>(GetAttributeObject(n"SlotCarInteraction"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SlotCarTrack == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (SlotCarTrack.RaceStage != ESlotCarRaceStage::ReadyCheck &&
			SlotCarTrack.RaceStage != ESlotCarRaceStage::Countdown)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (SlotCarTrack == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (SlotCarTrack.RaceStage != ESlotCarRaceStage::ReadyCheck &&
			SlotCarTrack.RaceStage != ESlotCarRaceStage::Countdown)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.BlockCapabilities(n"SlotCarInput", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(n"SlotCarInput", this);
	}
}