
import Cake.Weapons.Match.MatchWielderComponent;
import Cake.Weapons.Match.MatchWeaponActor;
import Cake.Weapons.Match.MatchWeaponSocketDefinition;
import Cake.Weapons.Match.MatchCrosshairWidget;
import Vino.Movement.Components.MovementComponent;
import Vino.Camera.Components.CameraUserComponent;

import Vino.Camera.Capabilities.CameraTags;
import Peanuts.Aiming.AutoAimStatics;

UCLASS(abstract)
class UMatchWeaponAimFullscreenCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(ActionNames::WeaponAim);
	default CapabilityTags.Add(n"MatchWeaponMovement");
	default CapabilityTags.Add(n"MatchWeaponAim");
	default CapabilityTags.Add(n"MatchWeapon");
	default CapabilityTags.Add(n"Weapon");

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::LastDemotable;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "Movement")
		float RotateWielderTowardsAimDirectionSpeed = 20.f;

	// Camera settings used while aiming
	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "Camera")
		UHazeCameraSpringArmSettingsDataAsset CameraSettings_Aiming = nullptr;

	// blend in time for pushing camera Settings while Aiming 
	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "Camera")
		float CameraSettingsBlendInTime = 0.5f;

	UPROPERTY(BlueprintReadOnly, EditDefaultsOnly, Category = "MISC")
		TSubclassOf<UMatchCrosshairWidget> CrossHairWidget;

	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
		FHazePlayOverrideAnimationParams AimMH_Player;

	UPROPERTY(Category = "Animation", meta = (ShowOnlyInnerProperties))
		FHazePlaySlotAnimationParams AimMH_MatchWeapon;

	UPROPERTY(Category = "Animation")
		UAimOffsetBlendSpace AimBlendSpace;

	UPROPERTY(Category = "Animation")
		UHazeLocomotionStateMachineAsset LocoAsset_NotAiming;

	UPROPERTY(Category = "Animation")
		UHazeLocomotionStateMachineAsset LocoAsset_Aiming;

	// Settings 
	//////////////////////////////////////////////////////////////////////////
	// Transient 

	FVector2D AimPosition;

	UMatchCrosshairWidget CrossHairWidgetInstance = nullptr;
	UCameraUserComponent CameraUser = nullptr;
	UMatchWielderComponent WielderComp = nullptr;
	AHazePlayerCharacter Player = nullptr;
	UHazeMovementComponent MoveComp = nullptr;

	// Transient 
	//////////////////////////////////////////////////////////////////////////
	// Capability Functions

	UFUNCTION(BlueprintOverride)
		void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CameraUser = UCameraUserComponent::Get(Owner);
		WielderComp = UMatchWielderComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
		EHazeNetworkActivation ShouldActivate() const
	{
		if (!WielderComp.HasMatchWeapon())
			return EHazeNetworkActivation::DontActivate;

		if (!WielderComp.ShouldFullscreenAim())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
		EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!WielderComp.HasMatchWeapon())
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (!WielderComp.ShouldFullscreenAim())
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
		void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Owner.SetCapabilityActionState(n"Aiming", EHazeActionState::Active);

		Player.BlockCapabilities(CameraTags::ChaseAssistance, this);

		Owner.BlockCapabilities(n"MatchWeaponIdle", this);
		Owner.BlockCapabilities(n"Dash", this);

		AddAimWidget();

		AimPosition = FVector2D(0.5f, 0.5f);
		SetMutuallyExclusive(n"MatchWeaponAim", true);
	}

	UFUNCTION(BlueprintOverride)
		void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		RemoveAimWidget();

		ConsumeAction(n"Aiming");

		Player.UnblockCapabilities(CameraTags::ChaseAssistance, this);

		Owner.UnblockCapabilities(n"MatchWeaponIdle", this);
		Owner.UnblockCapabilities(n"Dash", this);
		SetMutuallyExclusive(n"MatchWeaponAim", false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		UpdateWidget(DeltaTime);
	}

	void UpdateWidget(float DeltaTime)
	{
		AHazePlayerCharacter ScreenPlayer = SceneView::IsFullScreen() ? SceneView::GetFullScreenPlayer() : Player;

		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);

		const FVector2D Resolution = SceneView::GetPlayerViewResolution(ScreenPlayer);
		if (Resolution.X != 0.f)
		{
			Input.Y = -Input.Y;
			Input.X *= Resolution.Y / Resolution.X;
		}

		AimPosition += Input * 0.6f * DeltaTime;
		AimPosition.X = Math::Saturate(AimPosition.X);
		AimPosition.Y = Math::Saturate(AimPosition.Y);

		FVector Origin, Direction;
		SceneView::DeprojectScreenToWorld_Relative(ScreenPlayer, AimPosition, Origin, Direction);

		/* Correct using auto-aim on our line trace. */
		FAutoAimLine Aim = GetAutoAimForTargetLine(
			Player,
			Origin,
			Direction,
			50.f,
			8000.f,
			bCheckVisibility = true
		);

		FVector TargetAimLocation;
		if (Aim.AutoAimedAtComponent != nullptr)
			TargetAimLocation = Aim.AutoAimedAtPoint;
		else
			TargetAimLocation = Origin + Direction * 6000.f;

		if (GetActionStatus(n"MatchShoot") == EActionStateStatus::Active)
			CrossHairWidgetInstance.ArrowOffsetFromCenter += 20.f;

		CrossHairWidgetInstance.AimWorldLocationDesired = TargetAimLocation;
		CrossHairWidgetInstance.bIsAutoAimed = Aim.AutoAimedAtComponent != nullptr;
	}

	// Capability 
	//////////////////////////////////////////////////////////////////////////
	// Gameplay  

	void AddAimWidget()
	{
		if (!CrossHairWidget.IsValid())
			return;

		CrossHairWidgetInstance = Cast<UMatchCrosshairWidget>(Player.AddWidget(CrossHairWidget));
		CrossHairWidgetInstance.SetWidgetShowInFullscreen(true);

		// const FVector TargetAimLocation = WielderComp.TargetData.GetTargetLocation();
		// CrossHairWidgetInstance.AimWorldLocationDesired = TargetAimLocation;
		// CrossHairWidgetInstance.AimWorldLocation = TargetAimLocation;
		// CrossHairWidgetInstance.bIsAutoAimed = false;
	}

	void RemoveAimWidget()
	{
		if (!CrossHairWidget.IsValid())
			return;

		Player.RemoveWidget(CrossHairWidgetInstance);
	}
}






















