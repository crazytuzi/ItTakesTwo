import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourCircleHopCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Combat;

    float HopStartTime;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
        HopStartTime = Time::GetGameTimeSeconds();
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
            // Lost target
            BehaviourComponent.State = EWaspState::Idle; 
            return;
        }

        AHazeActor Target = BehaviourComponent.GetTarget();
        FVector OwnLoc = Owner.GetActorLocation();
        float TimeFraction = Time::GetGameTimeSince(HopStartTime) / FMath::Max(Settings.CircleHopDuration, 0.1f);
        if (TimeFraction > 1.0f)
        {
            // Make sure we're fighting fair by only starting attack if we can claim that privilege
            if (BehaviourComponent.ClaimGentlemanAction(n"WaspAttack", Target))
            {
                // We can start an attack
                BehaviourComponent.State = EWaspState::Telegraphing;
            }
            // Drift to a stop
            return;
        }

        // Parabolic hop over duration
        FVector TargetLoc = Target.GetActorLocation();
        float HeightFraction = 1.f * (TimeFraction - FMath::Square(TimeFraction * 1.3f)) + 1.f;
        float HopHeight = TargetLoc.Z + (Settings.EngageHeight * HeightFraction);
        float CircleDistance = 0.5f * (Settings.EngageMinDistance + Settings.EngageMaxDistance);
        FVector Dest = BehaviourComponent.GetCirclingDestination(TargetLoc, HopHeight, Owner.GetActorForwardVector(), CircleDistance);
        BehaviourComponent.MoveTo(Dest, Settings.EngageAcceleration);
		BehaviourComponent.RotateTowards(TargetLoc);
    }
}

