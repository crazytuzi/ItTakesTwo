import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyPlayerComponent;
import Cake.LevelSpecific.Hopscotch.Hazeboy.HazeboyManager;

class UHazeboyPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::ActiveGameplay);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	UPROPERTY()
	FText GiveUpText = NSLOCTEXT("Hazeboy", "GiveUp", "Give Up");

	AHazePlayerCharacter Player;
	UHazeboyPlayerComponent HazeboyComp;
	// AHazeboyManager
	AHazeboy Hazeboy;
	bool bShowingCancelWidget = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HazeboyComp = UHazeboyPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (HazeboyComp.CurrentDevice == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (HazeboyComp.CurrentDevice == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (HazeboyComp.bHasCancelled)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if (HazeboyGameHasEnded())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		auto Manager = GetHazeboyManager();
		Manager.DoubleInteract.StartInteracting(Player);

		Hazeboy = HazeboyComp.CurrentDevice;
		Hazeboy.TargetTank.SetControlSide(Owner);
		Hazeboy.TargetTank.OwningPlayer = Player;
		Hazeboy.InteractionComp.Disable(n"Busy");

		Player.CleanupCurrentMovementTrail();
		Player.BlockMovementSyncronization(this);

		Player.BlockCapabilities(n"PlayerMarker", this);
		Player.BlockCapabilities(CameraTags::FindOtherPlayer, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);

		Player.ActivateCamera(Hazeboy.UserCamera, CameraBlend::Normal(1.4f));

		FHazePlaySlotAnimationParams Params;
		Params.Animation = HazeboyComp.EnterAnim[Player];
		Params.BlendTime = 0.03f;
		Player.PlaySlotAnimation(FHazeAnimationDelegate(), FHazeAnimationDelegate(this, n"HandleEnterDone"), Params);

		System::SetTimer(this, n"CheckPendingBark", 2.f, false);
	}

	UFUNCTION()
	void CheckPendingBark()
	{
		if (!IsActive())
			return;

		if (!HazeboyIsTitleScreen())
			return;

		HazeboyPlayPendingBark(Player);
	}

	UFUNCTION()
	void HandleEnterDone()
	{
		if (!IsActive())
			return;

		FHazePlaySlotAnimationParams Params;
		Params.Animation = HazeboyComp.MHAnim[Player];
		Params.bLoop = true;
		Player.PlaySlotAnimation(Params);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockMovementSyncronization(this);

		Player.UnblockCapabilities(n"PlayerMarker", this);
		Player.UnblockCapabilities(CameraTags::FindOtherPlayer, this);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);

		if(bShowingCancelWidget)
		{
			RemoveCancelPromptByInstigator(Player, this);
			bShowingCancelWidget = false;
		}

		if (Hazeboy != nullptr)
		{
			if (Hazeboy.TargetTank != nullptr)
				Hazeboy.TargetTank.OwningPlayer = nullptr;

			Hazeboy.InteractionComp.EnableAfterFullSyncPoint(n"Busy");
			Player.DeactivateCamera(Hazeboy.UserCamera, 1.4f);
		}

		Player.StopUsingHazeboy();

		UAnimSequence AnimSequence = HazeboyComp.ExitAnim[Player]; 
		FHazeAnimationDelegate OnBlendOut;
		if (HazeboyGameHasEnded())
			OnBlendOut.BindUFunction(this, n"EndAnimationMinigameReactions");

		Player.PlaySlotAnimation(OnBlendingOut = OnBlendOut, Animation = AnimSequence, BlendTime = 0.3f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HazeboyGameIsActive())
		{
			if(!bShowingCancelWidget)
			{
				bShowingCancelWidget = true;
				ShowCancelPromptWithText(Player, this, GiveUpText);
			}

			if(bShowingCancelWidget)
			{
				if(HasControl())
				{
					if(WasActionStarted(ActionNames::Cancel))
						NetCancelHazeBoy();
				}
			}
		}
		else if(bShowingCancelWidget)
		{
			RemoveCancelPromptByInstigator(Player, this);
			bShowingCancelWidget = false;
		}
	}

	UFUNCTION()
	void EndAnimationMinigameReactions()
	{
		auto Manager = GetHazeboyManager();
		Manager.PlayReactionAnimation(Player);
	}

	UFUNCTION(NetFunction)
	void NetCancelHazeBoy()
	{
		if(HazeboyGameIsActive())
		{
			auto Tank = Hazeboy.TargetTank;
			Tank.Kill();
		}
	}
}