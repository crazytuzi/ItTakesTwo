import Cake.LevelSpecific.Music.NightClub.DJVinylPlayer;
import Cake.LevelSpecific.Music.NightClub.DJStationComponent;
import Peanuts.ButtonMash.Silent.ButtonMashSilent;

class DJStationCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"LevelSpecific";
	default CapabilityTags.Add(n"DJStationCapability");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;

	ADJVinylPlayer VinylPlayer;
	
	UDJStationComponent DJStationComp;

	UButtonMashSilentHandle Handle;

	float CurrentMashrate = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		DJStationComp = UDJStationComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(DJStationComp.VinylPlayer != nullptr)
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
			
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(DJStationComp.VinylPlayer == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(DJStationComp.VinylPlayer != VinylPlayer)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	bool RemoteAllowShouldActivate(FCapabilityRemoteValidationParams ActivationParams) const
	{
		return DJStationComp != nullptr && DJStationComp.VinylPlayer != nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Handle = StartButtonMashSilent(Player);
		VinylPlayer = Cast<ADJVinylPlayer>(DJStationComp.VinylPlayer);
		VinylPlayer.OnPlayerInteractionBegin(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		VinylPlayer.OnPlayerInteractionEnd(Player);
	}
/*
	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(HasControl())
		{
			CurrentMashrate = Handle.MashRateControlSide;
		
			//VinylPlayer.AddToProgressRate(Handle.MashRateControlSide);
			//VinylPlayer.ButtonMashRate += CurrentMashrate;

			if (WasActionStarted(ActionNames::ButtonMash))
				VinylPlayer.ButtonMashPulse();
		}
	}
	*/
}