
import Cake.Weapons.Nail.NailWielderComponent;
import Vino.Tutorial.TutorialStatics;
import Vino.Tutorial.TutorialPrompt;
import Cake.Weapons.Nail.NailWeaponStatics;

/*

	This capability will show a recall prompt when the following conditions are met:
		- While aiming
		- All nails thrown
		- no nails on screen
*/

UCLASS()
class UNailRecallPromptCapability : UHazeCapability
{
	default CapabilityTags.Add(n"NailWeapon");
	default CapabilityTags.Add(n"NailRecall");

	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";

	UNailWielderComponent WielderComp = nullptr;
	AHazePlayerCharacter Player = nullptr;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		WielderComp = UNailWielderComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(WielderComp.NailsThrown.Num() <= 0)
			return EHazeNetworkActivation::DontActivate;

		if(WielderComp.HasNailsEquipped())
			return EHazeNetworkActivation::DontActivate;

		if(WielderComp.AreNailsBeingRecalled())
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(ActionNames::WeaponAim) && !IsActioning(n"AlwaysAim"))
			return EHazeNetworkActivation::DontActivate;

		if(AreThrownNailsRendered())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		// if(WielderComp.NailsThrown.Num() == 0 && WielderComp.NailsBeingRecalled.Num() == 0)
		if(WielderComp.NailsThrown.Num() == 0)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(WielderComp.HasNailsEquipped())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(WielderComp.AreNailsBeingRecalled())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if (!IsActioning(ActionNames::WeaponAim) && !IsActioning(n"AlwaysAim"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(AreThrownNailsRendered())
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
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveTutorialPromptByInstigator(Player, this);
	}

	bool AreThrownNailsRendered() const
	{
		return WielderComp.AreThrownNailsRenderedFor(Player);
	}

}

