import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerMagnetActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerAttraction.MagneticPlayerAttractionComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPerchAndBoostComponent;

class UMagnetEventHandler : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::Magnetic);
	default CapabilityTags.Add(FMagneticTags::MagnetCapability);
	default CapabilityTags.Add(FMagneticTags::MagnetEventHandlerCapability);

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	APlayerMagnetActor MagnetOwner;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	AHazePlayerCharacter PlayerCharacter;

	// -1 for pulling, 0 for idle and 1 for pushing
	UPROPERTY(BlueprintReadOnly, NotEditable)
	EPlayerMagnetState PlayerMagnetState = EPlayerMagnetState::Idle;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MagnetOwner = Cast<APlayerMagnetActor>(Owner);
		PlayerCharacter = MagnetOwner.OwningPlayer;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MagnetOwner.OnMagnetActivated.AddUFunction(this, n"OnMagnetActivated");
		MagnetOwner.OnMagnetDeactivated.AddUFunction(this, n"OnMagnetDeactivated");

		MagnetOwner.OnMagnetVisualStarted.AddUFunction(this, n"OnMagnetVisualStarted");
		MagnetOwner.OnMagnetVisualStopped.AddUFunction(this, n"OnMagnetVisualStopped");
		MagnetOwner.OnTargetMagnetChanged.AddUFunction(this, n"OnTargetMagnetChanged");

		MagnetOwner.OnLaunchChargeStarted.AddUFunction(this, n"OnLaunchChargeStarted");
		MagnetOwner.OnLaunchChargeDone.AddUFunction(this, n"OnLaunchChargeDone");
		MagnetOwner.OnLaunchChargeCancelled.AddUFunction(this, n"OnLaunchChargeCancelled");

		MagnetOwner.OnLaunch.AddUFunction(this, n"OnLaunch");
		MagnetOwner.OnLaunchDone.AddUFunction(this, n"OnLaunchDone");

		MagnetOwner.OnMagnetPerchStarted.AddUFunction(this, n"OnMagnetPerchStarted");
		MagnetOwner.OnMagnetPerchPositionChange.AddUFunction(this, n"OnMagnetPerchPositionChange");
		MagnetOwner.OnMagnetPerchDone.AddUFunction(this, n"OnMagnetPerchDone");

		MagnetOwner.OnBoostChargeStarted.AddUFunction(this, n"OnBoostChargeStarted");
		MagnetOwner.OnBoostChargeCancelled.AddUFunction(this, n"OnBoostChargeCancelled");
		MagnetOwner.OnBoost.AddUFunction(this, n"OnBoost");

		MagnetOwner.OnMagnetPushStarted.AddUFunction(this, n"OnMagnetPushStarted");
		MagnetOwner.OnMagnetPushStopped.AddUFunction(this, n"OnMagnetPushStopped");

		MagnetOwner.OnMagnetPullStarted.AddUFunction(this, n"OnMagnetPullStarted");
		MagnetOwner.OnMagnetPullStopped.AddUFunction(this, n"OnMagnetPullStopped");

		MagnetOwner.OnMagnetBadInteraction.AddUFunction(this, n"OnBadMagnetInteraction");

		MagnetOwner.OnMPAChargeStarted.AddUFunction(this, n"OnMPAChargeStarted");
		MagnetOwner.OnMPAChargeDone.AddUFunction(this, n"OnMPAChargeDone");
		MagnetOwner.OnMPAChargeCancelled.AddUFunction(this, n"OnMPAChargeCancelled");
		MagnetOwner.OnMPALaunch.AddUFunction(this, n"OnMPALaunch");
		MagnetOwner.OnMPAPerchStarted.AddUFunction(this, n"OnMPAPerchStarted");
		MagnetOwner.OnMPAPerchDone.AddUFunction(this, n"OnMPAPerchDone");
		MagnetOwner.OnMPAPlayersConverged.AddUFunction(this, n"OnMPAPlayersConverged");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MagnetOwner.OnMagnetActivated.Unbind(this, n"OnMagnetActivated");
		MagnetOwner.OnMagnetDeactivated.Unbind(this, n"OnMagnetDeactivated");

		MagnetOwner.OnMagnetVisualStarted.Unbind(this, n"OnMagnetVisualStarted");
		MagnetOwner.OnMagnetVisualStopped.Unbind(this, n"OnMagnetVisualStopped");
		MagnetOwner.OnTargetMagnetChanged.Unbind(this, n"OnTargetMagnetChanged");

		MagnetOwner.OnLaunchChargeStarted.Unbind(this, n"OnLaunchChargeStarted");
		MagnetOwner.OnLaunchChargeDone.Unbind(this, n"OnLaunchChargeDone");
		MagnetOwner.OnLaunchChargeCancelled.Unbind(this, n"OnLaunchChargeCancelled");

		MagnetOwner.OnLaunch.Unbind(this, n"OnLaunch");
		MagnetOwner.OnLaunchDone.Unbind(this, n"OnLaunchDone");

		MagnetOwner.OnMagnetPerchStarted.Unbind(this, n"OnMagnetPerchStarted");
		MagnetOwner.OnMagnetPerchPositionChange.Unbind(this, n"OnMagnetPerchPositionChange");
		MagnetOwner.OnMagnetPerchDone.Unbind(this, n"OnMagnetPerchDone");

		MagnetOwner.OnBoostChargeStarted.Unbind(this, n"OnBoostChargeStarted");
		MagnetOwner.OnBoostChargeCancelled.Unbind(this, n"OnBoostChargeCancelled");
		MagnetOwner.OnBoost.Unbind(this, n"OnBoost");

		MagnetOwner.OnMagnetPushStarted.Unbind(this, n"OnMagnetPushStarted");
		MagnetOwner.OnMagnetPushStopped.Unbind(this, n"OnMagnetPushStopped");

		MagnetOwner.OnMagnetPullStarted.Unbind(this, n"OnMagnetPullStarted");
		MagnetOwner.OnMagnetPullStopped.Unbind(this, n"OnMagnetPullStopped");

		MagnetOwner.OnMagnetBadInteraction.Unbind(this, n"OnBadMagnetInteraction");

		MagnetOwner.OnMPAChargeStarted.Unbind(this, n"OnMPAChargeStarted");
		MagnetOwner.OnMPAChargeDone.Unbind(this, n"OnMPAChargeDone");
		MagnetOwner.OnMPAChargeCancelled.Unbind(this, n"OnMPAChargeCancelled");
		MagnetOwner.OnMPALaunch.Unbind(this, n"OnMPALaunch");
		MagnetOwner.OnMPAPerchStarted.Unbind(this, n"OnMPAPerchStarted");
		MagnetOwner.OnMPAPerchDone.Unbind(this, n"OnMPAPerchDone");
		MagnetOwner.OnMPAPlayersConverged.Unbind(this, n"OnMPAPlayersConverged");
	}

	// MAGNET ACTUATING /////////////////////////////
	// Player started actuating some magnet
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetActivated(UMagneticComponent Magnet, bool bEqualPolarities)
	{
		// Eman TODO: Expose list of types if we require more
		if(Magnet.IsA(UMagneticPlayerAttractionComponent::StaticClass()) || Magnet.IsA(UMagneticPerchAndBoostComponent::StaticClass()))
			return;

		if(bEqualPolarities)
		{
			MagnetOwner.MagnetState = EPlayerMagnetState::Pushing;
			MagnetOwner.OnMagnetPushStarted.Broadcast();
		}
		else
		{
			MagnetOwner.MagnetState = EPlayerMagnetState::Pulling;
			MagnetOwner.OnMagnetPullStarted.Broadcast();
		}
	}

	// Player stopped actuating magnet
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetDeactivated(UMagneticComponent Magnet, bool bEqualPolarities)
	{
		// Eman TODO: Expose list of types if we require more
		if(Magnet.IsA(UMagneticPlayerAttractionComponent::StaticClass()) || Magnet.IsA(UMagneticPerchAndBoostComponent::StaticClass()))
			return;

		if(bEqualPolarities)
			MagnetOwner.OnMagnetPushStopped.Broadcast();
		else
			MagnetOwner.OnMagnetPullStopped.Broadcast();

		MagnetOwner.MagnetState = EPlayerMagnetState::Idle;
	}


	// TARGETING ////////////////////////////////////
	// Player started targetting a magnet
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetVisualStarted() { }

	// Player stopped targetting magnet
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetVisualStopped() { }

	// Player changed magnet target without stopping
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnTargetMagnetChanged() { }


	// LAUNCHING ////////////////////////////////////
	// Player started charging magnet launch
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnLaunchChargeStarted() { }

	// Player completed charge
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnLaunchChargeDone() { }

	// Player cancelled magnet launch
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnLaunchChargeCancelled() { }

	// Launch charge completed and player is flying towards magnet
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnLaunch() { }

	// Player arrived to magnet
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnLaunchDone() { }


	// PERCHING ////////////////////////////////////
	// Flying towards magnet (magnet launch) is done and player is attached to magnet
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetPerchStarted() { }

	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetPerchPositionChange() { }

	// Player is dettaching and jumping away from magnet perch
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetPerchDone() { }


	// BOOST ////////////////////////////////////////
	// Player started charging boost
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnBoostChargeStarted() { }

	// Boost charge was cancelled by player
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnBoostChargeCancelled() { }

	// Boost charge is done and player is now boosting away!
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnBoost() { }


	// PUSH /////////////////////////////////////////
	// Player is pushing object with magnet
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetPushStarted() { }

	// Magnet pushing stopped
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetPushStopped() { }


	// PULL /////////////////////////////////////////
	// Player is pulling object with magnet
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetPullStarted() { }

	// Magnet pulling stopped
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMagnetPullStopped() { }


	// MISC /////////////////////////////////////////
	// Wrong player is interacting with magnet
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnBadMagnetInteraction() { }


	// MAGNETIC PLAYER ATTRACTION ///////////////////
	// Player started charging magnet
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMPAChargeStarted() { }

	// Player charged magnet
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMPAChargeDone() { }

	// Charging was cancelled
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMPAChargeCancelled() { }

	// Player started launching towards other player
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMPALaunch() { }

	// Player reached other player and will start piggybacking
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMPAPerchStarted() { }

	// Player will jump away from other player
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMPAPerchDone() { }

	// Both players launched to each other and reached the meeting point
	UFUNCTION(BlueprintEvent, meta=(AutoCreateBPNode))
	void OnMPAPlayersConverged() { }
}