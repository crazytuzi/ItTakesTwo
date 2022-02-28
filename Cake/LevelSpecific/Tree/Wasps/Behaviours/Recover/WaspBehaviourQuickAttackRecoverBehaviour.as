import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourQuickAttackRecoverCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Recover;
    default SetPriority(EWaspBehaviourPriority::High);

    float RecoverHeight = 0.f;
    float RecoverTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams) override
	{
		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
    		return EHazeNetworkActivation::DontActivate;
		if (BehaviourComponent.QuickAttackSequenceCount == 0)
    		return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
        RecoverHeight = Owner.GetActorLocation().Z + Settings.RecoverHeight;
		RecoverTime = Time::GetGameTimeSeconds() + Settings.QuickAttackRecoveryDuration;
		if (Time::GetGameTimeSince(BehaviourComponent.LastAttackRunHitTime) < 1.f)
			RecoverTime = Time::GetGameTimeSeconds() + Settings.QuickAttackHitRecoveryDuration;

		// Do not release attack claim from gentleman comp, we want to keep that up until all quick attacks are done.
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        // Only react to saps some time into recovery
        if (HealthComp.IsSapped() && (BehaviourComponent.GetStateDuration() > 1.f))
        {
            // Sapped!
            BehaviourComponent.State = EWaspState::Stunned; 
            return;
        }

        if (!BehaviourComponent.HasValidTarget())
        {
            // Lost target
			BehaviourComponent.AbortQuickAttackSequence();
            BehaviourComponent.State = EWaspState::Idle; 
            return;
        }

		if (Time::GetGameTimeSeconds() > RecoverTime)
		{
			// Time's up, charge!
            BehaviourComponent.State = EWaspState::Attack; 
			return;
		}

		// Up, up and away!
        FVector OwnLoc = Owner.GetActorLocation();
        FVector Destination = OwnLoc;
        if (Time::GetGameTimeSeconds() < RecoverTime - 1.f)
             Destination += Owner.GetActorForwardVector() * 1000.f;
        Destination.Z = RecoverHeight;
        BehaviourComponent.MoveTo(Destination, FMath::Max(Settings.RecoverAcceleration * (RecoverHeight - OwnLoc.Z - 100.f), 0.f));

		// Look forwards until almost done, then turn back to target
        if (Time::GetGameTimeSeconds() < RecoverTime - 1.f)
			BehaviourComponent.RotateTowards(OwnLoc + Owner.GetActorForwardVector() * 1000.f);
		else
			BehaviourComponent.RotateTowards(BehaviourComponent.Target.GetFocusLocation());
    }
}

