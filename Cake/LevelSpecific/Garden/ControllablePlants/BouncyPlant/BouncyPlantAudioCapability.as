import Cake.LevelSpecific.Garden.ControllablePlants.BouncyPlant.BouncyPlant;
import Vino.Audio.Capabilities.AudioTags;
import Peanuts.Audio.AudioStatics;

class UBouncyPlantAudioCapability : UHazeCapability
{
	ABouncyPlant BouncyPlant;

	UPROPERTY(Category = "Events")
	UAkAudioEvent OnEnterPlantEvent;
	
	UPROPERTY(Category = "Events")
	UAkAudioEvent OnExitPlantEvent;

	UPROPERTY(Category = "Events")
	UAkAudioEvent OnExitSoilEvent;
	
	UPROPERTY(Category = "Events")
	UAkAudioEvent OnBounceChargeUpEvent;
	
	UPROPERTY(Category = "Events")
	UAkAudioEvent OnBounceReleaseEvent;

	UPROPERTY(Category = "Events")
	UAkAudioEvent OnOtherPlayerBounceEvent;

	UPROPERTY(Category = "Events")
	UAkAudioEvent SuperBounceOnPlantEvent;

	UPROPERTY(Category = "Events")
	UAkAudioEvent SuperBounceOnOtherPlayerEvent;

	AHazePlayerCharacter PlayerController;

	private bool bWasCharging = false;
	private bool bHasPlayedExit = false;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		BouncyPlant = Cast<ABouncyPlant>(Owner);
		PlayerController = Game::GetCody();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BouncyPlant.bActive)
			return EHazeNetworkActivation::DontActivate;
		
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerController.BlockCapabilities(AudioTags::PlayerAudioVelocityData, this);
		PlayerController.PlayerHazeAkComp.HazePostEvent(OnEnterPlantEvent);		
		bHasPlayedExit = false;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(BouncyPlant == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(bHasPlayedExit)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerController.UnblockCapabilities(AudioTags::PlayerAudioVelocityData, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(BouncyPlant.bIsCharging && !bWasCharging)
		{
			bWasCharging = true;
			PlayerController.PlayerHazeAkComp.HazePostEvent(OnBounceChargeUpEvent);
		}
		else if(!BouncyPlant.bIsCharging && bWasCharging)
		{
			bWasCharging = false;
			PlayerController.PlayerHazeAkComp.HazePostEvent(OnBounceReleaseEvent);
		}

		if(ConsumeAction(n"AudioPlayerBounced") == EActionStateStatus::Active)
		{
			PlayerController.OtherPlayer.PlayerHazeAkComp.HazePostEvent(OnOtherPlayerBounceEvent);
		}

		if(ConsumeAction(n"OnExitPlant") == EActionStateStatus::Active)
		{
			PlayerController.PlayerHazeAkComp.HazePostEvent(OnExitPlantEvent);
			if(OnExitSoilEvent == nullptr)
				bHasPlayedExit = true;
		}

		if(ConsumeAction(n"Audio_OnExitSoil") == EActionStateStatus::Active)
		{
			PlayerController.PlayerHazeAkComp.HazePostEvent(OnExitSoilEvent);
			bHasPlayedExit = true;
		}

		if(ConsumeAction(n"AudioSuperBounce") == EActionStateStatus::Active)
		{
			//PrintToScreenScaled("superbounce", 2.f, FLinearColor :: LucBlue, 2.f);
			PlayerController.PlayerHazeAkComp.HazePostEvent(SuperBounceOnPlantEvent);
			PlayerController.OtherPlayer.PlayerHazeAkComp.HazePostEvent(SuperBounceOnOtherPlayerEvent);
		}
	}
}