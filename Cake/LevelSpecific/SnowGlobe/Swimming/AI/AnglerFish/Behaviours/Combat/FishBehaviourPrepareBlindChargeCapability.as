import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourCapability;
import Peanuts.Audio.AudioStatics;

class UFishBehaviourPrepareBlindChargeCapability : UFishBehaviourCapability
{
    default State = EFishState::Combat;
	float ChargeTime = BIG_NUMBER;
	AHazePlayerCharacter PlayerTarget = nullptr;
	bool bOtherPlayerDanger = false;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		PlayerTarget = Cast<AHazePlayerCharacter>(BehaviourComponent.GetTarget());
		float DistToTarget = Owner.GetDistanceTo(PlayerTarget);

		// Time we start charge at. 
		float PrepareDuration = Settings.PrepareBlindChargeDuration;
		ChargeTime = Time::GetGameTimeSeconds() + PrepareDuration;

		EffectsComp.SetEffectsMode(EFishEffectsMode::Attack);
		float GapeDuration = PrepareDuration * FMath::GetMappedRangeValueClamped(FVector2D(4000.f, 15000.f), FVector2D(1.f, 3.f), DistToTarget);
		AnimComp.SetGapingPercentage(100.f, GapeDuration);
		AnimComp.SetAgitated(true);

		AudioComp.PrepareBlindCharge(PlayerTarget);
	
		if (PlayerTarget != nullptr)
		{
			FHazePointOfInterest POI;
			POI.FocusTarget.Actor = Owner;
			POI.Blend.BlendTime = 1.f;
			PlayerTarget.ApplyPointOfInterest(POI, this);
		}

		bOtherPlayerDanger = false;
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		if (PlayerTarget != nullptr)
		{
			PlayerTarget.ClearPointOfInterestByInstigator(this);
			if (PlayerTarget.OtherPlayer != nullptr)
				PlayerTarget.OtherPlayer.ClearPointOfInterestByInstigator(this);
		}
	}

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		float CurTime = Time::GetGameTimeSeconds();
        if (!BehaviourComponent.CanHuntTarget(PlayerTarget))
        {
            // Lost target
            BehaviourComponent.State = EFishState::Recover; 
            return;
        }

		// Check if other player comes into the path of charge when the fish swings around
		if (!bOtherPlayerDanger && IsInDangerZone(PlayerTarget.OtherPlayer))
			NotifyDanger(PlayerTarget.OtherPlayer);

		if (CurTime >= ChargeTime)
		{
			// Charge!
			BehaviourComponent.State = EFishState::Attack;
			return;			
		}

		// Calculate turn duration based on fraction of lunge time and distance to target
		float TurnDuration = Settings.PrepareBlindChargeTurnDuration;
		float DistFactor = FMath::GetMappedRangeValueClamped(FVector2D(5000.f, 15000.f), FVector2D(1.f, 5.f), Owner.GetDistanceTo(PlayerTarget));
		TurnDuration *= DistFactor;

        // Keep moving towards target
        BehaviourComponent.MoveTo(PlayerTarget.ActorLocation, Settings.PrepareBlindChargeAcceleration, TurnDuration);
    }

	bool IsInDangerZone(AHazeActor Target)
	{
		if (Target == nullptr)
			return false;
		if (!Target.HasControl())
			return false;
		if (BehaviourComponent.IsInVisionSphere(Target.ActorLocation, 500.f))
			return true;
		if (BehaviourComponent.IsInVisionCone(Target.ActorLocation, 0.f))
			return true;
		return false;
	}

	void NotifyDanger(AHazeActor Target)
	{
		// We only decide about danger on target control side. 
		if ((Target == nullptr) || !Target.HasControl())
			return;

		// For best crumb trail match we use our crumb component on control side and targets crumb comp on remote side
		UHazeCrumbComponent DangerCrumbComp = HasControl() ? CrumbComp : UHazeCrumbComponent::Get(Target);
		if (ensure(DangerCrumbComp != nullptr))
		{
			FHazeDelegateCrumbParams CrumbParams;
			CrumbParams.AddObject(n"Target", Target);
			DangerCrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbNotifyDanger"), CrumbParams);	
		}
	}

	UFUNCTION()
	void CrumbNotifyDanger(const FHazeDelegateCrumbData& CrumbParams)
	{
		if (!IsActive())
			return;

		AHazePlayerCharacter Target = Cast<AHazePlayerCharacter>(CrumbParams.GetObject(n"Target"));
		FHazePointOfInterest POI;
		POI.FocusTarget.Actor = Owner;
		POI.Blend.BlendTime = 1.f;
		Target.ApplyPointOfInterest(POI, this);
		bOtherPlayerDanger = true;		
	}
}



