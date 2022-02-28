import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourCapability;

class UFishBehaviourAttackBlindChargeCapability : UFishBehaviourCapability
{
    default State = EFishState::Attack;
	FVector Destination;
	FVector ChargeDir;
	AHazePlayerCharacter PlayerTarget = nullptr;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
   		Super::OnActivated(ActivationParams);
		Destination = BehaviourComponent.Target.ActorLocation; 
		ChargeDir = (Destination - Owner.ActorLocation).GetSafeNormal();

		// Can't dive or rise too steeply 
		const float MaxCos = 0.707f; // ~45 degrees from vertical
		float UpDot = FVector::UpVector.DotProduct(ChargeDir);
		if (FMath::Abs(UpDot) > MaxCos) 
		{
			// Scale xy and clamp z
			ChargeDir = ChargeDir.GetSafeNormal2D() * FMath::Sqrt(1.f - FMath::Square(MaxCos));
			ChargeDir.Z = MaxCos * FMath::Sign(UpDot);
		}

		AnimComp.SetGapingPercentage(100.f);
		EffectsComp.SetEffectsMode(EFishEffectsMode::Attack);

		PlayerTarget = Cast<AHazePlayerCharacter>(BehaviourComponent.GetTarget());
		if (PlayerTarget != nullptr)
		{
			FHazePointOfInterest POI;
			POI.FocusTarget.Actor = Owner;
			POI.Blend.BlendTime = 2.f;
			PlayerTarget.ApplyPointOfInterest(POI, this);
		}
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		AnimComp.SetGapingPercentage(0.f);
		if (PlayerTarget != nullptr)
			PlayerTarget.ClearPointOfInterestByInstigator(this);

		AudioComp.CleanupBlindCharge();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		if (!BehaviourComponent.CanHuntTarget(PlayerTarget))
		{
			// Lost target
			BehaviourComponent.State = EFishState::Recover;
			return;
		}

		if (IsTimeToBite())
		{
			BehaviourComponent.State = EFishState::Recover;
			return;
		}

		// Update destination so we'll always pass target
		FVector DestToTarget = PlayerTarget.ActorLocation - Destination;
		float ChargeDist = ChargeDir.DotProduct(DestToTarget);
		if (ChargeDist > 0.f)
			Destination += ChargeDir * ChargeDist;

		if (ChargeDir.DotProduct(Destination - Owner.ActorLocation) < 0.f)
		{
			// We've passed the destination
			BehaviourComponent.State = EFishState::Recover;
			return;
		}

		if (BehaviourComponent.StateDuration > Settings.AttackBlindChargeMaxDuration)
		{
			BehaviourComponent.State = EFishState::Recover;
			return;
		}

		// Charge!
		BehaviourComponent.MoveTo(Destination + ChargeDir * 10000.f, Settings.AttackBlindChargeAcceleration, Settings.AttackBlindChargeTurnDuration);
    }

	bool IsTimeToBite()
	{
		// On control side we might get told by remote side that there's food, in which case we should try to eat it!
		if (BehaviourComponent.Food.Num() > 0)
			return true;

		// Check if we can eat any player. We might eat someone other than target by accident, big mouth after all :)
		bool bHit = false;
		TArray<AHazePlayerCharacter> Players = Game::GetPlayers();
		for (AHazePlayerCharacter Target : Players)
		{
			if (BehaviourComponent.CanHitTarget(Target, Settings.AttackRunHitRadius + 0.f, 0.3f))
			{
				TryToEat(Target);
				bHit = true;
			}
		}
		return bHit;
	}

	void TryToEat(AHazeActor Target)
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
		AnimComp.Bite();
	}
}

