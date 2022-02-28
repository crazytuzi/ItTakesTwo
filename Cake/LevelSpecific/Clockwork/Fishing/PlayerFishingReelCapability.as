import Cake.LevelSpecific.Clockwork.Fishing.PlayerFishingComponent;
import Cake.LevelSpecific.Clockwork.Fishing.RodBase;
import Peanuts.ButtonMash.Default.ButtonMashDefault;

class UPlayerFishingReelCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerFishingReelCapability");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 150;

	AHazePlayerCharacter Player;
	UPlayerFishingComponent PlayerComp;
	ARodBase RodBase;

	FVector2D LeftInput;  
    float LeftRotationRate; 
    FVector2D RotatedPreviousLeftInput;

	UButtonMashDefaultHandle ButtonMashHandle;

	FHazeAcceleratedFloat NetAccelReel;
	float NetAlphaTarget;

	float NetworkTime;
	float NetRate = 0.4f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerFishingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.FishingState == EFishingState::Reeling)
	        return EHazeNetworkActivation::ActivateFromControl;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.FishingState != EFishingState::Reeling)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlayerComp.HideTutorialPrompt(Player);
		PlayerComp.HideCancelInteractionPrompt(Player);

		PlayerComp.AlphaMax = 1.f + PlayerComp.AlphaStartingValue;
		PlayerComp.AlphaPlayerReel = PlayerComp.AlphaStartingValue / PlayerComp.AlphaMax;
		NetAccelReel.SnapTo(PlayerComp.AlphaPlayerReel);

		PlayerComp.ShowCancelInteractionPrompt(Player);

		if (Player.IsUsingGamepad())
			PlayerComp.ShowRightTriggerReelPrompt(Player);

		RodBase = Cast<ARodBase>(PlayerComp.RodBase);
		RodBase.AudioStartReel();
		RodBase.AudioRodStruggleStart();

		RodBase.PlayVOReelFish(Player);

		if (!Player.IsUsingGamepad())
			ButtonMashHandle = StartButtonMashDefaultAttachToComponent(Player, RodBase.CurrentCatch.RootComponent, NAME_None, FVector::ZeroVector);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.StopForceFeedback(PlayerComp.ReelRumble, n"REEL_RUMBLE");
		RodBase.AudioEndReel();
		RodBase.AudioReelingStruggle(0.f);
		RodBase.AudioRodStruggleEnd();
		
		if (!Player.IsUsingGamepad())
			StopButtonMash(ButtonMashHandle);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		PlayerComp.HideTutorialPrompt(Player);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		CalculateStickRotation(DeltaTime);

		if (HasControl())
		{
			if (PlayerComp.AlphaPlayerReel <= 0.f)
			{
				PlayerComp.FishingState = EFishingState::Default;
				NetDisableControlAndRemoteCatch();
			}
		}

		RodBase.AudioReelingStruggle(1.f);
	}

	void CalculateStickRotation(float DeltaTime)
    {
		if (Player.IsUsingGamepad())
		{
			LeftInput = GetAttributeVector2D(AttributeVectorNames::LeftStickRaw);
			LeftRotationRate = RotatedPreviousLeftInput.DotProduct(LeftInput);
			RotatedPreviousLeftInput = FVector2D(LeftInput.Y, -LeftInput.X);

			PlayerComp.ReelingCatchInput.AccelerateTo(LeftRotationRate, 1.f, DeltaTime);

			if (LeftRotationRate > 0.f && LeftInput.Size() > 0.f)
				RodBase.AudioReelingCatch(LeftInput.Size());
			else
				RodBase.AudioReelingCatch(0.f);

			if (HasControl())
			{
				if (LeftRotationRate > 0.f && LeftInput.Size() > 0.f)
				{
					PlayerComp.AlphaPlayerReel += 0.0115f * LeftRotationRate;
				}
				else
				{
					float SpeedMultiplier = PlayerComp.AlphaPlayerReel * 0.0085f;
					SpeedMultiplier = FMath::Clamp(SpeedMultiplier, 0.002f, 0.0055f);
					PlayerComp.AlphaPlayerReel -= SpeedMultiplier;
				}

				NetworkTime -= DeltaTime;

				if (NetworkTime <= 0.f)
				{
					NetworkTime = NetRate;
					NetAlphaReel(PlayerComp.AlphaPlayerReel);
				}
			}
			else
			{
				NetAccelReel.AccelerateTo(NetAlphaTarget, 2.f, DeltaTime);
				PlayerComp.AlphaPlayerReel = NetAccelReel.Value;
			}
		}
		else
		{
			if (HasControl())
			{
				if (ButtonMashHandle.MashRateControlSide > 0.f)
				{
					PlayerComp.AlphaPlayerReel += 0.2f * DeltaTime;
				}
				else
				{
					float SpeedMultiplier = PlayerComp.AlphaPlayerReel * 0.011f;
					SpeedMultiplier = FMath::Clamp(SpeedMultiplier, 0.002f, 0.0055f);
					PlayerComp.AlphaPlayerReel -= SpeedMultiplier;
				}

				NetworkTime -= DeltaTime;

				if (NetworkTime <= 0.f)
				{
					NetworkTime = NetRate;
					NetAlphaReel(PlayerComp.AlphaPlayerReel);
				}
			}
			else
			{
				NetAccelReel.AccelerateTo(NetAlphaTarget, 2.f, DeltaTime);
				PlayerComp.AlphaPlayerReel = NetAccelReel.Value;				
			}
		}
    }

	UFUNCTION(NetFunction)
	void NetAlphaReel(float TargetValue)
	{
		NetAlphaTarget = TargetValue;
	}

	UFUNCTION(NetFunction)
	void NetDisableControlAndRemoteCatch()
	{
		RodBase.DisableCatch();
	}
}