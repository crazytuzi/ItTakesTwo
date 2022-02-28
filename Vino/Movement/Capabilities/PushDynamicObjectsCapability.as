import Vino.Movement.Components.MovementComponent;
import Vino.Movement.MovementSystemTags;

class UPushDynamicObjectsCapability : UHazeCapability
{
    UHazeMovementComponent Movement;

	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::Physics);
    default CapabilityTags.Add(MovementSystemTags::PhysicsForce);

    default TickGroup = ECapabilityTickGroups::AfterGamePlay;

	default CapabilityDebugCategory = CapabilityTags::Movement;

    UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
    {
        Movement = UHazeMovementComponent::GetOrCreate(Owner);
        
    }

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        UPrimitiveComponent OtherComp = Movement.Impacts.ForwardImpact.Component;
		if (OtherComp != nullptr && OtherComp.IsAnySimulatingPhysics())
		    return EHazeNetworkActivation::ActivateLocal;

        return EHazeNetworkActivation::DontActivate;
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        UPrimitiveComponent OtherComp = Movement.Impacts.ForwardImpact.Component;
		if (OtherComp == nullptr || !OtherComp.IsAnySimulatingPhysics())
		    return EHazeNetworkDeactivation::DeactivateLocal;

        return EHazeNetworkDeactivation::DontDeactivate;
	}

    UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
    {
        FHitResult ForwardHit = Movement.Impacts.ForwardImpact;
        FHitResult DownHit = Movement.Impacts.DownImpact;

        if(ForwardHit.Component == DownHit.Component)
        {
           //Print("Simon, you fucked up. DownHit and ForwardHit: " + ForwardHit.Actor.GetName(), Color = FLinearColor::Red);
        }
        else
        {
			// TODO::MovementSettings - PushSettings?
            //Movement.ApplyPushForceOnObject(ForwardHit, Movement.PushMultiplier); 
        }
        
    }
};