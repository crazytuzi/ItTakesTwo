import Cake.LevelSpecific.Tree.Larvae.Behaviours.LarvaBehaviourCapability;

class ULarvaBehaviourPursueCapability : ULarvaBehaviourCapability
{
    default State = ELarvaState::Pursue;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		Owner.PlaySlotAnimation(Animation = BehaviourComponent.AnimFeature.Crawl_Mh, bLoop = true);
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

        if (CanAttack(BehaviourComponent.Target))
        {
            BehaviourComponent.State = ELarvaState::Attack; 
            return;
        }

        BehaviourMoveComp.CrawlTo(BehaviourComponent.Target.GetActorLocation());
    }

    bool CanAttack(AHazeActor Target)
    {
		float Range = Settings.AttackDistance;
		if (!BehaviourMoveComp.bUsingPathfindingCollision)
			Range += 100.f;

		UHazeMovementComponent TargetMoveComp = UHazeMovementComponent::Get(Target);
		if ((TargetMoveComp == nullptr) || (TargetMoveComp.IsGrounded()))
		{
			// Standing on ground, ignore height in case we're staning on an obstacle
			if (Owner.GetActorLocation().DistSquared2D(Target.GetActorLocation()) < FMath::Square(Range))
				return true;            
		}
		// Airborne, we want to allow player to double-jump over larvae
		else if (Owner.GetActorLocation().DistSquared(Target.GetActorLocation()) < FMath::Square(Range))
			return true;

        return false;
    }
}
