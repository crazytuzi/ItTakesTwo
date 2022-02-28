import Cake.FlyingMachine.FlyingMachineNames;
import Cake.FlyingMachine.Gunner.FlyingMachineGunnerComponent;
import Cake.FlyingMachine.Turret.FlyingMachineTurret;
import Vino.Camera.Components.CameraUserComponent;
import Peanuts.Aiming.AutoAimStatics;

class UFlyingMachineGunnerAutoAimCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default CapabilityTags.Add(FlyingMachineTag::Gunner);
	default TickGroup = ECapabilityTickGroups::LastDemotable;
	default TickGroupOrder = 51;
	default CapabilityDebugCategory = FlyingMachineCategory::Gunner;

	AHazePlayerCharacter Player;
	UCameraUserComponent CameraUser;
	UFlyingMachineGunnerComponent Gunner;

	AFlyingMachineTurret Turret;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Gunner = UFlyingMachineGunnerComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!HasControl())
			return EHazeNetworkActivation::DontActivate;

		if (Gunner.AutoAimedTarget == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if (!Gunner.AutoAimedTarget.IsNetworked())
		{
			Print("Trying to auto-aim on a non-networked actor", Color = FLinearColor::Red);
			return EHazeNetworkActivation::DontActivate;
		}

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Gunner.AutoAimedTarget == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddObject(n"Target", Gunner.AutoAimedTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (!HasControl())
			Gunner.AutoAimedTarget = Cast<UAutoAimTargetComponent>(ActivationParams.GetObject(n"Target"));

		Turret = Gunner.CurrentTurret;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Turret = nullptr;

		if (!HasControl())
			Gunner.AutoAimedTarget = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if (!HasControl())
			return;

		// On the control-side, look for targets!
		if (Gunner.CurrentTurret == nullptr)
		{
			Gunner.AutoAimedTarget = nullptr;
			return;
		}

		UHazeCameraComponent Camera = Gunner.CurrentTurret.Camera;
		FAutoAimLine AutoAimResult = GetAutoAimForTargetLine(Player, Camera.WorldLocation, Camera.ForwardVector, 200.f, 40000.f, true);

		Gunner.AutoAimedTarget = AutoAimResult.AutoAimedAtComponent;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// In some circumstances, things we're auto-aiming at might be destroyed on one side!
		// So just bail for a while
		if (Gunner.AutoAimedTarget == nullptr)
			return;

		FVector Direction = Gunner.AutoAimedTarget.WorldLocation - Turret.TurretLocation;
		Direction.Normalize();

		Gunner.TargetAimDirection = Direction;
	}
}
