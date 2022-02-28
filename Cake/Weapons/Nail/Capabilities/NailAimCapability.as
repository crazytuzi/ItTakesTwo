
import Cake.Weapons.Nail.NailWielderComponent;
import Cake.Weapons.Nail.NailWeaponActor;
import Vino.Movement.Components.MovementComponent;
import Cake.Weapons.Nail.NailWeaponCrosshairWidget;
import Peanuts.Aiming.AutoAimStatics;
import Cake.Weapons.Nail.NailWielderAimCollisionSolver;
import Vino.Movement.MovementSystemTags;

UCLASS(abstract)
class UNailAimCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Weapon");
	default CapabilityTags.Add(n"NailWeapon");
	default CapabilityTags.Add(n"NailAim");
	default CapabilityTags.Add(n"NailMovement");
	default CapabilityTags.Add(n"Movement");
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::MovementAction);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(ActionNames::WeaponAim);

	default CapabilityDebugCategory = n"LevelSpecific";

	default TickGroup = ECapabilityTickGroups::LastDemotable;
	// default TickGroup = ECapabilityTickGroups::LastMovement;
	// default TickGroupOrder = 50;
	default TickGroupOrder = 198;

	UPROPERTY(BlueprintReadOnly, Category = "Movement")
	float RotateWielderTowardsAimDirectionSpeed = 20.f;

	UPROPERTY(Category = "Throw")
	float AutoAimMinDistance = 100.f;
	
	UPROPERTY(Category = "Throw")
	float ThrowTraceLength = 10000.f;

	/* How fast the camera settings will be blended in*/
	UPROPERTY(BlueprintReadOnly, Category = "Camera")
	float CameraSettingsBlendInTime = 0.5f;

	/* Will be pushed when you hold down the aim button */
	UPROPERTY(BlueprintReadOnly, Category = "Camera")
	UHazeCameraSpringArmSettingsDataAsset CameraSettings_Aiming;

	UPROPERTY(BlueprintReadOnly, Category = "HUD")
	TSubclassOf<UNailWeaponCrosshairWidget> CrossHairWidgetClass;

	UPROPERTY(Category = "Animation")
	FHazePlayOverrideAnimationParams Aim_MH_Player;

	UPROPERTY(Category = "Animation")
	FHazePlaySlotAnimationParams Aim_MH_Nail;

	UPROPERTY(Category = "Animation")
	UHazeLocomotionAssetBase StrafeAsset;

	UPROPERTY(Category = "Animation")
	UAimOffsetBlendSpace AimBlendSpace;

	// Settings 
	//////////////////////////////////////////////////////////////////////////
	// Transient 

	UClass PreviousCollisionSolverClass;
	UClass PreviousRemoteCollisionSolverClass;

	UNailWeaponCrosshairWidget CrossHairWidgetInstance = nullptr;
	UHazeActiveCameraUserComponent CameraUser = nullptr;
	UNailWielderComponent WielderComp = nullptr;
	UHazeMovementComponent MoveComp = nullptr;
	AHazePlayerCharacter Player = nullptr;

	float PrevCamYAW = 0.f;

	// Transient 
	//////////////////////////////////////////////////////////////////////////
	// Capability Functions

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CameraUser = UHazeActiveCameraUserComponent::Get(Owner);
		Player = Cast<AHazePlayerCharacter>(Owner);
		WielderComp = UNailWielderComponent::GetOrCreate(Owner);
		MoveComp = UHazeMovementComponent::GetOrCreate(Owner);
  		Owner.BlockCapabilities(n"NailThrow", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
  		Owner.UnblockCapabilities(n"NailThrow", this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!WielderComp.IsOwnerOfNails())
			return EHazeNetworkActivation::DontActivate;

		if (!IsActioning(ActionNames::WeaponAim) && !IsActioning(n"AlwaysAim"))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(n"AlwaysAim"))
			return EHazeNetworkDeactivation::DontDeactivate;

		if (IsActioning(ActionNames::WeaponAim))
			return EHazeNetworkDeactivation::DontDeactivate;
			
		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Push our special collision solver used while aiming
		MoveComp.GetCurrentCollisionSolverType(PreviousCollisionSolverClass, PreviousRemoteCollisionSolverClass);
		if(MoveComp.IsGrounded())
			MoveComp.UseCollisionSolver(UNailAimCollisionSolver::StaticClass(), PreviousRemoteCollisionSolverClass);

		AddAimingWidget();
		ApplyAimCameraSettings();

		Player.PlayAimSpace(AimBlendSpace);
		Player.AddLocomotionAsset(StrafeAsset, this);
		
		// Owner.BlockCapabilities(n"Dash", this);
		Owner.BlockCapabilities(n"SprintSlowdown", this);
		Owner.BlockCapabilities(n"CharacterFacing", this);
 		Owner.UnblockCapabilities(n"NailThrow", this);

		Owner.BlockCapabilities(MovementSystemTags::Sprint, this);

		WielderComp.SetAnimBoolParam(WielderComp.NailEquippedToHand, n"NailAiming", true);
		WielderComp.bAiming = true;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Revert back to the previous collision solver
		MoveComp.UseCollisionSolver(PreviousCollisionSolverClass, PreviousRemoteCollisionSolverClass);

		RemoveAimingWidget();
		ClearAimCameraSettings();

		WielderComp.SetAnimBoolParam(WielderComp.NailEquippedToHand, n"NailAiming", false);
		WielderComp.bAiming = false;

		// Owner.UnblockCapabilities(n"Dash", this);
		Owner.UnblockCapabilities(n"SprintSlowdown", this);
		Owner.UnblockCapabilities(n"CharacterFacing", this);
		Owner.UnblockCapabilities(MovementSystemTags::Sprint, this);

 		Owner.BlockCapabilities(n"NailThrow", this);

		Player.StopAimSpace(AimBlendSpace);
		Player.ClearLocomotionAssetByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		WielderComp.SetAnimBoolParam(WielderComp.NailEquippedToHand, n"NailAiming", true);
		WielderComp.bAiming = true;

		UpdateAimSpace(DeltaTime);

		// @TODO: handle this more cleanly, it'll do contains check every tick :7
		if(WielderComp.HasNailsEquipped())
		{
			if (Player.HasLocomotionAsset(StrafeAsset) == false)
				Player.AddLocomotionAsset(StrafeAsset, this);
		}
		else if(!WielderComp.HasNailEquippedToHand())
		{
			if (Player.HasLocomotionAsset(StrafeAsset))
				Player.ClearLocomotionAssetByInstigator(this);

			// Oskar wanted to turn of the aim recall animation 
			// while jumping because he didn't have any animation for it yet.
			if (MoveComp.IsGrounded() && !MoveComp.BecameGrounded())
			{
				MoveComp.SetAnimationToBeRequested(n"NailRecallStrafe");
			}
		}

		UpdateWidget(DeltaTime);
		UpdateMovement();
	}

	void UpdateMovement()
	{
		MoveComp.SetTargetFacingDirection(
			Player.GetViewRotation().Vector(),
			RotateWielderTowardsAimDirectionSpeed
		);

		// prevent the player from falling off ledges while aiming 
		if(MoveComp.BecameGrounded())
			MoveComp.UseCollisionSolver(UNailAimCollisionSolver::StaticClass(), PreviousRemoteCollisionSolverClass);
		else if(MoveComp.BecameAirborne())
			MoveComp.UseCollisionSolver(PreviousCollisionSolverClass, PreviousRemoteCollisionSolverClass);
	}

	bool WielderWantsToStandStill() const
	{
		const FVector MovementDirection = GetAttributeVector(AttributeVectorNames::MovementDirection);
		return MovementDirection.IsNearlyZero();
	}

	void AddAimingWidget()
	{
		if (!CrossHairWidgetClass.IsValid())
			return;

		CrossHairWidgetInstance = Cast<UNailWeaponCrosshairWidget>(Player.AddWidget(CrossHairWidgetClass));
		CrossHairWidgetInstance.AimWorldLocation_Current.SnapTo(Player.ViewLocation + Player.ViewRotation.ForwardVector * ThrowTraceLength);
	}

	void RemoveAimingWidget()
	{
		if (!CrossHairWidgetClass.IsValid())
			return;

		Player.RemoveWidget(CrossHairWidgetInstance);
	}

	// Gameplay functions 
	//////////////////////////////////////////////////////////////////////////
	// Camera Functions

	void ApplyAimCameraSettings()
	{
		auto BlendSettings = FHazeCameraBlendSettings();
		BlendSettings.BlendTime = CameraSettingsBlendInTime;
		Player.ApplyCameraSettings(
			CameraSettings_Aiming,
			BlendSettings,
			CameraSettings_Aiming,
			EHazeCameraPriority::High
		);
		CameraUser.SetAiming(this);
	}

	void ClearAimCameraSettings()
	{
		Player.ClearCameraSettingsByInstigator(CameraSettings_Aiming);
		CameraUser.ClearAiming(this);
	}

	// Camera Functions
	//////////////////////////////////////////////////////////////////////////
	// Animation functions 

	void UpdateAimSpace(const float Dt)
	{
		auto PlayerRot = Player.GetPlayerViewRotation();
		WielderComp.SetAnimFloatParamOnAll(n"AimSpacePitch", PlayerRot.Pitch);

		float AimRotationSpeed = 0.f;
		if(Dt != 0.f)
		{
			AimRotationSpeed = PlayerRot.Yaw - PrevCamYAW;
			AimRotationSpeed /= Dt;
			AimRotationSpeed = FMath::UnwindDegrees(AimRotationSpeed);
		}
		PrevCamYAW = PlayerRot.Yaw;
		WielderComp.SetAnimFloatParamOnAll(n"AimRotationSpeed", AimRotationSpeed);
	}

	void UpdateWidget(float DeltaTime)
	{
 		const FVector Direction = Player.GetViewRotation().Vector();
 		const FVector Origin = Player.GetViewLocation();
		
		/* Correct using auto-aim on our line trace. */
		FAutoAimLine Aim = GetAutoAimForTargetLine(
			Player,
			Origin,
			Direction,
			AutoAimMinDistance,
			ThrowTraceLength,
			bCheckVisibility = true
		);

		if (Aim.AutoAimedAtComponent != nullptr)
		{
			CrossHairWidgetInstance.AutoAimComponent = Aim.AutoAimedAtComponent;

			// We use the component because the AutoAimedAtPoint
			// is projected on a sphere which creates wobbliness 
			// with default settings... you can edit all 
			// instances but then Per will have to edit
			// everything everywhere?!
			CrossHairWidgetInstance.AimWorldLocation_Desired = Aim.AutoAimedAtComponent.GetWorldLocation();
//			CrossHairWidgetInstance.AimWorldLocation_Desired = Aim.AutoAimedAtPoint;
		}
		else
		{
			CrossHairWidgetInstance.AutoAimComponent = nullptr;
			CrossHairWidgetInstance.AimWorldLocation_Desired = Player.ViewLocation + Player.ViewRotation.ForwardVector * ThrowTraceLength;
		}

		// System::DrawDebugSphere(AimLocation, 100.f);

	}

}






















