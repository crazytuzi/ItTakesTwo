import Cake.LevelSpecific.Clockwork.Fishing.PlayerFishingComponent;
import Cake.LevelSpecific.Clockwork.Fishing.WidgetFishingCatch;
import Cake.LevelSpecific.Clockwork.Fishing.RodBase;

class UPlayerFishingCatchingCapability : UHazeCapability
{
	default CapabilityTags.Add(n"PlayerFishingCatchingCapability");

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UPlayerFishingComponent PlayerComp;

	float MinCatchTime = 1.2f;
	float MaxCatchTime = 2.5f;
	float CatchTime;

	float MinReactionTime = 3.5f;
	float MaxReactionTime = 5.f;
	float ReactionTimeRate;
	float ReactionTime;

	ARodBase RodBase;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerComp = UPlayerFishingComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PlayerComp.FishingState == EFishingState::Catching)
	        return EHazeNetworkActivation::ActivateUsingCrumb;

        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PlayerComp.FishingState != EFishingState::Catching)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		RodBase = Cast<ARodBase>(PlayerComp.RodBase);
		CatchTime = FMath::RandRange(MinCatchTime, MaxCatchTime);
		ReactionTimeRate = FMath::RandRange(MinReactionTime, MaxReactionTime);

		PlayerComp.bCanCancelFishing = true;
		PlayerComp.ShowCancelInteractionPrompt(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		PlayerComp.bCatchIsHere = false;
		Player.StopForceFeedback(PlayerComp.ReelRumble, n"REEL_RUMBLE");
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		PlayerComp.bCatchIsHere = false;
		PlayerComp.HideTutorialPrompt(Player);
		PlayerComp.HideCancelInteractionPrompt(Player);
		Player.StopForceFeedback(PlayerComp.ReelRumble, n"REEL_RUMBLE");

		if (RodBase != nullptr)
			RodBase.AudioCatchOnLine(0.f);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		CatchTime -= DeltaTime;

		if (CatchTime > 0.f)
			return;

		if (!HasControl())
			return;
		
		if (!PlayerComp.bCatchIsHere)
		{
			NetCatchFish();
			Player.PlayForceFeedback(PlayerComp.ReelRumble, true, true, n"REEL_RUMBLE", 1.f);
			ReactionTime = System::GameTimeInSeconds + ReactionTimeRate;
			RodBase.AudioStartCatchOnLine();
		}
		else if (PlayerComp.bCatchIsHere)
		{
			RodBase.AudioCatchOnLine(1.f);
		}

		if (ReactionTime <= System::GameTimeInSeconds)
		{
			NetSetDefault();
			return;
		}

		if (WasActionStarted(ActionNames::ClockFishingCatch) && HasControl())
		{
			NetReeling();
			int RIndex = FMath::RandRange(0, RodBase.FishingCatchManager.CatchObjectArray.Num() - 1);
			RodBase.NetEnableAndAttachCatch(RIndex);
		}
	}

	UFUNCTION(NetFunction)
	void NetCatchFish()
	{
		PlayerComp.ShowCatchFishPrompt(Player);
		PlayerComp.bCatchIsHere = true;
	}

	UFUNCTION(NetFunction)
	void NetReeling()
	{
		PlayerComp.FishingState = EFishingState::Reeling;
	}

	UFUNCTION(NetFunction)
	void NetSetDefault()
	{
		PlayerComp.FishingState = EFishingState::Default;
	}
}