import Cake.FlyingMachine.Gunner.FlyingMachineGunnerComponent;
import Cake.FlyingMachine.FlyingMachineNames;

class UFlyingMachineGunnerCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default CapabilityTags.Add(FlyingMachineTag::Gunner);
	default CapabilityDebugCategory = FlyingMachineCategory::Gunner;
	default TickGroup = ECapabilityTickGroups::Input;

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
		Player.CleanupCurrentMovementTrail();
		Player.BlockMovementSyncronization(this);

		Turret = Gunner.CurrentTurret;
		Player.AttachToComponent(Turret.Mesh, n"Turret");
		Player.AddLocomotionFeature(Turret.GunnerFeature);

		Player.BlockCapabilities(CapabilityTags::Movement, this);

		Player.Mesh.AddTickPrerequisiteComponent(Turret.Mesh);

		// Initialize aim direction to be where the turret is actually looking
		Gunner.CurrentAimDirection = Turret.TurretForward;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockMovementSyncronization(this);

		Player.DetachRootComponentFromParent();
		if (Turret != nullptr)
		{
			Player.RemoveLocomotionFeature(Turret.GunnerFeature);
			Player.Mesh.RemoveTickPrerequisiteComponent(Turret.Mesh);
		}

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeRequestLocomotionData AnimRequest;
		AnimRequest.AnimationTag = n"FlyingMachine";
		AnimRequest.WantedVelocity = GetAttributeVector(AttributeVectorNames::MovementRaw);
		Player.RequestLocomotion(AnimRequest);
	}
}