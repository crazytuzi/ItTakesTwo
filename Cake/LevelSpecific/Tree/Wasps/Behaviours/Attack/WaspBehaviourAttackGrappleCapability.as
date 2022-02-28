import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourAttackGrappleCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Attack;
    default SetPriority(EWaspBehaviourPriority::High);

    FVector AttackDestination;
    FVector AttackDirection;
    float TrackTime = 0.f;
 
 	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
    		return EHazeNetworkActivation::DontActivate;
        if (!BehaviourComponent.bHasPerformedSustainedAttack) 
    		return EHazeNetworkActivation::DontActivate; // Never do this as the first attack
        if (Time::GetGameTimeSeconds() < BehaviourComponent.GetGrappleCooldownTime())
            return EHazeNetworkActivation::DontActivate;

        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

        // Don't want any others to grapple for a while
        BehaviourComponent.ReportGrapple();

        // Set destination
        UpdateAttackDestination();
        TrackTime = Time::GetGameTimeSeconds() + Settings.AttackRunTrackDuration;

        // Play start anim
		AnimComp.PlayAnimation(EWaspAnim::Grapple_Attack, 0.1f);

		// Stop any ongoing quick attack sequence
		BehaviourComponent.QuickAttackSequenceCount = 0;
    }

    void UpdateAttackDestination()
    {
        AttackDestination = BehaviourComponent.GetAttackRunDestination(BehaviourComponent.GetTarget());
        AttackDirection = (AttackDestination - Owner.GetActorLocation()).GetSafeNormal();
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        Super::OnDeactivated(DeactivationParams);
        if (BehaviourComponent.State != EWaspState::Grapple)
			AnimComp.StopAnimation(EWaspAnim::Grapple_Attack, 0.1f);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (Time::GetGameTimeSeconds() < TrackTime)
            UpdateAttackDestination();

        if (ShouldRecover())
        {
            BehaviourComponent.State = EWaspState::Recover; 
            return;
        }

        if (BehaviourComponent.CanHitTarget(BehaviourComponent.GetTarget(), 100.f, 0.15f, false))
        {
            // Try grapple
            BehaviourComponent.State = EWaspState::Grapple;
            return;
        }

        // Initial hover...
        FVector CurDestination = AttackDestination;
        if (BehaviourComponent.GetStateDuration() > 1.f)
        {
            // ...then all out charge!
            FVector ToDestination = (AttackDestination - Owner.GetActorLocation());
            if (ToDestination.DotProduct(AttackDirection) < 0.f)
            {
                // Past attack destination, adjust upwards
                CurDestination = AttackDestination + (FVector(AttackDirection.X, AttackDirection.Y, 1.f) * 500.f);                
            }
            BehaviourComponent.MoveTo(CurDestination, Settings.AttackRunAcceleration);
        }
        BehaviourComponent.RotateTowards(CurDestination + AttackDirection * 1000.f);
        BehaviourComponent.ReportGrapple();
    }
    
    bool ShouldRecover()
    {
        // Have we lost target?
        if (!BehaviourComponent.HasValidTarget())
            return true;
 
        // Has attack gone for too long?
        if (BehaviourComponent.GetStateDuration() > 5.f)
            return true;
 
        // Have we passed some ways beyond destination?
        FVector ToDestination = (AttackDestination + AttackDirection * 200.f  - Owner.GetActorLocation());
        if (ToDestination.DotProduct(AttackDirection) < 0.f)
            return true; 
        
        // Keep on coming!
        return false;
    }
}

