import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourGentlemanCircleCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Combat;
    default SetPriority(EWaspBehaviourPriority::High);

    float CircleHeight = 0.f;
    float AdjustHeightTime = 0.f;

	UFUNCTION(BlueprintOverride) 
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
    		return EHazeNetworkActivation::DontActivate;
        if (!Settings.bUseGentleManFighting)
        	return EHazeNetworkActivation::DontActivate;
        UGentlemanFightingComponent GentlemanComp = BehaviourComponent.GetGentlemanComponent();
		if (GentlemanComp == nullptr)
			return EHazeNetworkActivation::DontActivate;
		if (GentlemanComp.IsActionAvailable(n"WaspAttack"))
			return EHazeNetworkActivation::DontActivate;
       	return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (Super::ShouldDeactivate() != EHazeNetworkDeactivation::DontDeactivate)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        if (!Settings.bUseGentleManFighting)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        UGentlemanFightingComponent GentlemanComp = BehaviourComponent.GetGentlemanComponent();
        if (GentlemanComp == nullptr)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        if (GentlemanComp.IsActionAvailable(n"WaspAttack"))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
        AdjustHeightTime = 0.f;
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

        float CurTime = Time::GetGameTimeSeconds();
        if (CurTime > AdjustHeightTime)
        {
            CircleHeight = AdjustCircleHeight();
            AdjustHeightTime = CurTime + 0.5f;
        }

        // Keep moving to attack destination
        AHazeActor Target = BehaviourComponent.GetTarget();
        float CircleDistance = Settings.GentlemanDistance;
        FVector Dest = BehaviourComponent.GetCirclingDestination(Target.GetActorLocation(), CircleHeight, Owner.GetActorForwardVector(), CircleDistance);
        BehaviourComponent.MoveTo(Dest, 1500.f);
    }

    float AdjustCircleHeight()
    {
        float GentlemanHeight = BehaviourComponent.GetTarget().GetActorLocation().Z + Settings.GentlemanHeight;
        float GoodHeight = FMath::Clamp(Owner.GetActorLocation().Z, GentlemanHeight - 100.f, GentlemanHeight + 200.f);
        TSet<AHazeActor> Wasps = BehaviourComponent.Team.GetMembers();
        FVector PredictedLocation = Owner.GetActorLocation() + BehaviourComponent.GetVelocity() * 0.3f;
        for (AHazeActor Wasp : Wasps)
        {
            if (Wasp == Owner)
                continue;
            FVector OtherPredictedLocation = Wasp.GetActorLocation() + Wasp.GetActualVelocity() * 0.3f;
            if (PredictedLocation.DistSquared2D(OtherPredictedLocation) < FMath::Square(200.f))
            {
                float HeightDiff = (PredictedLocation.Z - OtherPredictedLocation.Z);
                GoodHeight += 200.f * FMath::Max(1.f - FMath::Abs(HeightDiff * 0.005f), 0.f) * FMath::Sign(HeightDiff);    
            }            
        }
        return GoodHeight;
    }
}

