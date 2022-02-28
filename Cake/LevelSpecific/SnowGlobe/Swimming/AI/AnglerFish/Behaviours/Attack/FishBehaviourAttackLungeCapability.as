import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourCapability;

class UFishBehaviourAttackLungeCapability : UFishBehaviourCapability
{
    default State = EFishState::Attack;
	float MaxEatDuration = 1.5f;
	float BiteTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
   		Super::OnActivated(ActivationParams);
		float Dist = Owner.GetDistanceTo(BehaviourComponent.Target);

		AnimComp.SetGapingPercentage(100.f);
		BiteTime = Time::GetGameTimeSeconds() + FMath::GetMappedRangeValueClamped(FVector2D(8000.f, 30000.f), FVector2D(0.f, 1.2f), Dist);
		EffectsComp.SetEffectsMode(EFishEffectsMode::Attack);

		MaxEatDuration = FMath::GetMappedRangeValueClamped(FVector2D(4000.f, 30000.f), FVector2D(0.2f, 1.5f), Dist);
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		AnimComp.SetGapingPercentage(0.f);
    }

    UFUNCTION()
    void OnAttackHit(AHazeActor Target)
    {
		if (!IsActive())
			return;

        BehaviourComponent.State = EFishState::Recover; 
		BehaviourComponent.Food.AddUnique(Target);
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (HitAnyTarget())
		{
			BehaviourComponent.State = EFishState::Recover;
		}

		if (Time::GetGameTimeSeconds() > BiteTime)
		{
			AnimComp.Bite();
			BiteTime = BIG_NUMBER;
		}

		// Lunge!
		BehaviourComponent.MoveTo(BehaviourComponent.Target.ActorLocation, Settings.AttackLungeAcceleration, Settings.AttackTurnDuration);

		// We can now do damage.
		BehaviourComponent.PerformSustainedAttack(0.5f);
    }

	bool HitAnyTarget()
	{
		// Check if we can eat any player. We might eat someone other than target by accident, big mouth after all :)
		bool bHit = false;
		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		for (AHazePlayerCharacter Target : Players)
		{
			if (BehaviourComponent.CanHitTarget(Target, Settings.AttackRunHitRadius + 800.f, 0.01f))
			{
				Eat(Target);
				bHit = true;
			}
		}
		if (!bHit && (BehaviourComponent.StateDuration > MaxEatDuration))
		{
			// Auto hit target in case we've bounced off bad geometry
			Eat(BehaviourComponent.Target);
			return true;
		}
		return bHit;
	}

	void Eat(AHazeActor Target)
	{
		// To ensure best synced crumb trail we use our crumb component when hitting a target 
		// on our control side and the targets crumb component when hitting on on our remote side.
		UHazeCrumbComponent HitCrumbComp = HasControl() ? CrumbComp : UHazeCrumbComponent::Get(Target);
		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"Food", Target);
		HitCrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbEat"), CrumbParams);
	}

	UFUNCTION()
	void CrumbEat(const FHazeDelegateCrumbData& CrumbData)
	{
		// Glomp!
		AHazeActor Food = Cast<AHazeActor>(CrumbData.GetObject(n"Food"));
		BehaviourComponent.Food.AddUnique(Food);
		BehaviourComponent.OnAttackRunHit.Broadcast(Food);
	}
}

