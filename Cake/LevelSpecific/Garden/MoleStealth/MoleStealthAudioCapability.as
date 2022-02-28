import Cake.LevelSpecific.Garden.MoleStealth.MoleStealthSystem;

class UMoleStealthAudioCapability : UHazeCapability
{
	UMoleStealthPlayerComponent PlayerStealthComp;	
	AMoleStealthManager StealthManager;
	AHazePlayerCharacter PlayerOwner;	
	float WobbleValue = 0.f;	
	float SoundynessValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlayerOwner = Cast<AHazePlayerCharacter>(Owner);
		// PlayerStealthComponent is only on Cody
		if(!PlayerOwner.IsCody())
			return;

		PlayerStealthComp = UMoleStealthPlayerComponent::Get(Owner);		
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		// Only need this capability to run on one character
		if(IsActioning(n"MoleStealthActive") && PlayerOwner.IsCody())
     		return EHazeNetworkActivation::ActivateLocal;

		return EHazeNetworkActivation::DontActivate;
	}	

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{	
		// Fugly way of getting our StealthManager after we've activate
		if(StealthManager == nullptr)
		{
			StealthManager = PlayerStealthComp.CurrentManager;
			if(StealthManager != nullptr)
				StealthManager.OnDetected.AddUFunction(this, n"OnPlayersDetected");		
		}

		ConsumeAttribute(n"SoundMeterWobble", WobbleValue);
		//ConsumeAttribute(n"SoundMeterSoundyness", SoundynessValue);

		if(PlayerStealthComp.ActiveWidget != nullptr)
		{
			float RtpcValue = PlayerStealthComp.ActiveWidget.DetectionAmountAlpha + (WobbleValue * 0.01f);			

			// > 0.6 means in the red
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_Garden_MoleTunnels_SoundMeter_Level", RtpcValue);
		}
	}

	UFUNCTION()
	void OnPlayersDetected(AMoleStealthManager StealthManager)
	{		
		// PLAYERS DETECTED STINGER
	}
}