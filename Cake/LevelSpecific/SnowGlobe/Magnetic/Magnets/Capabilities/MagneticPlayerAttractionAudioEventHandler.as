import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.Capabilities.MagnetAudioEventHandler;

class UMagneticPlayerAttractionAudioEventHandler : UMagnetAudioEventHandler
{
	default CapabilityTags.Remove(n"MagnetAudioEventHandlerBase");
	/**
	* Inherited variables
	*
	* 	+ APlayerMagnetActor MagnetOwner
	*	+ AHazePlayerCharacter PlayerCharacter
	*
	* 	+ UPlayerHazeAkComponent HazeAkComp
	*	+ UMagneticPlayerComponent PlayerMagnetComp
	*/

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) override
	{
		Owner.BlockCapabilities(n"MagnetAudioEventHandlerBase", this);

		Super::OnActivated(ActivationParams);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams) override
	{
		Owner.UnblockCapabilities(n"MagnetAudioEventHandlerBase", this);
		Super::OnDeactivated(DeactivationParams);
	}

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnBothPlayersAttractedEvent;

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Super::TickActive(DeltaTime);
	}

	// Player started charging magnet
	UFUNCTION(BlueprintOverride)
	void OnMPAChargeStarted() 
	{
		OnLaunchChargeStarted();
	}

	// Player charged magnet
	UFUNCTION(BlueprintOverride)
	void OnMPAChargeDone()
	{ 
		OnLaunchChargeDone();
	}

	// Player cancelled magnet charge
	UFUNCTION(BlueprintOverride)
	void OnMPAChargeCancelled() 
	{
		OnLaunchChargeCancelled();
	}

	// Launch charge completed and player is flying towards other player
	UFUNCTION(BlueprintOverride)
	void OnMPALaunch()
	{
		OnLaunch();
	}

	// Flying towards other player is done and player is attached to other player
	UFUNCTION(BlueprintOverride)
	void OnMPAPerchStarted() 
	{
		OnMagnetPerchStarted();
	}

	// Player is dettaching and jumping away from other player
	UFUNCTION(BlueprintOverride)
	void OnMPAPerchDone() 
	{
		OnMagnetPerchDone();
	}

	// Both players met after launching towards each other
	UFUNCTION(BlueprintOverride)
	void OnMPAPlayersConverged()
	{
		PrintScaled("BAM! Both players attracted", 1.f, FLinearColor::Black, 2.f);

		HazeAkComp.HazePostEvent(OnBothPlayersAttractedEvent);
	}
}