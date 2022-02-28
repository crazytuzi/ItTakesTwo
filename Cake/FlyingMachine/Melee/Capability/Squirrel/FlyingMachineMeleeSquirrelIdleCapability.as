
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeSquirrelComponent;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFight180Turn;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightTaunt;

class UFlyingMachineMeleeSquirrelIdleCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(MeleeTags::MeleeSquirrelAi);

	default CapabilityDebugCategory = MeleeTags::Melee;

	default TickGroup = ECapabilityTickGroups::LastMovement;
	default TickGroupOrder = 190;

	AHazeCharacter Squirrel = nullptr;
	UFlyingMachineMeleeSquirrelComponent SquirrelMeleeComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Squirrel = Cast<AHazeCharacter>(Owner);
		SquirrelMeleeComponent = Cast<UFlyingMachineMeleeSquirrelComponent>(MeleeComponent);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsStateActive(EHazeMeleeStateType::None))
			return EHazeNetworkActivation::ActivateLocal;

		if(IsStateActive(EHazeMeleeStateType::Idle))
			return EHazeNetworkActivation::ActivateLocal;
		
		return EHazeNetworkActivation::DontActivate;
	}


	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if(IsStateActive(EHazeMeleeStateType::None))
			return EHazeNetworkDeactivation::DontDeactivate;

		if(IsStateActive(EHazeMeleeStateType::Idle))
			return EHazeNetworkDeactivation::DontDeactivate;

 		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		SquirrelMeleeComponent.IdleTime = 0;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SquirrelMeleeComponent.IdleTime = -1;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		SquirrelMeleeComponent.IdleTime += DeltaTime;
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Str = "";
		return Str;
	}
}
