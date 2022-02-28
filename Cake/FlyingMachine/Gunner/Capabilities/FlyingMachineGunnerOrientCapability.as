import Cake.FlyingMachine.FlyingMachineNames;
import Cake.FlyingMachine.Gunner.FlyingMachineGunnerComponent;
import Vino.Camera.Components.CameraUserComponent;

class UFlyingMachineGunnerOrientCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default CapabilityTags.Add(FlyingMachineTag::Gunner);

	default TickGroup = ECapabilityTickGroups::LastDemotable;
	default TickGroupOrder = 105;
	default CapabilityDebugCategory = FlyingMachineCategory::Gunner;

	AHazePlayerCharacter Player;
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
		Gunner.CurrentAimDirection = Turret.TurretForward;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Turret = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Rotate direction
		{
			FQuat DeltaQuat = FQuat::FindBetweenNormals(Gunner.CurrentAimDirection, Gunner.TargetAimDirection);

			FVector Axis;
			float Angle = 0.f;
			DeltaQuat.ToAxisAndAngle(Axis, Angle);

			Angle = Angle * 10.f * DeltaTime;
			DeltaQuat = FQuat(Axis, Angle);

			Gunner.CurrentAimDirection = DeltaQuat.RotateVector(Gunner.CurrentAimDirection);

			Turret.RotateToDirection(Gunner.CurrentAimDirection);

			FTransform Trans = Turret.TurretTransform;
			FVector Loca = Turret.TurretLocation;
		}
	}
}