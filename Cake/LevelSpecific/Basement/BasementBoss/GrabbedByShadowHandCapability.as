import Peanuts.ButtonMash.Default.ButtonMashDefault;
import Peanuts.ButtonMash.Silent.ButtonMashSilent;
import Cake.LevelSpecific.Basement.BasementBoss.ShadowHand;
import Cake.LevelSpecific.Basement.BasementBoss.ShadowHandManager;
import Peanuts.Fades.FadeStatics;

class UGrabbedByShadowHandCapability : UHazeCapability
{
	/*default CapabilityTags.Add(n"ShadowHandGrab");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter MainPlayer;
	AParentBlob ParentBlob;
	AShadowHand CurrentShadowHand;
	AShadowHandManager ShadowHandManager;

	UButtonMashDefaultHandle MayButtonMashHandle;
	UButtonMashSilentHandle CodyButtonMashHandle;

	float TimeSinceHeartBeat = 0.f;
	float MashMultiplier = 0.035f;
	float Progress = 0.6f;

	bool bKilled = false;
	bool bThrown = false;

	float CurrentGlowValue = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ParentBlob = Cast<AParentBlob>(Owner);
		MainPlayer = Game::GetMay();
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"Grabbed"))
        	return EHazeNetworkActivation::ActivateFromControl;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"Grabbed"))
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (bKilled)
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TArray<AShadowHandManager> ShadowHandManagers;
		GetAllActorsOfClass(ShadowHandManagers);
		ShadowHandManager = ShadowHandManagers[0];

		CurrentShadowHand = Cast<AShadowHand>(GetAttributeObject(n"ShadowHand"));
		Owner.BlockCapabilities(CapabilityTags::Movement, this);

		System::SetTimer(this, n"AttachToHand", 0.05f, false);

		MainPlayer.PlayCameraShake(CurrentShadowHand.GrabbedConstantCamShake);

		Progress = 0.6f;

		TimeSinceHeartBeat = 0.f;
		CurrentGlowValue = 0.f;
		bThrown = false;
	}

	UFUNCTION()
	void AttachToHand()
	{
		Owner.AttachToComponent(CurrentShadowHand.GrabPoint, NAME_None, EAttachmentRule::SnapToTarget, EAttachmentRule::KeepWorld, EAttachmentRule::KeepWorld, false);
		MainPlayer.ApplyCameraSettings(CurrentShadowHand.GrabbedCamSettings, FHazeCameraBlendSettings(0.5f), this);

		MayButtonMashHandle = StartButtonMashDefaultAttachToComponent(Game::GetMay(), CurrentShadowHand.GrabPoint, NAME_None, FVector(0.f, 0.f, 75.f));
		CodyButtonMashHandle = StartButtonMashSilent(Game::GetCody());

		Progress = 0.6f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MainPlayer.StopAllCameraShakes();
		MainPlayer.ClearCameraSettingsByInstigator(this, 2.f);
		MainPlayer.ClearFieldOfViewByInstigator(this, 1.f);
		MainPlayer.ClearIdealDistanceByInstigator(this, 1.f);

		Owner.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Owner.UnblockCapabilities(CapabilityTags::Movement, this);

		StopButtonMash(MayButtonMashHandle);
		StopButtonMash(CodyButtonMashHandle);

		Material::SetScalarParameterValue(CurrentShadowHand.WorldParamCollection, n"BasementAshGlow", 0.f);

		if (bKilled)
		{
			ParentBlob.SetCapabilityActionState(n"Grabbed", EHazeActionState::Inactive);
			CurrentShadowHand.OnPlayersKilled.Broadcast(CurrentShadowHand);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (MayButtonMashHandle == nullptr || CodyButtonMashHandle == nullptr)
			return;

		if (ParentBlob.bBrothersMovementActive && MayButtonMashHandle.MashRateControlSide != 0)
		{
			Progress += MayButtonMashHandle.MashRateControlSide * MashMultiplier * 2 * DeltaTime;
		}

		if (MayButtonMashHandle.MashRateControlSide == 0 && CodyButtonMashHandle.MashRateControlSide == 0)
		{
			float DecaySpeed = CurrentShadowHand.HeartbeatDecayCurve.GetFloatValue(Progress);
			Progress -= DecaySpeed * DeltaTime;
		}
		else if (MayButtonMashHandle.MashRateControlSide > 0 && CodyButtonMashHandle.MashRateControlSide > 0)
		{
			float CurrentMashRate = MayButtonMashHandle.MashRateControlSide + CodyButtonMashHandle.MashRateControlSide;
			Progress += CurrentMashRate * MashMultiplier * DeltaTime;
		}

		float CurrentProgress = Progress;
		ShadowHandManager.UpdateButtonMashProgress(CurrentProgress);

		if (Progress >= 1 && !bThrown)
		{
			// CurrentShadowHand.ReleasePlayers();
			bThrown = true;
		}

		float HeartbeatInterval = FMath::Lerp(0.55f, 1.75f, CurrentProgress);

		TimeSinceHeartBeat += DeltaTime;
		if (TimeSinceHeartBeat >= HeartbeatInterval)
		{
			TimeSinceHeartBeat = 0.f;

			int HeartbeatForceFeedbackIndex = 0;
			if (CurrentProgress > 0.25f)
				HeartbeatForceFeedbackIndex = 1;
			if (CurrentProgress > 0.5f)
				HeartbeatForceFeedbackIndex = 2;
			if (CurrentProgress > 0.75f)
				HeartbeatForceFeedbackIndex = 3;

			MainPlayer.PlayForceFeedback(CurrentShadowHand.HeartbeatForceFeedbackEffects[HeartbeatForceFeedbackIndex], false, true, NAME_None);

			float CamShakeIntensity = CurrentShadowHand.HeartbeatCamShakeIntensityCurve.GetFloatValue(CurrentProgress);
			MainPlayer.PlayCameraShake(CurrentShadowHand.HeartbeatCamShake, CamShakeIntensity);
		}

		if (CurrentProgress <= 0 && !bKilled)
		{
			bKilled = true;
		}

		float TargetGlowValue = FMath::Lerp(3000.f, 0.f, CurrentProgress);
		CurrentGlowValue = FMath::FInterpTo(CurrentGlowValue, TargetGlowValue, DeltaTime, 5.f);
		Material::SetScalarParameterValue(CurrentShadowHand.WorldParamCollection, n"BasementAshGlow", CurrentGlowValue);
	}

	void UpdateCameraValues(float Progress)
	{
		float FoV = FMath::Lerp(110.f, 70.f, Progress);
		MainPlayer.ApplyFieldOfView(FoV, FHazeCameraBlendSettings(0.5f), this, EHazeCameraPriority::Maximum);

		float IdealDistance = FMath::Lerp(500.f, 1000.f, Progress);
		MainPlayer.ApplyIdealDistance(IdealDistance, FHazeCameraBlendSettings(0.5f), this, EHazeCameraPriority::Maximum);
	}*/
}