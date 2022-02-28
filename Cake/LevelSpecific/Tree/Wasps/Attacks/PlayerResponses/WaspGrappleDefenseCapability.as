import Peanuts.ButtonMash.Progress.ButtonMashProgress;
import Peanuts.ButtonMash.ButtonMashStatics;
import Cake.LevelSpecific.Tree.Wasps.Animation.LocomotionFeatureHeroWasp;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourComponent;
import Cake.LevelSpecific.Tree.Wasps.Animation.WaspAnimationComponent;

class UWaspGrappleDefenseCapability : UHazeCapability
{
	default CapabilityTags.Add(n"WaspGrapple");
	default CapabilityDebugCategory = n"WaspResponses";
	default TickGroup = ECapabilityTickGroups::GamePlay;

    ULocomotionFeatureHeroWasp AnimFeature;
	AHazePlayerCharacter Player = nullptr;
	AHazeActor Attacker = nullptr;
	UButtonMashProgressHandle ButtonMashHandle;

	float ButtonMashProgress = 0.99f;
	float ButtonMashStrength = 1.f;
	float ButtonMashDecreaseRate = 0.5f;
	float WeightedMashRate = 0.f;
	float ButtonMashIncreaseRate = 0.f;
	float ButtonMashIncreaseRateMultiplier = 0.f;
	bool bStruggling = false;
	bool bFailed = false;
	float CompleteTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(GetAttributeObject(n"GrapplingWasp") != nullptr)
        	return EHazeNetworkActivation::ActivateUsingCrumb;
		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if ((CompleteTime != 0.f) && (Time::GetGameTimeSeconds() > CompleteTime))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"Attacker", GetAttributeObject(n"GrapplingWasp"));
		ActivationParams.AddVector(n"Force", UHazeBaseMovementComponent::Get(Attacker).GetVelocity());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Attacker = Cast<AHazeActor>(ActivationParams.GetObject(n"Attacker"));
		AnimFeature = UWaspAnimationComponent::Get(Attacker).AnimFeature;
		bFailed = false;
		bStruggling = false;
		CompleteTime = 0.f;

        Player.BlockCapabilities(n"MovementInput", this);
        Player.BlockCapabilities(n"Weapon", this);

        FHazeAnimationDelegate OnStartAnimDone;
        OnStartAnimDone.BindUFunction(this, n"OnAnimGrappleStartDone");
	    Player.PlaySlotAnimation(OnBlendingOut = OnStartAnimDone, Animation = AnimFeature.Grapple_Enter.GetPlayerAnimation(Player));

		Player.ApplyCameraSettings(AnimFeature.Grapple_CameraSettings, FHazeCameraBlendSettings(1.f), this);

		// Give us a wallop so we'll slide a bit
        FVector ImpactForce = ActivationParams.GetVector(n"Force");
		ImpactForce.Z = 1700.f;
		Player.AddImpulse(ImpactForce);
	}

	UFUNCTION()
	void OnAnimGrappleStartDone()
	{
	    if (IsActive())
		{
			Player.PlaySlotAnimation(Animation = AnimFeature.Grapple_MH.GetPlayerAnimation(Player), bLoop = true);
	        ButtonMashHandle = StartButtonMashProgressAttachToActor(Player, Player, FVector(0,0,100));
			bStruggling = true;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ButtonMashProgress = 0.99f;
		ButtonMashStrength = 1.f;
		ButtonMashDecreaseRate = 0.5f;
		WeightedMashRate = 0.f;
		ButtonMashIncreaseRate = 0.f;
		ButtonMashIncreaseRateMultiplier = 0.f;
		Player.ClearCameraSettingsByInstigator(this);
		Player.SetCapabilityAttributeObject(n"GrapplingWasp", nullptr);
		Player.StopAllSlotAnimations();
        Player.UnblockCapabilities(n"MovementInput", this);
        Player.UnblockCapabilities(n"Weapon", this);
		if (bStruggling)
			StopButtonMash(ButtonMashHandle);
	}

	void OnDefenseSuccess()
	{
		if (bStruggling)
			StopButtonMash(ButtonMashHandle);

		UAnimSequence SuccessAnim = AnimFeature.Grapple_Aborted.GetPlayerAnimation(Player);
		Player.PlaySlotAnimation(Animation = SuccessAnim);

		CompleteTime = Time::GetGameTimeSeconds() + SuccessAnim.SequenceLength - 0.2f;
		bStruggling = false;
		Player.ClearCameraSettingsByInstigator(this);
	}

    void OnDefenseFailed()
    {
		bFailed = true;
		if (bStruggling)
			StopButtonMash(ButtonMashHandle);

		UAnimSequence FailAnim = AnimFeature.Grapple_Kill.GetPlayerAnimation(Player);
		Player.PlaySlotAnimation(Animation = FailAnim);
		
		CompleteTime = Time::GetGameTimeSeconds() + FailAnim.SequenceLength - 0.2f;
		bStruggling = false;

		// Let attacker know we've failed
		Attacker.SetCapabilityAttributeValue(n"WaspGrappleDefenseFailTime", Time::GetGameTimeSeconds());
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (bFailed)
			return;

		if (bStruggling)
		{
			if(GetAttributeObject(n"GrapplingWasp") == nullptr)
			{
				OnDefenseSuccess();
			}
			else
			{
				UpdateButtonMashProgress(DeltaTime);
				if (ButtonMashProgress < 0.f)
					OnDefenseFailed();
			}
		}
	}

	void UpdateButtonMashProgress(float DeltaTime)
	{
		ButtonMashStrength = ButtonMashStrength - (0.1f * DeltaTime);
		WeightedMashRate = ButtonMashHandle.MashRateControlSide * ButtonMashStrength;
		ButtonMashIncreaseRateMultiplier = FMath::GetMappedRangeValueClamped(FVector2D(0,1), FVector2D(5,0.5), ButtonMashProgress);
		ButtonMashIncreaseRate = FMath::GetMappedRangeValueClamped(FVector2D(0, 5), FVector2D(0, ButtonMashDecreaseRate * ButtonMashIncreaseRateMultiplier), WeightedMashRate);
		ButtonMashProgress = (ButtonMashProgress - (ButtonMashDecreaseRate * DeltaTime) + (ButtonMashIncreaseRate * DeltaTime));
		ButtonMashHandle.Progress = ButtonMashProgress;
	}
}