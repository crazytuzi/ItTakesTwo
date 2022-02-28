import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Vino.Movement.Capabilities.Swimming.SnowGlobeSwimmingComponent;

class UPlayerGenericMagnetCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::MagnetCapability);
	default CapabilityTags.Add(FMagneticTags::PlayerGenericMagnetCapability);

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 80;

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	AHazePlayerCharacter Player;
	UMagneticPlayerComponent PlayerMagnetComp;
	UHazeMovementComponent MoveComp;

	UMagnetGenericComponent ActivatedMagnet;
	FVector PreviousMagnetLocation;
	// bool bPlayedRumble = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;

		UMagnetGenericComponent CurrentTargetedMagnet = Cast<UMagnetGenericComponent>(PlayerMagnetComp.GetTargetedMagnet());
		if(CurrentTargetedMagnet == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!CurrentTargetedMagnet.IsInfluencedBy(Player))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(ActivatedMagnet.bIsDisabled)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Prevent Players from standing on top of the magnets owning actor and using it
		if(ActivatedMagnet.IsBlockedByStandingPlayer(Player))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Deactivate when player steps out of range
		if(DistanceToMagnet > ActivatedMagnet.DeactivationDistance)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		// Check Generic Magnet Settings
		if(ActivatedMagnet.GenericMagnetSettings != nullptr)
		{
			if(ActivatedMagnet.GenericMagnetSettings.bDeactivateWhenDistanceIsLongerThanCustomDistance)
			{
				if(DistanceToMagnet > ActivatedMagnet.GenericMagnetSettings.CustomDistance)
					return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			}
			if(ActivatedMagnet.GenericMagnetSettings.bOnlyBlockSamePolarityWhenInfluencing)
			{
				if(!PlayerMagnetComp.HasOppositePolarity(ActivatedMagnet) && ActivatedMagnet.IsMagneticPathBlocked(PlayerMagnetComp, ActivatedMagnet.GenericMagnetSettings.bIgnoreSelf))
					return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			}
			else if(ActivatedMagnet.GenericMagnetSettings.bDoExtraVisibilityCheckToBlockParents)
			{
				if(ActivatedMagnet.IsMagneticPathBlocked(PlayerMagnetComp, ActivatedMagnet.GenericMagnetSettings.bIgnoreSelf))
					return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			}
			if(ActivatedMagnet.GenericMagnetSettings.bCheckFreeSightWhenInfluencing)
			{
				if(!ActivatedMagnet.HasFreeSight(Player))
					return EHazeNetworkDeactivation::DeactivateUsingCrumb;
			}
		}

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		UMagnetGenericComponent CurrentTarget = Cast<UMagnetGenericComponent>(PlayerMagnetComp.GetTargetedMagnet());

		ActivationParams.AddObject(n"CurrentMagnet", CurrentTarget);

		// Only need to add this on the controlside
		CurrentTarget.ApplyControlInfluenser(PlayerMagnetComp, n"GenericActivation", 1, 0);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Active);

		ActivatedMagnet = Cast<UMagnetGenericComponent>(ActivationParams.GetObject(n"CurrentMagnet"));
		PlayerMagnetComp.ActivateMagnetLockon(ActivatedMagnet, this);

		AHazeActor MagnetOwner = Cast<AHazeActor>(ActivatedMagnet.Owner);
		if (MagnetOwner != nullptr)
			MagnetOwner.SetCapabilityActionState(n"MagneticInteraction", EHazeActionState::Active);

		ActivatedMagnet.OnGenericMagnetInteractionStateChanged.Broadcast(true, ActivatedMagnet, Player);

		if(ActivatedMagnet.GenericMagnetSettings != nullptr)
		{
			// if(ActivatedMagnet.GenericMagnetSettings.StartUpRumble != nullptr)
			// 	Player.PlayForceFeedback(ActivatedMagnet.GenericMagnetSettings.StartUpRumble, false, true, n"GenericMagnetInteractionStartup");

			if(ActivatedMagnet.GenericMagnetSettings.bShouldSlowPlayer)
				UMovementSettings::SetMoveSpeed(Player, ActivatedMagnet.GenericMagnetSettings.PlayerMovementSpeed, ActivatedMagnet);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// if(bPlayedRumble)
		// {
		// 	Player.StopForceFeedback(ActivatedMagnet.GenericMagnetSettings.ConstantRumble, n"GenericMagnetInteractionConstant");
		// 	bPlayedRumble = false;
		// }

		PlayerMagnetComp.DeactivateMagnetLockon(this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);
		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Inactive);

		ActivatedMagnet.OnGenericMagnetInteractionStateChanged.Broadcast(false, ActivatedMagnet, Player);

		AHazeActor MagnetOwner = Cast<AHazeActor>(ActivatedMagnet.Owner);
		if (MagnetOwner != nullptr)
		{
			TArray<AHazePlayerCharacter> InfluencingPlayers;
			ActivatedMagnet.GetInfluencingPlayers(InfluencingPlayers);
			if(!InfluencingPlayers.Contains(Player.OtherPlayer))
				MagnetOwner.SetCapabilityActionState(n"MagneticInteraction", EHazeActionState::Inactive);
		}

		// Clear magnet influencer and force delta
		ActivatedMagnet.RemoveInfluenser(Player, n"GenericActivation");
		PlayerMagnetComp.PlayerMagnet.ActivatedMagnetMovementDelta = 0.f;

		// Clear strafe state machine asset and mesh offset rotation
		Player.ClearLocomotionAssetByInstigator(this);
		Player.SetAnimFloatParam(n"MagnetAngle", 0.f);
		Player.MeshOffsetComponent.ResetRotationWithTime();

		Player.ClearCameraSettingsByInstigator(ActivatedMagnet);
		Player.ClearPointOfInterestByInstigator(ActivatedMagnet);
		Player.ClearSettingsByInstigator(ActivatedMagnet);

		ActivatedMagnet = nullptr;
		PreviousMagnetLocation = FVector::ZeroVector;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(ActivatedMagnet == nullptr)
			return;

		FVector PlayerToMagnet = (ActivatedMagnet.WorldLocation - Player.ActorLocation).GetSafeNormal();
		FVector ConstrainedPlayerToMagnet = PlayerToMagnet.ConstrainToPlane(Player.MovementWorldUp).GetSafeNormal();

		// Calculate force and update event value
		FVector DeltaVelocity = ActivatedMagnet.WorldLocation - PreviousMagnetLocation;
		PlayerMagnetComp.PlayerMagnet.ActivatedMagnetMovementDelta = DeltaVelocity.Size();
		PreviousMagnetLocation = ActivatedMagnet.WorldLocation;

		// if(ActivatedMagnet.GenericMagnetSettings == nullptr)
		// 	return;

		// if(!bPlayedRumble && ActivatedMagnet.GenericMagnetSettings.ConstantRumble != nullptr)
		// {
		// 	Player.PlayForceFeedback(ActivatedMagnet.GenericMagnetSettings.ConstantRumble, true, true, n"GenericMagnetInteractionConstant");
		// 	bPlayedRumble = true;
		// }
	}

	float GetDistanceToMagnet() const property
	{
		float Distance = PlayerMagnetComp.WorldLocation.Distance(ActivatedMagnet.WorldLocation);
		return Distance;
	}
}
