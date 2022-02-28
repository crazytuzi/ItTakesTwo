import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.Pilot.FlyingMachinePilotComponent;
import Cake.FlyingMachine.FlyingMachineNames;

class UFlyingMachinePilotCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 1;

	AHazePlayerCharacter Player;
	UFlyingMachinePilotComponent PilotComp;
	AFlyingMachine Machine;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PilotComp = UFlyingMachinePilotComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (PilotComp.CurrentMachine == nullptr)
			return EHazeNetworkActivation::DontActivate;
			
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (PilotComp.CurrentMachine == nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;
			
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.CleanupCurrentMovementTrail();
		Player.BlockMovementSyncronization(this);

		Machine = PilotComp.CurrentMachine;
		Machine.Pilot = Player;
		Player.AttachToComponent(Machine.Mesh, n"Align");
		Player.BlockCapabilities(CapabilityTags::Movement, this);

		Player.AddLocomotionFeature(Machine.PilotFeature);

		Machine.CallOnStartDrivingEvent();
		Player.DisableOutlineByInstigator(this);

		Player.Mesh.AddTickPrerequisiteComponent(Machine.Mesh);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockMovementSyncronization(this);

		if (Machine != nullptr)
		{
			Player.RemoveLocomotionFeature(Machine.PilotFeature);
			Machine.CallOnStopDrivingEvent();
			Player.Mesh.RemoveTickPrerequisiteComponent(Machine.Mesh);
			Machine.Pilot = nullptr;
			Machine = nullptr;
		}

		Player.DetachRootComponentFromParent();
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.EnableOutlineByInstigator(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeRequestLocomotionData AnimRequest;
		AnimRequest.AnimationTag = n"FlyingMachine";
		Player.RequestLocomotion(AnimRequest);
	}
}