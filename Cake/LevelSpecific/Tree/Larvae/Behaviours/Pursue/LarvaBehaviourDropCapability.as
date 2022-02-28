import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourCapability;

class ULarvaBehaviourDropCapability : ULarvaBehaviourCapability
{
    default State = ELarvaState::Pursue;
    default Priority = ELarvaPriority::High;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
			return EHazeNetworkActivation::DontActivate;
		if (BehaviourComponent.CanEatSap())
			return EHazeNetworkActivation::DontActivate;
        if (!BehaviourComponent.HasValidTarget())
			return EHazeNetworkActivation::DontActivate;
		if (!CanDropOnTarget(BehaviourComponent.Target))
			return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	bool CanDropOnTarget(AHazeActor Target) const
	{
		if (Owner.ActorLocation.Z - BehaviourComponent.TargetGroundHeight < Settings.DropHeight)
			return false;

		// Lower drop radius when not upside down
		float DropRadius = Settings.DropRadius * Owner.ActorUpVector.DotProduct(-FVector::UpVector);
		if (DropRadius < 0.f)
			return false;
		FVector ToTarget = Target.ActorLocation - Owner.ActorLocation;
		return (ToTarget.SizeSquared2D() < FMath::Square(DropRadius));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		Owner.PlaySlotAnimation(Animation = BehaviourComponent.AnimFeature.Crawl_Mh, bLoop = true); // Replace with drop anim
		BehaviourComponent.State = ELarvaState::Pursue;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
        if (BehaviourComponent.CanEatSap())
        {
            // Sapped, nom nom!
            BehaviourComponent.State = ELarvaState::Stunned; 
            return;
        }

        if (!BehaviourComponent.HasValidTarget())
		{
			// Lost target
            BehaviourComponent.State = ELarvaState::Idle; 
            return;
        }

        if (Owner.ActorLocation.Z < BehaviourComponent.Target.ActorLocation.Z + (Settings.DropHeight - 50.f))
		{
			// Restart targeting
            BehaviourComponent.State = ELarvaState::Idle; 
			return;			
		}

        BehaviourMoveComp.DropTo(BehaviourComponent.Target.GetActorLocation());
    }
}
