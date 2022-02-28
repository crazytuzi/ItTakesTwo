import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.WaterHose.WaterHoseComponent;
import Vino.Movement.MovementSystemTags;
import Vino.Camera.Components.CameraUserComponent;
import Cake.LevelSpecific.Garden.Sickle.Player.Sickle;
import Cake.LevelSpecific.Garden.Sickle.SickleTags;

class UWaterHoseAimAnimationCapability : UHazeCapability
{
	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	UHazeMovementComponent MoveComp;
	UWaterHoseComponent WaterHoseComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		WaterHoseComp = UWaterHoseComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (!WaterHoseComp.bWaterHoseActive)
        	return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!WaterHoseComp.bWaterHoseActive)
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		MoveComp.SetAnimationToBeRequested(n"WaterHose");
	}
}