import Vino.Movement.Components.MovementComponent;
import Cake.Weapons.Sap.SapWeaponWielderComponent;
import Vino.Camera.Components.CameraUserComponent;
import Vino.Camera.Capabilities.CameraTags;
import Vino.Movement.MovementSystemTags;

class USapWeaponFullscreenAimCapability : UHazeCapability 
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

	USapWeaponFullscreenCrosshairWidget Widget;

	FVector2D AimPosition;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Wielder = USapWeaponWielderComponent::Get(Player);
		CameraUser = UCameraUserComponent::Get(Player);
		MoveComp = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Wielder.Weapon == nullptr)
	        return EHazeNetworkActivation::DontActivate;

	    if (!Wielder.bFullscreenAim)
	        return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Wielder.Weapon == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

	    if (!Wielder.bFullscreenAim)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Widget = Cast<USapWeaponFullscreenCrosshairWidget>(Player.AddWidget(Wielder.FullscreenCrosshairWidgetClass));
		Widget.SetWidgetShowInFullscreen(true);

		AimPosition = FVector2D(0.5f, 0.5f);

		Wielder.bIsAiming = true;

		Player.BlockCapabilities(MovementSystemTags::TurnAround, this);
		Player.BlockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.BlockCapabilities(MovementSystemTags::WallSlide, this);
		Player.BlockCapabilities(MovementSystemTags::LedgeVault, this);

		SetMutuallyExclusive(SapWeaponTags::Aim, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveWidget(Widget);
		Widget = nullptr;

		Wielder.bIsAiming = false;

		Player.UnblockCapabilities(MovementSystemTags::TurnAround, this);
		Player.UnblockCapabilities(MovementSystemTags::LedgeGrab, this);
		Player.UnblockCapabilities(MovementSystemTags::WallSlide, this);
		Player.UnblockCapabilities(MovementSystemTags::LedgeVault, this);

		SetMutuallyExclusive(SapWeaponTags::Aim, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		AHazePlayerCharacter ScreenPlayer = SceneView::IsFullScreen() ? SceneView::GetFullScreenPlayer() : Player;
		FVector2D Resolution = SceneView::GetPlayerViewResolution(ScreenPlayer);

		if(Resolution.X == 0.f)
			return;

		FVector2D Input = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
		Input.Y = -Input.Y;
		Input.X *= Resolution.Y / Resolution.X;

		AimPosition += Input * 0.6f * DeltaTime;
		AimPosition.X = Math::Saturate(AimPosition.X);
		AimPosition.Y = Math::Saturate(AimPosition.Y);

		FVector Origin;
		FVector Direction;
		if (SceneView::DeprojectScreenToWorld_Relative(ScreenPlayer, AimPosition, Origin, Direction))
			Wielder.AimTarget = SapQueryAimTarget(ScreenPlayer, Origin, Direction);

		// Update widget, bruv
		Widget.AimScreenPosition = AimPosition;
		Widget.AimLocation = Wielder.AimTarget.WorldLocation;
		Widget.PressurePercent = Wielder.Pressure / Sap::Pressure::Max;

		FRotator CameraRot = Player.GetViewRotation();
		if (Wielder.AimTarget.HasAttachParent())
			Widget.SurfaceQuat = Math::MakeQuatFromZX(Wielder.AimTarget.WorldNormal, CameraRot.UpVector);
		else
			Widget.SurfaceQuat = Math::MakeQuatFromZX(-CameraRot.ForwardVector, CameraRot.UpVector);

		if (Wielder.AimTarget.bIsAutoAim)
		{
			Widget.SurfaceQuat = Math::MakeQuatFromZX(-CameraRot.ForwardVector, CameraRot.UpVector);
			Widget.AimLocation = Wielder.AimTarget.Component.GetSocketLocation(Wielder.AimTarget.Socket);
		}
	}
}