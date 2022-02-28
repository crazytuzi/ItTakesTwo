import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourAttackSwoopCapability : UWaspBehaviourCapability
{
	default CapabilityTags.Add(n"AttackRun");
	
    default State = EWaspState::Attack;

    uint8 AttackIndex = 0;
    FVector AttackDestination;
    FVector AttackDirection;
    float TrackTime = 0;
	FVector UnstuckLoc;
	float UnstuckTime = 0.f;

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
    		return EHazeNetworkActivation::DontActivate;
        if (AnimComp.AnimFeature.Attacks.Num() == 0)
            return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
        // Choose attack variant (deterministic for now, but we'll want to randomize later so need to replicate)
		ActivationParams.AddNumber(n"AttackIndex", (AttackIndex + 1) % AnimComp.AnimFeature.Attacks.Num());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        Super::OnActivated(ActivationParams);

        // Set destination
        UpdateAttackDestination();
        TrackTime = Time::GetGameTimeSeconds() + Settings.AttackRunTrackDuration;

		AttackIndex = ActivationParams.GetNumber(n"AttackIndex");
		AnimComp.PlayAnimation(EWaspAnim::Attacks, AttackIndex, 0.1f);

        // Make sure we handle hits
        BehaviourComponent.OnAttackRunHit.AddUFunction(this, n"OnAttackHit");

		// Flash for a while at start of attack
		EffectsComp.FlashTime = Time::GetGameTimeSeconds() + 0.9f;

		// Update quick attack sequence
		if (BehaviourComponent.QuickAttackSequenceCount == 0)
			BehaviourComponent.QuickAttackSequenceCount = FMath::Max(Settings.NumQuickAttacks - 1, 0);
		else
			BehaviourComponent.QuickAttackSequenceCount--;			

		// Set up stuck check stuff
		UnstuckLoc = Owner.ActorLocation;
		UnstuckTime = Time::GameTimeSeconds;
    }

    void UpdateAttackDestination()
    {
		if (BehaviourComponent.Target == nullptr)
			return; // Can be null in network

        AttackDestination = BehaviourComponent.GetAttackRunDestination(BehaviourComponent.GetTarget());
        AttackDirection = (AttackDestination - Owner.GetActorLocation()).GetSafeNormal();
		EffectsComp.ShowAttackEffect(AttackDestination);
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        Super::OnDeactivated(DeactivationParams);
		AnimComp.StopAnimation(EWaspAnim::Attacks);
        BehaviourComponent.OnAttackRunHit.Unbind(this, n"OnAttackHit");
		EffectsComp.HideAttackEffect();
    }

    UFUNCTION()
    void OnAttackHit(AHazeActor Target)
    {
        if (IsActive() && HasControl())
        {
            // We've hit something, go straight to recovery
            BehaviourComponent.State = EWaspState::Recover; 
        }
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (Settings.bCanStunDuringAttackRun && HealthComp.IsSapped())
        {
            // Sapped!
            BehaviourComponent.State = EWaspState::Stunned; 
            return;
        }

		if (BehaviourComponent.Target != nullptr)
		{
			FVector ToTarget = (BehaviourComponent.Target.GetActorLocation() - Owner.GetActorLocation()).GetSafeNormal2D();
			float ToTargetDot = Owner.GetActorForwardVector().DotProduct(ToTarget);

			if (Time::GetGameTimeSeconds() < TrackTime && ToTargetDot > 0.707f)
			{
				UpdateAttackDestination();
			}
			else
			{
				AttackDestination += BehaviourComponent.TargetGroundVelocity.Value * DeltaTime;
			} 
		}

        if (ShouldRecover())
        {
            BehaviourComponent.State = EWaspState::Recover; 
            return;
        }

        if (BehaviourComponent.GetStateDuration() < 0.3f)
        {
            // Initial backwards swing...
            BehaviourComponent.MoveTo(Owner.GetActorLocation() - AttackDirection * 1000.f, 2000.f);
			UnstuckTime = Time::GameTimeSeconds;
        }
        else if (BehaviourComponent.GetStateDuration() > 0.5f)
        {
            // We can now do damage. Note that this will continue some short while after ending this behaviour.
            BehaviourComponent.PerformSustainedAttack(0.5f);

			UpdateStuck(DeltaTime);
			if (IsStuck())
			{
				// We've been stuck for a while, skip to recovery
				BehaviourComponent.State = EWaspState::Recover; 
				return;
			}

            // ...then all out charge!
            BehaviourComponent.MoveTo(AttackDestination, Settings.AttackRunAcceleration);
	    }
        BehaviourComponent.RotateTowards(AttackDestination + AttackDirection * 1000.f);
    }

    bool ShouldRecover()
    {
		if (!HasControl())
			return false;

        // Have we lost target?
        if (!BehaviourComponent.HasValidTarget())
            return true;

        // Has attack gone for too long?
        if (BehaviourComponent.GetStateDuration() > 5.f)
            return true;

        // Have we passed destination? 
        FVector ToDestination = (AttackDestination - Owner.GetActorLocation());
        if (ToDestination.DotProduct(AttackDirection) < 0.f)     
            return true;

        // Keep on coming!    
        return false;
    }

	void UpdateStuck(float DeltaTime)
	{
		if (Owner.ActorLocation.DistSquared2D(UnstuckLoc) < FMath::Square(1000.f * DeltaTime))
			return; // Might be stuck, don't update unstuck values
		UnstuckLoc = Owner.ActorLocation;
		UnstuckTime = Time::GameTimeSeconds;
	}

	bool IsStuck()
	{
		if (BehaviourComponent.GetStateDuration() < 1.f)
			return false;
		if (Time::GetGameTimeSince(UnstuckTime) < 0.5f)
			return false;
		return true;
	}
}

