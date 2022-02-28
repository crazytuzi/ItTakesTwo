import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStone;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingStoneComponent;
import Cake.LevelSpecific.SnowGlobe.IceSkating.IceSkatingComponent;

class UCurlingStonePlayStateCapability : UHazeCapability
{
	default CapabilityTags.Add(n"CurlingStonePlayStateCapability");
	default CapabilityTags.Add(n"CurlingStoneMovement");

	default CapabilityDebugCategory = n"GamePlay";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	ACurlingStone CurlingStone;

	UHazeMovementComponent MoveComp;

	UCurlingStoneComponent StoneComp;

	//UIceSkatingComponent PlayerIceSkatingComp;

	UCurlingPlayerComp PlayerComp;

	FVector MovementForce;

	float Gravity = 2300.f;
	float Drag;
	float IceDrag = 0.4f;
	float BeforeShootDrag = 1.4f; 

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		CurlingStone = Cast<ACurlingStone>(Owner);

		MoveComp = UHazeMovementComponent::Get(CurlingStone);
		StoneComp = UCurlingStoneComponent::Get(CurlingStone);

		Drag = BeforeShootDrag;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (CurlingStone.GetRootComponent().GetAttachParent() != nullptr)
        	return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (CurlingStone.GetRootComponent().GetAttachParent() != nullptr)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}
}