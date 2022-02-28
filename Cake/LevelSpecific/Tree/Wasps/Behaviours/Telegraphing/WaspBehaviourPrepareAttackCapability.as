import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourPrepareAttackCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Telegraphing;

    float AttackTime;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

        // Set time for attack
        AttackTime = Time::GetGameTimeSeconds() + Settings.PrepareAttackDuration;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (HealthComp.IsSapped())
        {
            // Sapped!
            BehaviourComponent.State = EWaspState::Stunned; 
            return;
        }

        if (!BehaviourComponent.HasValidTarget())
        {
            BehaviourComponent.State = EWaspState::Idle; // Lost target
            return;
        }

        if (Time::GetGameTimeSeconds() > AttackTime)
        {
            BehaviourComponent.State = EWaspState::Attack;
            return;
        }

        // Push away when close to target, otherwise drift to a stop 
        FVector TargetLoc = BehaviourComponent.GetTarget().GetActorLocation();
        FVector OwnLoc = Owner.GetActorLocation();
        if (OwnLoc.DistSquared2D(TargetLoc) < FMath::Square(Settings.EngageMinDistance))
        {
            FVector AwayDir = (OwnLoc - TargetLoc).GetSafeNormal2D();
            BehaviourComponent.MoveTo(OwnLoc + AwayDir * Settings.EngageMaxDistance, 2000.f);
        }

        // Face target
        BehaviourComponent.RotateTowards(BehaviourComponent.GetTarget().GetFocusLocation());
    }
}

