import Vino.Tutorial.TutorialStatics;

class UAimTutorialDataAsset : UDataAsset
{
	UPROPERTY()
	FName AimAction = n"WeaponAim";

	UPROPERTY()
	FText AimText;

	UPROPERTY()
	FName FireAction = n"WeaponFire";

	UPROPERTY()
	FText FireText;
};

UFUNCTION(Category = "Tutorials")
void ShowAimTutorial(AHazePlayerCharacter Player, UAimTutorialDataAsset AimTutorial)
{
	Player.AddCapability(UAimTutorialCapability::StaticClass());
	if (Player.HasControl())
		Player.SetCapabilityAttributeObject(n"AimTutorialDataAsset", AimTutorial);
}

UFUNCTION(Category = "Tutorials")
void HideAimTutorial(AHazePlayerCharacter Player)
{
	Player.SetCapabilityAttributeObject(n"AimTutorialDataAsset", nullptr);
}

class UAimTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(n"Tutorial");
	default CapabilityTags.Add(n"HUD");
	
    AHazePlayerCharacter Player;
	UAimTutorialDataAsset Asset;

	bool bWasAiming = false;
	bool bTutorialComplete = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GetAttributeObject(n"AimTutorialDataAsset") != nullptr)
			return EHazeNetworkActivation::ActivateUsingCrumb;
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bTutorialComplete)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		ActivationParams.AddObject(n"AimTutorialDataAsset", GetAttributeObject(n"AimTutorialDataAsset"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Asset = Cast<UAimTutorialDataAsset>(ActivationParams.GetObject(n"AimTutorialDataAsset"));
		bWasAiming = !IsActioning(Asset.AimAction);
		bTutorialComplete = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		bool bIsAiming;
		if (HasControl())
			bIsAiming = IsActioning(Asset.AimAction);
		else
			bIsAiming = Owner.IsAnyCapabilityActive(n"WeaponAim"); // Hack to make this work on the remote side
		if (bIsAiming)
		{
			if (!bWasAiming)
			{
				// We started aiming this frame, update the prompt
				bWasAiming = true;

				RemoveTutorialPromptByInstigator(Player, this);

				FTutorialPrompt FirePrompt;
				FirePrompt.Action = Asset.FireAction;
				FirePrompt.Text = Asset.FireText;
				ShowTutorialPrompt(Player, FirePrompt, this);
			}

			if (HasControl() && IsActioning(Asset.FireAction))
			{
				// We started firing, aim tutorial is complete
				bTutorialComplete = true;

				UObject AimAssetObj;
				ConsumeAttribute(n"AimTutorialDataAsset", AimAssetObj);
			}
		}
		else 
		{
			if (bWasAiming)
			{
				// We stopped aiming without firing, go back to aiming prompt
				bWasAiming = false;

				RemoveTutorialPromptByInstigator(Player, this);

				FTutorialPrompt AimPrompt;
				AimPrompt.Action = Asset.AimAction;
				AimPrompt.Text = Asset.AimText;
				ShowTutorialPrompt(Player, AimPrompt, this);
			}
		}
	}
};