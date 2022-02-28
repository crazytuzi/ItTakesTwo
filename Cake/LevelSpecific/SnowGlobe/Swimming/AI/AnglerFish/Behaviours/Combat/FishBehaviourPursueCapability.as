import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourCapability;

class UFishBehaviourPursueCapability : UFishBehaviourCapability
{
    default State = EFishState::Combat;
	float FrustrationTime = BIG_NUMBER;
	FVector FrustrationLocation = FVector::ZeroVector;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		FrustrationTime = Time::GetGameTimeSeconds() + Settings.PursueFrustrationDuration;
		EffectsComp.SetEffectsMode(EFishEffectsMode::Attack);
		AnimComp.SetGapingPercentage(50.f);
		AnimComp.SetAgitated(true);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		AHazeActor Target = BehaviourComponent.GetTarget();
        if (!BehaviourComponent.CanHuntTarget(Target))
        {
            // Lost target
            BehaviourComponent.State = EFishState::Recover; 
            return;
        }

		UpdateFrustration();

        if (IsInAttackPosition(Target)) 
        {
            // We can start an attack run
            BehaviourComponent.State = EFishState::Attack;
            return;
        }

        // Keep moving towards target
        BehaviourComponent.MoveTo(Target.ActorLocation, Settings.PursueAcceleration, Settings.PursueTurnDuration);
    }

	void UpdateFrustration()
	{
		if (Owner.GetActorLocation().DistSquared2D(FrustrationLocation) > 100.f*100.f)
		{
			FrustrationTime = Time::GetGameTimeSeconds() + Settings.PursueFrustrationDuration;
			FrustrationLocation = Owner.GetActorLocation();
		}
	}

    bool IsInAttackPosition(AHazeActor Target)
    {
		if (Time::GetGameTimeSeconds() > FrustrationTime)
			return true; // Dagnabbit, we've had enough of being stuck!

        FVector ToTarget = (Target.ActorLocation - Owner.ActorLocation);
		if (ToTarget.SizeSquared() < FMath::Square(Settings.LaunchAttackRange))
			return true;

		float CosAttackAngle = FMath::Cos(FMath::DegreesToRadians(Settings.LaunchAttackAngle));
		if (ToTarget.GetSafeNormal().DotProduct(BehaviourComponent.MawForwardVector) > CosAttackAngle)
        	return true;

		return false;
    }
}

