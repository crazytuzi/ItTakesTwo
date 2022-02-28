import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourEngageCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Combat;

    FVector AttackOffset;
	float FrustrationTime = BIG_NUMBER;
	FVector FrustrationLocation = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

        // Find a nice position relative to target to engage from
        FVector OffsetDir = BehaviourComponent.GetTarget().GetActorForwardVector();
        AHazePlayerCharacter PlayerTarget = Cast<AHazePlayerCharacter>(BehaviourComponent.GetTarget());
        if (PlayerTarget != nullptr)
            OffsetDir = PlayerTarget.GetViewRotation().GetForwardVector().GetSafeNormal2D();
		if (Settings.bAllowBackStabbing)
		{
			// Just go for closest location
			OffsetDir = (Owner.ActorLocation - BehaviourComponent.GetTarget().ActorLocation).GetSafeNormal2D();
		}
        AttackOffset = OffsetDir * GetEngageDistance();
        AttackOffset += FVector::UpVector * Settings.EngageHeight;

		FrustrationTime = Time::GetGameTimeSeconds() + Settings.EngageFrustrationDuration;
	}

    float GetEngageDistance()
    {
        // Engage min/max center distance
        return 0.5f * (Settings.EngageMinDistance + Settings.EngageMaxDistance);
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

		UpdateFrustration();

        AHazeActor Target = BehaviourComponent.GetTarget();
        if (IsInAttackPosition(Target)) 
        {
            // Make sure we're fighting fair by only starting attack if we can claim that privilege
            if (BehaviourComponent.ClaimGentlemanAction(n"WaspAttack", Target))
            {
                // We can start an attack run
                BehaviourComponent.State = EWaspState::Telegraphing;
            }
            // Drift to a stop
            return;
        }

        // Keep moving to attack destination
        FVector Dest = GetAttackDestination(Target);
        float Acc = FMath::Min(Settings.EngageAcceleration, Owner.GetActorLocation().Distance(Dest) * 2.f);
        Dest = GetCirclingDestination(Dest, Target);
        BehaviourComponent.MoveTo(Dest, Acc);
		BehaviourComponent.RotateTowards(Target.GetActorLocation());
    }

	void UpdateFrustration()
	{
		if (Owner.GetActorLocation().DistSquared2D(FrustrationLocation) > 100.f*100.f)
		{
			FrustrationTime = Time::GetGameTimeSeconds() + Settings.EngageFrustrationDuration;
			FrustrationLocation = Owner.GetActorLocation();
		}
	}

    FVector GetAttackDestination(AHazeActor Target)
    {
        return Target.GetActorLocation() + AttackOffset;
    }

    FVector GetCirclingDestination(const FVector& Dest, AHazeActor Target)
    {
        FVector OwnLoc = Owner.GetActorLocation();
        FVector TargetLoc = Target.GetActorLocation();
        FVector ToTarget = (TargetLoc - OwnLoc);
        FVector DestToTarget = (TargetLoc - Dest);
        if (ToTarget.DotProduct(DestToTarget) > 0.f)
        {
            // Target is not in the way of destination
            return Dest;
        }

        // Target is between us and destination, circle around
        FVector ToDest = Dest - OwnLoc;
        return BehaviourComponent.GetCirclingDestination(TargetLoc, Settings.EngageHeight, ToDest, GetEngageDistance());
    }

    bool IsInAttackPosition(AHazeActor Target)
    {
		if (Time::GetGameTimeSeconds() > FrustrationTime)
			return true; // Dagnabbit, we've had enough of being stuck!

        FVector AttackDest = GetAttackDestination(Target);
        if (Owner.GetActorLocation().DistSquared(AttackDest) > FMath::Square(Settings.EngageMinDistance * 1.4f))
            return false;
        float DistToTargetSqr2D = Owner.GetActorLocation().DistSquared2D(Target.GetActorLocation());
        if (DistToTargetSqr2D < FMath::Square(Settings.EngageMinDistance))
            return false;
        if (DistToTargetSqr2D > FMath::Square(Settings.EngageMaxDistance))
            return false;
        return true;
    }
}

