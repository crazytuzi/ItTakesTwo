import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;
import Vino.Movement.Components.MovementComponent;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;

class UWallWalkingAnimalFaceInputCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AWallWalkingAnimal TargetAnimal;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TargetAnimal = Cast<AWallWalkingAnimal>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!TargetAnimal.IsCarryingPlayer())
			return EHazeNetworkActivation::DontActivate;

		if(TargetAnimal.bPreparingToLaunch)
			return EHazeNetworkActivation::DontActivate;

		if(TargetAnimal.bRidingPlayerIsAiming)
			return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!TargetAnimal.IsCarryingPlayer())
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TargetAnimal.bPreparingToLaunch)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TargetAnimal.bRidingPlayerIsAiming)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetAnimal.bFaceCameraDirection = false;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TargetAnimal.bFaceCameraDirection = true;
		AHazePlayerCharacter CurrentPlayer = TargetAnimal.GetPlayer();
		if(CurrentPlayer != nullptr)
		{
			TargetAnimal.MoveComp.SetTargetFacingRotation(CurrentPlayer.GetControlRotation());
		}		
	}
}