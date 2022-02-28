import Cake.FlyingMachine.Gunner.FlyingMachineGunnerComponent;
import Cake.FlyingMachine.Gunner.FlyingMachineGunnerCrosshairWidget;
import Cake.FlyingMachine.FlyingMachineNames;
import Vino.Camera.Components.CameraUserComponent;

class UFlyingMachineGunnerHudCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Gunner);
	default CapabilityTags.Add(FlyingMachineTag::Hud);

	default TickGroup = ECapabilityTickGroups::LastDemotable;
	default TickGroupOrder = 150;
	default CapabilityDebugCategory = FlyingMachineCategory::Gunner;

	AHazePlayerCharacter Player;
	UFlyingMachineGunnerComponent Gunner;

	AFlyingMachineTurret Turret;
	UHazeCameraComponent Camera;

	FHazeAcceleratedFloat MuzzleMarkerDistance;

	UPROPERTY(Category = "Widget")
	TSubclassOf<UFlyingMachineGunnerCrosshairWidget> WidgetClass;

	UPROPERTY()
	UFlyingMachineGunnerCrosshairWidget Widget;

	FFlyingMachineGunnerSettings Settings;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Gunner = UFlyingMachineGunnerComponent::GetOrCreate(Player);

		MuzzleMarkerDistance.SnapTo(Settings.TargetTraceLength);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Gunner.CurrentTurret == nullptr)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Gunner.CurrentTurret == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Turret = Gunner.CurrentTurret;

		Camera = Turret.Camera;
		Widget = Cast<UFlyingMachineGunnerCrosshairWidget>(Player.AddWidget(WidgetClass));
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.RemoveWidget(Widget);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// If we're auto aiming at something, accelerate towards that distance
		if (Gunner.AutoAimedTarget != nullptr)
		{
			float DistanceToTarget = (Gunner.AutoAimedTarget.WorldLocation - Turret.TurretLocation).Size();
			MuzzleMarkerDistance.SnapTo(DistanceToTarget, 0.f);
		}
		else
		{
			MuzzleMarkerDistance.AccelerateTo(Settings.TargetTraceLength, 0.2f, DeltaTime);
		}

		Widget.AimWorldLocation = Turret.TurretLocation + Gunner.CurrentAimDirection * MuzzleMarkerDistance.Value;

		if (WasActionStarted(FlyingMachineAction::Fire))
			Widget.BP_PlayFireAnimation();

		// Find out if aim is clamped
		FVector TargetForward = Gunner.TargetAimDirection;
		FVector PlaneUp = Turret.ActorUpVector;

		float PitchDot = TargetForward.DotProduct(PlaneUp);
		float TargetPitch = FMath::Asin(PitchDot) * RAD_TO_DEG;

		bool bWithinClamp = TargetPitch >= Settings.MinPitch && TargetPitch <= Settings.MaxPitch;

		Widget.IsAimClamped = !bWithinClamp;
		Widget.ReloadProgress = Gunner.ReloadProgress;
	}
}