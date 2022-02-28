import Cake.LevelSpecific.Garden.Greenhouse.BossControllablePlant.BossControllablePlantHammer;
import Vino.Tutorial.TutorialPrompt;
import Vino.Tutorial.TutorialStatics;

class UBossControllablePlantHammerMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	ABossControllablePlantHammer Plant;

	UMovePlantWidget MovementWidget;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Plant = Cast<ABossControllablePlantHammer>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!Plant.bIsAlive)
			return EHazeNetworkActivation::DontActivate; 
		
		if (!Plant.bBeingControlled)
			return EHazeNetworkActivation::DontActivate; 

		if (!Plant.bFullyButtonMashed)
			return EHazeNetworkActivation::DontActivate; 

		if (Plant.SoilPatch.CurrentSection != 1)
			return EHazeNetworkActivation::DontActivate; 
	
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if (!Plant.bIsAlive)
			return EHazeNetworkDeactivation::DeactivateLocal; 

		if (!Plant.bBeingControlled)
			return EHazeNetworkDeactivation::DeactivateLocal; 

		if (!Plant.bFullyButtonMashed)
			return EHazeNetworkDeactivation::DeactivateLocal; 

		if (Plant.SoilPatch.CurrentSection != 1)
			return EHazeNetworkDeactivation::DeactivateLocal; 

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// FTutorialPrompt TutorialPrompt;
		// if(Plant.IsRightPlant)
		// {
		// 	TutorialPrompt.Action = AttributeVectorNames::MovementRaw;
		// 	TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRight;
		// }
		// else
		// {
		// 	TutorialPrompt.Action = AttributeVectorNames::RightStickRaw;
		// 	TutorialPrompt.DisplayType = ETutorialPromptDisplay::RightStick_LeftRight;
		// }

		// ShowTutorialPrompt(Plant.ControllingPlayer, TutorialPrompt, Plant);

		MovementWidget = Cast<UMovePlantWidget>((Plant.ControllingPlayer.AddWidget(Plant.MovementWidgetClass)));

		if (Plant.IsRightPlant)
			MovementWidget.SetStickTypeAndSide(EMovePlantInputType::LeftRight, EMovePlantInputSide::Right);
		else
			MovementWidget.SetStickTypeAndSide(EMovePlantInputType::LeftRight, EMovePlantInputSide::Left);

		MovementWidget.AttachWidgetToComponent(Plant.ButtonMashAttachPoint);
		
		MovementWidget.SetWidgetShowInFullscreen(true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		//RemoveTutorialPromptByInstigator(Plant.ControllingPlayer, Plant);
		MovementWidget.Destroy();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float XInput;
		if (Plant.IsRightPlant)
			XInput = Plant.BossPlantsComp.RightStickInput.X;
		else
			XInput = Plant.BossPlantsComp.LeftStickInput.X;

		Plant.CurrentRotationValue += XInput * Plant.RotationSpeed * DeltaTime;
		Plant.CurrentRotationValue = FMath::Clamp(Plant.CurrentRotationValue, 0.0f, 1.0f);

		float CurrentYawRotation = FMath::Lerp(0.0f, Plant.MaxYawValue, Plant.CurrentRotationValue);

		Plant.RotationRoot.SetRelativeRotation(FRotator(0.0f, CurrentYawRotation, 0.0f));
	}
}
