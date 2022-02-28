import Cake.SlotCar.SlotCarTrackActor;
import Cake.SlotCar.SlotCarSettings;

class USlotCarTrackRaceBlockCarCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SlotCar");
	default CapabilityTags.Add(n"SlotCarTrackRaceBlockCarCapability");

	default CapabilityDebugCategory = n"SlotCar";
	
	default TickGroup = ECapabilityTickGroups::BeforeGamePlay;
	default TickGroupOrder = 99;

	ASlotCarTrackActor SlotCarTrack;

	bool bCapabilitiesBlocked = false;
	int LightSequence = -1;
	// bool bLightsOut = false;

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		SlotCarTrack = Cast<ASlotCarTrackActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (SlotCarTrack == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (SlotCarTrack.RaceStage == ESlotCarRaceStage::RaceActive)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// if (bLightsOut)
		// 	return EHazeNetworkDeactivation::DeactivateLocal;

		if (SlotCarTrack.RaceStage == ESlotCarRaceStage::RaceActive)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		BlockSlotCarCapabilities();
		SlotCarTrack.RaceStage = ESlotCarRaceStage::Countdown;
		// bLightsOut = false;

		// Reset track player tracking
		for (AHazePlayerCharacter Player : Game::Players)
		{
			SlotCarTrack.LapTimes[Player].PrepareForRaceStart(5);
		}

		// Reset cars to the starting grid
		for (ASlotCarActor SlotCar : SlotCarTrack.SlotCars)
		{
			SlotCar.CurrentSpeed = 0.f;
			SlotCar.TeleportSlotCarToStartOfSpline(SlotCar);
		}

		// SlotCarTrack.SlotCarTrackWidget.RaceCountdownStarted();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams Params)
	{
		// if (bLightsOut)
		// SlotCarTrack.RaceStage = ESlotCarRaceStage::CountdownFinished;

		// SlotCarTrack.SlotCarTrackWidget.RaceCountdownFinished();

		for (AHazePlayerCharacter Player : Game::Players)
		{
			SlotCarTrack.LapTimes[Player].RaceEnded();			
		}

		UnblockSlotCarCapabilities();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		// if (!bLightsOut)
		// {
		// 	int ActiveLights = 0;

		// 	float RaceStartTime = ActiveDuration - SlotCarSettings::Race.PreLightsTime;
		// 	if (RaceStartTime > 0.f)
		// 	{
		// 		ActiveLights = FMath::FloorToInt(RaceStartTime / (SlotCarSettings::Race.LightsTime / SlotCarSettings::Race.NumberOfLights));
		// 	}

		// 	if (LightSequence != ActiveLights)
		// 	{
		// 		LightSequence = ActiveLights;
		// 		SlotCarTrack.SlotCarTrackWidget.UpdateStartLights(LightSequence);
		// 		// Activate Light

		// 		if (LightSequence <= 3 && LightSequence >= 1)
		// 		{
		// 			UHazeAkComponent::HazePostEventFireForget(SlotCarTrack.RedLightEvent, SlotCarTrack.ActorTransform);
		// 		}
				

		// 		if (LightSequence == 4)
		// 		{
		// 			bLightsOut = true;
		// 			UHazeAkComponent::HazePostEventFireForget(SlotCarTrack.GreenLightEvent, SlotCarTrack.ActorTransform);		
		// 		}
		// 	}
		// }
	}

	void BlockSlotCarCapabilities()
	{
		if (bCapabilitiesBlocked)
			return;
			
		for (ASlotCarActor SlotCar : SlotCarTrack.SlotCars)
		{
			SlotCar.BlockCapabilities(n"SlotCar", this);
			bCapabilitiesBlocked = true;
		}
	}

	void UnblockSlotCarCapabilities()
	{
		if (!bCapabilitiesBlocked)
			return;

		for (ASlotCarActor SlotCar : SlotCarTrack.SlotCars)
		{
			SlotCar.UnblockCapabilities(n"SlotCar", this);
			bCapabilitiesBlocked = false;
		}
	}
}