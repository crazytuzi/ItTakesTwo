
import Cake.Weapons.Nail.NailWielderComponent;
import Vino.Tutorial.TutorialStatics;
import Vino.Tutorial.TutorialPrompt;
import Cake.Weapons.Nail.NailWeaponStatics;

UCLASS()
class UNailRecallTutorialCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NailTutorial");
	default CapabilityTags.Add(n"NailWeapon");
	default CapabilityTags.Add(n"NailRecall");
	default CapabilityTags.Add(n"Tutorial");
	default CapabilityTags.Add(n"Weapon");

	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default CapabilityDebugCategory = n"LevelSpecific";

	UNailWielderComponent WielderComp = nullptr;
	AHazePlayerCharacter Player = nullptr;

	bool bDoneTutorial_Recall = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WielderComp = UNailWielderComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(bDoneTutorial_Recall)
			return EHazeNetworkActivation::DontActivate;

		if(WielderComp.NailsThrown.Num() <= 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bDoneTutorial_Recall)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(WielderComp.NailsThrown.Num() == 0 && WielderComp.NailsBeingRecalled.Num() == 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.Action = ActionNames::WeaponReload;
		TutorialPrompt.Text = WielderComp.NailsThrown.Last().RecallNailTutorialText;
		TutorialPrompt.Mode = ETutorialPromptMode::Default;
		ShowTutorialPrompt(Player, TutorialPrompt, this);

		// Make sure that nails dont get autorecalled during tutorial.
		Owner.BlockCapabilities(n"NailRecall", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RecallAllNailsToWielder(Player);
		RemoveTutorialPromptByInstigator(Player, this);
		Owner.UnblockCapabilities(n"NailRecall", this);

		// make sure that the nail is recalled immediately
		WielderComp.TimeStampRecallTagUnblocked -= 2.f;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(WasActionStarted(ActionNames::WeaponReload))
			bDoneTutorial_Recall = true;
	}

}




















