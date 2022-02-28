import Vino.Movement.Components.MovementComponent;
import Cake.Weapons.Sap.SapWeaponWielderComponent;
import Vino.Camera.Components.CameraUserComponent;
import Peanuts.Aiming.AutoAimStatics;
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.Weapons.AimTargetIndicator.AimTargetIndicatorComponent;
import Vino.Movement.MovementSystemTags;

class USapWeaponAimCapability : UHazeCapability 
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(CapabilityTags::Weapon);
	default CapabilityTags.Add(ActionNames::WeaponAim);
	default CapabilityTags.Add(SapWeaponTags::Weapon);
	default CapabilityTags.Add(SapWeaponTags::Aim);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::LastDemotable;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	USapWeaponWielderComponent Wielder;
	UCameraUserComponent CameraUser;
	UHazeMovementComponent MoveComp;
	UUserGrindComponent GrindComp;

	USapWeaponCrosshairWidget Widget;

	FTransform PreviousCameraTransform;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Wielder = USapWeaponWielderComponent::GetOrCreate(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
		GrindComp = UUserGrindComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Wielder.Weapon == nullptr)
	        return EHazeNetworkActivation::DontActivate;

	    if (!IsActioning(ActionNames::WeaponAim))
	        return EHazeNetworkActivation::DontActivate;

	    if (GrindComp.HasTargetGrindSpline())
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Wielder.Weapon == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

	    if (!IsActioning(ActionNames::WeaponAim))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

	    if (GrindComp.HasTargetGrindSpline())
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CameraUser.SetAiming(this);
		Player.ApplyCameraSettings(Wielder.AimCameraSettings, FHazeCameraBlendSettings(1.f), this, EHazeCameraPriority::Medium);

		Player.BlockCapabilities(n"CharacterFacing", this);
		Player.BlockCapabilities(MovementSystemTags::Sprint, this);
		Player.BlockCapabilities(MovementSystemTags::TurnAround, this);
		Player.BlockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.BlockCapabilities(MovementSystemTags::WallSlide, this);
		Player.BlockCapabilities(MovementSystemTags::LedgeVault, this);
		Player.AddLocomotionAsset(Wielder.AimLocomotion, this);

		Widget = Cast<USapWeaponCrosshairWidget>(
			Player.AddWidget(Wielder.CrosshairWidgetClass)
		);

		Wielder.bIsAiming = true;
		Wielder.bAimingWasBlocked = false;
		SetAimTargetIndicatorVisible(Player, true);

		// Setup variables for the first time
		FVector CameraLoc = Player.GetPlayerViewLocation();
		FVector CameraForward = Player.ControlRotation.ForwardVector;

		Wielder.AimTarget = SapQueryAimTarget(Player, CameraLoc, CameraForward);
		Wielder.AimSurfaceNormal = -CameraForward;
		GetWidgetLocationAndQuat(Wielder.AimTarget, Widget.AimLocation, Widget.SurfaceQuat);

		PreviousCameraTransform = Player.GetPlayerViewTransform();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SetAimTargetIndicatorVisible(Player, false);
		CameraUser.ClearAiming(this);
		Player.ClearCameraSettingsByInstigator(this);

		Player.UnblockCapabilities(n"CharacterFacing", this);
		Player.UnblockCapabilities(MovementSystemTags::Sprint, this);
		Player.UnblockCapabilities(MovementSystemTags::TurnAround, this);
		Player.UnblockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.UnblockCapabilities(MovementSystemTags::WallSlide, this);
		Player.UnblockCapabilities(MovementSystemTags::LedgeVault, this);
		Player.ClearLocomotionAssetByInstigator(this);

		Player.RemoveWidget(Widget);
		Widget = nullptr;

		Wielder.bIsAiming = false;
		Wielder.AimTarget = FSapAttachTarget();

		// Used for separate animations out of aiming
		if (IsBlocked())
			Wielder.bAimingWasBlocked = true;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Okay, so, we want to keep the widgets location camera-relative
		// So, to do this, before we do any lerping, get the PREVIOUS camera-relative position of the target
		// Then, re-transform it into the CURRENT camera space, and use that
		FTransform CurrentCameraTransform = Player.GetPlayerViewTransform();

		FVector RelativeLocation = PreviousCameraTransform.InverseTransformPosition(Widget.AimLocation);
		Widget.AimLocation = CurrentCameraTransform.TransformPosition(RelativeLocation);

		PreviousCameraTransform = CurrentCameraTransform;

		// Alright! Done with that, do the aiming.
		FRotator ControlRotation = Player.GetControlRotation();
		MoveComp.SetTargetFacingRotation(ControlRotation, 5.5f);	

		FVector CameraLoc = Player.GetPlayerViewLocation();
		FVector CameraForward = Player.ControlRotation.ForwardVector;

		FSapAttachTarget AimTarget = SapQueryAimTarget(Player, CameraLoc, CameraForward);
		Wielder.AimTarget = AimTarget;

		// Update the widget!
		FVector WidgetLocation;
		FQuat WidgetQuat;
		GetWidgetLocationAndQuat(Wielder.AimTarget, WidgetLocation, WidgetQuat);

		Widget.AimLocation = FMath::Lerp(Widget.AimLocation, WidgetLocation, 22.f * DeltaTime);
		Widget.SurfaceQuat = FQuat::Slerp(Widget.SurfaceQuat, WidgetQuat, 18.f * DeltaTime);

		// Pressure stuff
		Widget.PressurePercent = Wielder.Pressure / Sap::Pressure::Max;
	}

	void GetWidgetLocationAndQuat(FSapAttachTarget Target, FVector& WidgetLocation, FQuat& WidgetQuat) const
	{
		FRotator CameraRot = Player.GetViewRotation();
		FVector CameraLoc = Player.GetViewLocation();

		if (Target.bIsAutoAim)
		{
			WidgetLocation = Wielder.AimTarget.Component.GetSocketLocation(Wielder.AimTarget.Socket);
			WidgetQuat = Math::MakeQuatFromZX(-CameraRot.ForwardVector, CameraRot.UpVector);
		}
		else
		{
			WidgetLocation = Target.WorldLocation;
			if (Wielder.AimTarget.HasAttachParent())
			{
				WidgetQuat = Math::MakeQuatFromZX(Wielder.AimSurfaceNormal, CameraRot.UpVector);
			}
			else
			{
				WidgetQuat = Math::MakeQuatFromZX(-CameraRot.ForwardVector, CameraRot.UpVector);
			}
		}

		// Limit how far away the widget can be
		float WidgetDistance = CameraLoc.Distance(WidgetLocation);
		if (WidgetDistance > Sap::Aim::WidgetMaxDistance)
		{
			FVector Direction = (WidgetLocation - CameraLoc).GetSafeNormal();
			WidgetLocation = CameraLoc + Direction * Sap::Aim::WidgetMaxDistance;
			WidgetQuat = Math::MakeQuatFromZX(-CameraRot.ForwardVector, CameraRot.UpVector);
		}
	}
}