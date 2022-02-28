import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;

class UWaspBehaviourFindTargetCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Idle;
	default SetPriority(EWaspBehaviourPriority::Low);

	float CanSwitchTargetTime = -BIG_NUMBER;

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaSeconds)
    {
		if (HasControl())
		{
			if (HealthComp.IsSapped())
			{
				// Don't try to find target when sapped!
				BehaviourComponent.State = EWaspState::Stunned; 
				return;
			}

			AHazeActor BestTarget = FindBestTarget(); 
			if (BestTarget != nullptr)
			{
				// Note that this may switch control side!
				BehaviourComponent.SetTarget(BestTarget);
				CanSwitchTargetTime = Time::GetGameTimeSeconds() + 2.f;
			}
			else if ((BehaviourComponent.Target != nullptr) && !BehaviourComponent.IsValidTarget(BehaviourComponent.Target))
			{
				// Lose current target if it's invalid
				BehaviourComponent.SetTarget(nullptr);
			}
		}

		// If any new target is on remote side, we will have switched control side here, 
		// so will stay in this state doing nothing until other side tells us otherwise.
        if (HasControl() && BehaviourComponent.HasValidTarget())
		{
			// We've found a target, proceed with next state!
            BehaviourComponent.State = BehaviourComponent.FindTargetExitState; 
			
			// Only use any overriden exit state once, then revert to engaging target
			BehaviourComponent.FindTargetExitState = EWaspState::Combat;
            return;
        }
    }

    AHazeActor FindBestTarget()
    {
		// Always go with aggro target when valid
		if (BehaviourComponent.IsValidTarget(BehaviourComponent.AggroTarget))
			return BehaviourComponent.AggroTarget;

		if (BehaviourComponent.HasValidTarget())
		{
			// Should we stay with current target?
			if (Time::GetGameTimeSeconds() < CanSwitchTargetTime)
				return BehaviourComponent.Target;
			if (BehaviourComponent.SameTargetAttackCount < Settings.NumAttacksBeforeSwitchingTarget)
				return BehaviourComponent.Target;
		}

		// Find new target
		if (Settings.TargetSelection == EWaspTargetSelection::Alternate)
		{
			if (BehaviourComponent.HasValidTarget())
			{
				AHazeActor AlternateTarget = Game::GetCody();
				if (BehaviourComponent.Target == Game::GetCody())
					AlternateTarget = Game::GetMay();
				if (BehaviourComponent.IsValidTarget(AlternateTarget))
					return AlternateTarget;
			} 
		}

        float MaxDistanceSqr = FMath::Square(Settings.MaxTargetDistance);
        float ClosestTargetDistSqr = MaxDistanceSqr;
        int32 LeastNumOpponents = 1000000;
        AHazeActor BestTarget = nullptr;
        TArray<AHazePlayerCharacter> PotentialTargets = Game::GetPlayers();
        for (AHazePlayerCharacter PotentialTarget : PotentialTargets)
        {
			if (!BehaviourComponent.IsValidTarget(PotentialTarget))
				continue;

            float TargetDistSqr = Owner.GetSquaredDistanceTo(PotentialTarget);
            if (TargetDistSqr < MaxDistanceSqr)
            {
                UGentlemanFightingComponent GentleManComp = UGentlemanFightingComponent::Get(PotentialTarget);
                int32 NumOpponents = (GentleManComp != nullptr) ? GentleManComp.GetNumOtherOpponents(Owner) : 0;
                if (NumOpponents < LeastNumOpponents)
                {
                    // Go for the one with least opponents
                    LeastNumOpponents = NumOpponents;                 
                    ClosestTargetDistSqr = TargetDistSqr;
                    BestTarget = PotentialTarget;
                }
                else if ((NumOpponents == LeastNumOpponents) && 
                         (TargetDistSqr < ClosestTargetDistSqr))
                {
                    // If equal number of opponents, go for the closest one
                    ClosestTargetDistSqr = TargetDistSqr;
                    BestTarget = PotentialTarget;
                }
            }
        }

        return BestTarget;
    }
}
