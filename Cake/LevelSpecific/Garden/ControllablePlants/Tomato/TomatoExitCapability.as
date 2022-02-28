import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Garden.ControllablePlants.Soil.ExitSoilCapability;
import Cake.LevelSpecific.Garden.ControllablePlants.Tomato.Tomato;

class UTomatoExitCapability : UExitSoilCapability
{
	default CapabilityTags.Add(CapabilityTags::Input);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(n"ExitTomato");

	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 50;

	UPROPERTY()
	FText OverrideCancelText;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);

		if(HasControl())
			//ShowCancelPromptWithText(Player, this, OverrideCancelText);

		SetMutuallyExclusive(n"ExitSoil", true);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if(HasControl())
			RemoveCancelPromptByInstigator(Player, this);

		SetMutuallyExclusive(n"ExitSoil", false);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const override
	{
		if(IsActioning(n"ForceExitTomato"))
			return EHazeNetworkActivation::ActivateLocal;

		//if(WasActionStarted(ActionNames::Cancel))
			//return EHazeNetworkActivation::ActivateLocal;


		return Super::ShouldActivate();
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		if(WasActionStarted(ActionNames::Cancel))
			ActivationParams.AddActionState(n"IsValidExit");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams) override
	{
		MakeCancelPromptClicked(Player);
		const bool bIsValidExit = ActivationParams.GetActionState(n"IsValidExit");

		if(IsActioning(n"ForceExitTomato"))
		{
			ConsumeAction(n"ForceExitTomato");
			ATomato Tomato = Cast<ATomato>(PlantsComp.CurrentPlant);
			Tomato.bTriggerExposionOnExit = true;
		}
		else if(bIsValidExit)
		{
			Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
			ATomato Tomato = Cast<ATomato>(PlantsComp.CurrentPlant);
			Tomato.bTriggerExposionOnExit = true;
		}

		Super::OnActivated(ActivationParams);
	}
}