import Cake.FlyingMachine.FlyingMachine;
import Cake.FlyingMachine.Pilot.FlyingMachinePilotComponent;
import Cake.FlyingMachine.FlyingMachineNames;

class UFlyingMachinePilotInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default CapabilityTags.Add(FlyingMachineTag::Machine);
	default CapabilityTags.Add(FlyingMachineTag::Input);
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 99;

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
		Machine = PilotComp.CurrentMachine;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		if (Machine != nullptr)
		{
			Machine.SetCapabilityAttributeVector(FlyingMachineAttribute::SteerInput, FVector::ZeroVector);
			Machine.SetCapabilityActionState(FlyingMachineAction::Boost, EHazeActionState::Inactive);	
			Machine = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Turning input
		FVector InputVector = GetAttributeVector(AttributeVectorNames::LeftStickRaw);

		if (Player.IsSteeringPitchInverted())
			InputVector.Y *= -1.f;

		Machine.SetCapabilityAttributeVector(FlyingMachineAttribute::SteerInput, InputVector);

		// Boosting 
		Machine.SetCapabilityActionState(FlyingMachineAction::Boost, TranslateAction(ActionNames::MovementDash));
	}

	EHazeActionState TranslateAction(FName ActionName)
	{
		return IsActioning(ActionName) ? EHazeActionState::Active : EHazeActionState::Inactive;
	}
}