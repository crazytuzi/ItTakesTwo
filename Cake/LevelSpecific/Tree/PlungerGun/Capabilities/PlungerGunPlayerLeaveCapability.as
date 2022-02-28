import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunPlayerComponent;
import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunManager;

class UPlungerGunPlayerLeaveCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 90;

	UPROPERTY()
	FText GiveUpText = NSLOCTEXT("PlungerDunger", "GiveUp", "Give Up");

	AHazePlayerCharacter Player;
	UPlungerGunPlayerComponent GunComp;

	bool bShowingCancelPrompt = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GunComp = UPlungerGunPlayerComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if(bShowingCancelPrompt)
		{
			RemoveCancelPromptByInstigator(Player, this);
			bShowingCancelPrompt = false;
		}
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		bool bWantToShowPrompt = true;
		if (GunComp.Gun == nullptr)
			bWantToShowPrompt = false;

		if (!PlungerGunGameIsActive())
			bWantToShowPrompt = PlungerGunManager.DoubleInteract.CanPlayerCancel(Player);

		if(bShowingCancelPrompt != bWantToShowPrompt)
		{
			if(bWantToShowPrompt)
			{
				if (PlungerGunGameIsActive())
					ShowCancelPromptWithText(Player, this, GiveUpText);
				else
					ShowCancelPrompt(Player, this);

				bShowingCancelPrompt = true;
			}
			else
			{
				RemoveCancelPromptByInstigator(Player, this);
				bShowingCancelPrompt = false;
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GunComp.Gun == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (PlungerGunGameIsIdle())
		{
			// While IDLE we can cancel manually!
			if (!PlungerGunManager.DoubleInteract.CanPlayerCancel(Player))
				return EHazeNetworkActivation::DontActivate;

			if (!WasActionStarted(ActionNames::Cancel))
				return EHazeNetworkActivation::DontActivate;

			return EHazeNetworkActivation::ActivateFromControl;
		}

		if (PlungerGunGameIsResetting())
		{
			// When resetting, just leave! We're done here.
			return EHazeNetworkActivation::ActivateLocal;
		}

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		PlungerGunManager.DoubleInteract.CancelInteracting(Player);
		GunComp.ExitGun();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	}
}