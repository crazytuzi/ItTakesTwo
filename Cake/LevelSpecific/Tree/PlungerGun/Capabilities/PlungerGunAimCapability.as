import Cake.LevelSpecific.Tree.PlungerGun.PlungerGunPlayerComponent;

class UPlungerGunPlayerAimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default TickGroup = ECapabilityTickGroups::LastDemotable;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	UPlungerGunPlayerComponent GunComp;
	UCameraUserComponent UserComp;
	APlungerGun Gun;

	UPlungerGunCrosshairWidget Crosshair;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		GunComp = UPlungerGunPlayerComponent::Get(Owner);
		UserComp = UCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (GunComp.Gun == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (GunComp.Gun == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Gun = GunComp.Gun;

		Crosshair = Cast<UPlungerGunCrosshairWidget>(Player.AddWidget(Gun.CrosshairWidgetClass));
		GunComp.Widget = Crosshair;
		UserComp.SetAiming(this);

		Gun.BP_OnStartAiming();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (Gun != nullptr)
			Gun.BP_OnStopAiming();

		Gun = nullptr;
		GunComp.Widget = nullptr;

		Player.RemoveWidget(Crosshair);
		UserComp.ClearAiming(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (UserComp.HasPointOfInterest(EHazePointOfInterestType::Forced))
			return;

		// Lerp the guns rotation towards desired!
		FRotator CurrentRotation;
		CurrentRotation.Yaw = Gun.YawRoot.RelativeRotation.Yaw;
		CurrentRotation.Pitch = Gun.PitchRoot.RelativeRotation.Pitch;

		FRotator RelativeDesired = Gun.ActorTransform.InverseTransformRotation(UserComp.DesiredRotation);

		// Gun is pitched 10 degress above desired, because it looks nice I dunno lmao
		RelativeDesired.Pitch += 10.f;

		CurrentRotation = FMath::RInterpTo(CurrentRotation, RelativeDesired, 12.f, DeltaTime);

		// Find out how much we're aiming
		float YawDiffSqrd = FMath::Square(Gun.YawRoot.RelativeRotation.Yaw - CurrentRotation.Yaw);
		float PitchDiffSqrd = FMath::Square(Gun.PitchRoot.RelativeRotation.Pitch - CurrentRotation.Pitch);
		float AimDelta = FMath::Sqrt(YawDiffSqrd + PitchDiffSqrd);
		Gun.BP_OnAim((AimDelta / DeltaTime) / 100.f);

		Gun.YawRoot.RelativeRotation = FRotator(0.f, CurrentRotation.Yaw, 0.f);
		Gun.PitchRoot.RelativeRotation = FRotator(CurrentRotation.Pitch, 0.f, 0.f);

		Crosshair.FireOrigin = Gun.Muzzle.WorldTransform;
	}
}