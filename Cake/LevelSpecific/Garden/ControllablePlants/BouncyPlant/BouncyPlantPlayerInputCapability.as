import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Tutorial.TutorialStatics;
import Cake.LevelSpecific.Garden.ControllablePlants.BouncyPlant.BouncyPlant;

class UBouncyPlantPlayerInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 10;

	ABouncyPlant CurrentBouncyPlant;
	UCameraUserComponent CameraUser;
	AHazePlayerCharacter Player;
	UControllablePlantsComponent PlantsComp;

	bool bTutorialActive = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlantsComp = UControllablePlantsComponent::Get(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if (PlantsComp.CurrentPlant == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!PlantsComp.CurrentPlant.IsA(ABouncyPlant::StaticClass()))
			return EHazeNetworkActivation::DontActivate;
        	
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentBouncyPlant = Cast<ABouncyPlant>(PlantsComp.CurrentPlant);
		CameraUser.SetAiming(this);
		ShowTutorialPrompt(Player, CurrentBouncyPlant.BounceTutorial, this);
		bTutorialActive = true;
		Player.ShowCancelPrompt(this);

/*
		FTutorialPrompt ZoomPrompt;
		ZoomPrompt.Action = ActionNames::TEMPLeftTrigger;
		ZoomPrompt.Text = FText::FromString("Zoom");
		ZoomPrompt.MaximumDuration = 10.f;
		ZoomPrompt.Mode = ETutorialPromptMode::Default;
		ShowTutorialPrompt(Player, ZoomPrompt, this);

		FTutorialPrompt ShootPrompt;
		ShootPrompt.Action = ActionNames::TEMPRightTrigger;
		ShootPrompt.Text = FText::FromString("Shoot");
		ShootPrompt.MaximumDuration = 10.f;
		ShootPrompt.Mode = ETutorialPromptMode::Default;
		ShowTutorialPrompt(Player, ShootPrompt, this);

		FTutorialPrompt ReloadPrompt;
		ReloadPrompt.Action = ActionNames::TEMPLeftFaceButton;
		ReloadPrompt.Text = FText::FromString("Reload");
		ReloadPrompt.MaximumDuration = 10.f;
		ReloadPrompt.Mode = ETutorialPromptMode::Default;
		ShowTutorialPrompt(Player, ReloadPrompt, this);
*/
	}
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if(bTutorialActive)
			RemoveTutorialPromptByInstigator(Player, this);
			
		CameraUser.ClearAiming(this);
		Player.ClearCameraSettingsByInstigator(this);
		Player.RemoveCancelPromptByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if(CurrentBouncyPlant.bTutorialCompleted && bTutorialActive)
		{
			RemoveTutorialPromptByInstigator(Player, this);
			bTutorialActive = false;
		}

		FVector2D PlayerInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);

		//const float FireRate = GetAttributeValue(ActionNames::WeaponFire);

		//WeaponFire returning 0 due to not being an axis binding, changed to binary to work / be consistant between keyboard/gamepad.
		int FireRate = 0;
		if(IsActioning(ActionNames::WeaponFire))
		{
			FireRate = 1.f;
			Player.SetFrameForceFeedback(0.05f, 0.05f);
		}

		CurrentBouncyPlant.UpdatePlayerInput(PlayerInput, FireRate);
	}
}
