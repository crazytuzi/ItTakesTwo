import Cake.LevelSpecific.Garden.ControllablePlants.ControllablePlantsComponent;
import Cake.LevelSpecific.Garden.ControllablePlants.Beanstalk.BeanstalkTags;
import Vino.Tutorial.TutorialStatics;

class UBeanstalkPlayerInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::Input);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 1;

	UControllablePlantsComponent PlantsComp;
	ABeanstalk Beanstalk;
	AHazePlayerCharacter Player;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		PlantsComp = UControllablePlantsComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		if(PlantsComp.CurrentPlant == nullptr)
			return EHazeNetworkActivation::DontActivate;

		ABeanstalk TempStalk = Cast<ABeanstalk>(PlantsComp.CurrentPlant);
		
		if(TempStalk == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(TempStalk.CurrentState == EBeanstalkState::Hurt)
			return EHazeNetworkActivation::DontActivate;
		

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Beanstalk = Cast<ABeanstalk>(PlantsComp.CurrentPlant);
		Player.ShowCancelPrompt(this);

		if(Beanstalk.CameraSettings != nullptr)
		{
			FHazeCameraBlendSettings CameraBlend;
			CameraBlend.BlendTime = 1.0f;
			Player.ApplyCameraSettings(Beanstalk.CameraSettings, CameraBlend, this, EHazeCameraPriority::High);
			FHazeCameraSettings SpecificCameraSettings;
			SpecificCameraSettings.bUseSnapOnTeleport = true;
			SpecificCameraSettings.bSnapOnTeleport = false;
			Player.ApplySpecificCameraSettings(SpecificCameraSettings, FHazeCameraClampSettings(), FHazeCameraSpringArmSettings(), CameraBlend, this, EHazeCameraPriority::Medium);
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(PlantsComp.CurrentPlant == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		ABeanstalk TempStalk = Cast<ABeanstalk>(PlantsComp.CurrentPlant);
		
		if(TempStalk == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TempStalk.CurrentState == EBeanstalkState::Hurt)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveCancelPromptByInstigator(this);
		Player.ClearCameraSettingsByInstigator(this, 1.0f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		const float InputModifier = Beanstalk.InputModifier;
		FVector PlayerInput = GetAttributeVector(AttributeVectorNames::LeftStickRaw);

		PlayerInput.Y = 0.f;

		const float InputVerticalModifier = 1.0f + FMath::Abs(PlayerInput.X);
		const float InputHorizontalModifier = 1.0f + FMath::Abs(PlayerInput.Y);

		const float DeadZoneVerticalModifier = FMath::Pow(FMath::Abs(PlayerInput.Y), 3.0f * InputVerticalModifier);
		const float DeadZoneHorizontalModifier = FMath::Pow(FMath::Abs(PlayerInput.X), 1.5f * InputHorizontalModifier);

		PlayerInput.Y *= -1.0f;

		
		float MovementDirection = 0.0f;

		if (IsActioning(ActionNames::SecondaryLevelAbility))
		{
			MovementDirection = -GetAttributeValue(AttributeNames::SecondaryLevelAbilityAxis);
		}
		else if (IsActioning(ActionNames::PrimaryLevelAbility))
		{
			MovementDirection = GetAttributeValue(AttributeNames::PrimaryLevelAbilityAxis);

			if(!Beanstalk.bHasExtended)
				Beanstalk.bHasExtended = true;
		}

		MovementDirection *= InputModifier;
		PlayerInput *= InputModifier;

		bool bShouldSpawnLeaf = false;
		bool bShouldExit = false;
		bool bWasReverseStopped = false;

		if(Beanstalk.CurrentState != EBeanstalkState::Submerging)
		{
			bShouldSpawnLeaf = WasActionStarted(ActionNames::BeanstalkSpawnLeaf);
			bShouldExit = WasActionStarted(ActionNames::Cancel);
			bWasReverseStopped = WasActionStopped(ActionNames::SecondaryLevelAbility);

			if(WasButtonPressed())
			{
				Beanstalk.OnInputPressed(true);
			}
			else if(WasButtonReleased())
			{
				Beanstalk.OnInputPressed(false);
			}
		}

		if(Beanstalk.CurrentState == EBeanstalkState::Submerging && MovementDirection <= 0.0f)
		{
			MovementDirection = -1.0f;
		}

		Beanstalk.UpdatePlayerInput(PlayerInput, MovementDirection, bShouldSpawnLeaf, bShouldExit, bWasReverseStopped);
	}

	bool WasButtonPressed() const
	{
		return (WasActionStarted(ActionNames::SecondaryLevelAbility) && !IsActioning(ActionNames::PrimaryLevelAbility)) || 
		(WasActionStarted(ActionNames::PrimaryLevelAbility) && !IsActioning(ActionNames::SecondaryLevelAbility));
	}
//
	bool WasButtonReleased() const
	{
		return (WasActionStopped(ActionNames::SecondaryLevelAbility) && !IsActioning(ActionNames::PrimaryLevelAbility)) || 
		(WasActionStopped(ActionNames::PrimaryLevelAbility) && !IsActioning(ActionNames::SecondaryLevelAbility));
	}
}
