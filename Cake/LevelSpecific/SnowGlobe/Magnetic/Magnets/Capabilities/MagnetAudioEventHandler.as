import Cake.LevelSpecific.Snowglobe.Magnetic.Magnets.Capabilities.MagnetEventHandler;
import Cake.LevelSpecific.Snowglobe.Magnetic.PlayerMagnetActor;
import Cake.LevelSpecific.Snowglobe.Magnetic.Magnets.MagneticPlayerComponent;
import Peanuts.Audio.AudioStatics;

class UMagnetAudioEventHandler : UMagnetEventHandler
{
	default CapabilityTags.Add(FMagneticTags::MagnetAudioEventHandlerCapability);
	default CapabilityTags.Add(n"MagnetAudioEventHandlerBase");

	/**
	* Inherited variables
	*
	* 	+ APlayerMagnetActor MagnetOwner
	*	+ AHazePlayerCharacter PlayerCharacter
	*/

	UPROPERTY(BlueprintReadOnly, NotEditable)
	UPlayerHazeAkComponent HazeAkComp;

	UMagneticPlayerComponent PlayerMagnetComp;
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartPullEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopPullEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StartPushEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopPushEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ChangeUpStartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ChangeUpStopEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnLaunchSuperMagnetMayEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnLaunchSuperMagnetCodyEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnLaunchInAirStartEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnLaunchInAirStopEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnLandSuperMagnetEvent;

	FHazeAudioEventInstance InAirLoopInstance;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);

		HazeAkComp = UPlayerHazeAkComponent::Get(PlayerCharacter);
		PlayerMagnetComp = UMagneticPlayerComponent::Get(PlayerCharacter);

		if(PlayerCharacter != nullptr)
		{
			HazeAudio::SetPlayerPanning(HazeAkComp, PlayerCharacter);
		}	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);

		if (InAirLoopInstance.PlayingID != 0)
			HazeAkComp.HazePostEvent(OnLaunchInAirStopEvent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Add value for distance to attached object: 0 close - 1 furthest.
		HazeAkComp.SetRTPCValue("Rtpc_Gadget_Magnets_DistanceToAttachedObject", MagnetOwner.NormalDistanceToTargetMagnet, 0.f);
		//Print("MagnetDistanceToAttachedObject: " + MagnetOwner.NormalDistanceToTargetMagnet);

		// Add value for charge time: 0 non - 1 full.
		HazeAkComp.SetRTPCValue("Rtpc_Gadget_Magnets_ChargeTimer", MagnetOwner.MagnetChargeProgress, 0.f);
		// Print("MagnetChargeTime: " + MagnetOwner.MagnetChargeProgress);
		
		// Add value for if pull ilde push: pull = -1, Idle = 0, Push = +1.	
		HazeAkComp.SetRTPCValue("Rtpc_Gadget_Magnets_PullIdlePush", MagnetOwner.GetMagnetStateAsFloat(), 0.f);
		// Print("MagnetState: " + MagnetOwner.GetMagnetStateAsFloat());

		HazeAkComp.SetRTPCValue("Rtpc_Gadget_Magnets_LaunchProgress", MagnetOwner.MagnetLaunchProgress, 0.f);
		// Print("MagnetLaunchProgress: " + MagnetOwner.MagnetLaunchProgress);

		// Magnet's delta movement this frame
		HazeAkComp.SetRTPCValue("Rtpc_Gadget_Magnets_MovementDelta", MagnetOwner.ActivatedMagnetMovementDelta, 0.f);
		//Print("MagnetDelta: " + MagnetOwner.ActivatedMagnetMovementDelta);
	}

	// TARGETING ////////////////////////////////////
	// Player started targetting a magnet
	UFUNCTION(BlueprintOverride)
	void OnMagnetVisualStarted() 
	{ 
		// PrintScaled("MagnetStart", 1.f, FLinearColor::Green, 2.f);

		HazeAkComp.HazePostEvent(StartEvent);
	}

	// Player stopped targetting magnet
	UFUNCTION(BlueprintOverride)
	void OnMagnetVisualStopped() 
	{
		// PrintScaled("MagnetStop", 1.f, FLinearColor::Red, 2.f);

		HazeAkComp.HazePostEvent(StopEvent);
	}

	// Player changed magnet target without stopping
	UFUNCTION(BlueprintOverride)
	void OnTargetMagnetChanged() 
	{
		// PrintScaled("MagnetChanged", 1.f, FLinearColor::Blue, 2.f);
	}


	// LAUNCHING ////////////////////////////////////
	// Player started charging magnet launch
	UFUNCTION(BlueprintOverride)
	void OnLaunchChargeStarted() 
	{ 
		// PrintScaled(PlayerCharacter.Name + " ChargeStarted", 1.f, FLinearColor::Green, 2.f);

		HazeAkComp.HazePostEvent(ChangeUpStartEvent);
	}

	// Player completed charge
	UFUNCTION(BlueprintOverride)
	void OnLaunchChargeDone()
	{
		//PrintScaled("ChargeDone", 1.f, FLinearColor::Red, 2.f);

		HazeAkComp.HazePostEvent(ChangeUpStopEvent);
	}

	// Player cancelled magnet charge
	UFUNCTION(BlueprintOverride)
	void OnLaunchChargeCancelled() 
	{ 
		// PrintScaled("ChargeCancelled", 1.f, FLinearColor::Red, 2.f);

		HazeAkComp.HazePostEvent(ChangeUpStopEvent);
	}

	// Launch charge completed and player is flying towards magnet
	UFUNCTION(BlueprintOverride)
	void OnLaunch() 
	{ 
		// PrintScaled("Launch", 1.f, FLinearColor::Black, 2.f);
		InAirLoopInstance = HazeAkComp.HazePostEvent(OnLaunchInAirStartEvent);
	}

	// Player arrived to magnet
	UFUNCTION(BlueprintOverride)
	void OnLaunchDone()
	{
		// PrintScaled("OnLaunchDone", 1.f, FLinearColor::Black, 2.f);

		InAirLoopInstance = Audio::EmptyEventInstance;
		HazeAkComp.HazePostEvent(OnLaunchInAirStopEvent);
	}

	// Flying towards magnet (magnet launch) is done and player is attached to magnet
	UFUNCTION(BlueprintOverride)
	void OnMagnetPerchStarted() 
	{
		// PrintScaled("OnLandSuperMagnet", 1.f, FLinearColor::Black, 2.f);

		HazeAkComp.HazePostEvent(OnLandSuperMagnetEvent);
	}

	UFUNCTION(BlueprintOverride)
	void OnMagnetPerchPositionChange() 
	{
		// PrintScaled("PerchPosChange", 1.f, FLinearColor::Black, 2.f);
	}


	// Player is dettaching and jumping away from magnet perch
	UFUNCTION(BlueprintOverride)
	void OnMagnetPerchDone() 
	{ 
		// PrintScaled("PerchDone", 1.f, FLinearColor::Black, 2.f);
	}

	// BOOST ////////////////////////////////////////
	// Player started charging boost
	UFUNCTION(BlueprintOverride)
	void OnBoostChargeStarted()
	{
		// PrintScaled("BoostChargeStart", 1.f, FLinearColor::Black, 2.f);

		HazeAkComp.HazePostEvent(ChangeUpStartEvent);
	}

	// Boost charge was cancelled by player
	UFUNCTION(BlueprintOverride)
	void OnBoostChargeCancelled() 
	{ 
		// PrintScaled("BoostCancel", 1.f, FLinearColor::Black, 2.f);

		HazeAkComp.HazePostEvent(ChangeUpStopEvent);
	}

	// Boost charge is done and player is now boosting away!
	UFUNCTION(BlueprintOverride)
	void OnBoost() 
	{ 
		// PrintScaled("OnLaunchSuperMagnet", 1.f, FLinearColor::Black, 2.f);

		HazeAkComp.HazePostEvent(ChangeUpStopEvent);

		if(PlayerCharacter.IsCody())
			HazeAkComp.HazePostEvent(OnLaunchSuperMagnetCodyEvent);
		else
			HazeAkComp.HazePostEvent(OnLaunchSuperMagnetMayEvent);
	}


	// PUSH /////////////////////////////////////////
	// Player is pushing object with magnet
	UFUNCTION(BlueprintOverride)
	void OnMagnetPushStarted() 
	{ 
		// PrintScaled("PushStart", 1.f, FLinearColor::Black, 2.f);
		
		HazeAkComp.HazePostEvent(StartPushEvent);
	}

	// Magnet pushing stopped
	UFUNCTION(BlueprintOverride)
	void OnMagnetPushStopped() 
	{ 
		// PrintScaled("PushStop", 1.f, FLinearColor::Black, 2.f);

		HazeAkComp.HazePostEvent(StopPushEvent);
	}


	// PULL /////////////////////////////////////////
	// Player is pulling object with magnet
	UFUNCTION(BlueprintOverride)
	void OnMagnetPullStarted() 
	{ 
		// PrintScaled("PullStart", 1.f, FLinearColor::Black, 2.f);
		
		HazeAkComp.HazePostEvent(StartPullEvent);
	}

	// Magnet pulling stopped
	UFUNCTION(BlueprintOverride)
	void OnMagnetPullStopped() 
	{ 
		//PrintScaled("PullStop", 1.f, FLinearColor::Black, 2.f);
		
		HazeAkComp.HazePostEvent(StopPullEvent);
	}


	// MAGNETIC PLAYER ATTRACTION ///////////////////
	// Player started charging magnet
	UFUNCTION(BlueprintOverride)
	void OnMPAChargeStarted() { }

	// Player charged magnet
	UFUNCTION(BlueprintOverride)
	void OnMPAChargeDone() { }

	// Player cancelled magnet charge
	UFUNCTION(BlueprintOverride)
	void OnMPAChargeCancelled() { }

	// Launch charge completed and player is flying towards other player
	UFUNCTION(BlueprintOverride)
	void OnMPALaunch() { }

	// Flying towards other player is done and player is attached to other player
	UFUNCTION(BlueprintOverride)
	void OnMPAPerchStarted() { }

	// Player is dettaching and jumping away from other player
	UFUNCTION(BlueprintOverride)
	void OnMPAPerchDone() { }

	// Both players met after launching towards each other
	UFUNCTION(BlueprintOverride)
	void OnMPAPlayersConverged() { }


	// MISC /////////////////////////////////////////
	// Wrong player is interacting with magnet
	UFUNCTION(BlueprintOverride)
	void OnBadMagnetInteraction() { }
}