import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UWallWalkingAnimalDebugCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(CapabilityTags::Debug);

	default CapabilityDebugCategory = n"Debug";



	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void SetupDebugVariables(FHazePerActorDebugCreationData& DebugValues) const
	{
		DebugValues.AddDebugSettingsValue(n"ShowSpiderDebug", 1);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Owner.GetDebugFlag(n"ShowSpiderDebug"))
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Owner.GetDebugFlag(n"ShowSpiderDebug"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		PrintToScreen("SPIDER: " + Owner.GetName());
	}
}


class UWallWalkingAnimalPlayerDebugCapability : UHazeDebugCapability
{
	default CapabilityTags.Add(CapabilityTags::Debug);

	default CapabilityDebugCategory = n"Debug";

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!Owner.GetDebugFlag(n"ShowSpiderDebug"))
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!Owner.GetDebugFlag(n"ShowSpiderDebug"))
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
	
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{		
		PrintToScreen("Player riding on spider: " + Owner.GetName());
	}
}