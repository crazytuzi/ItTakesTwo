import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourCapability;

class UBeetleBehaviourFaceTargetCapability : UBeetleBehaviourCapability
{
	default State = EBeetleState::Pursue;

	FHazeAcceleratedFloat TurnAlpha;
	bool bIsTurning = false;
	float StartYaw;

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		// Select target on control side, replicate to remote
		ActivationParams.AddObject(n"Target", BehaviourComp.GetBestTarget(HealthComp.LastAttacker));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

		// In networked play, we might get deactivated as stale when switching target (and thus control side). 
		// If that happens this capability will be reactivated so we should only switch target once we've 
		// successfully faced current target.
		BehaviourComp.bKeepTarget = true; 

		AHazeActor Target = Cast<AHazeActor>(ActivationParams.GetObject(n"Target"));	
		BehaviourComp.AggroTarget = Target;

		TurnAlpha.SnapTo(0.1f);

		// Since we may have to wait for other side to get control before any actual 
		// actor turning takes place (from crumbs) we might have to postpone turn anim.
		bIsTurning = false;
		StartYaw = Owner.ActorRotation.Yaw;
		if (Target.HasControl() == HasControl())
			StartTurn(Target);
		else
			AnimComp.PlayAnim(AnimFeature.Idle_Mh, bLoop = true);

		// Note that this may switch control side next update!
		BehaviourComp.SetTarget(Target);
		ensure(BehaviourComp.Target != nullptr);
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Network note: if we have switched control side, beetle will currently
		// not do anything here until other side starts sending crumbs.
		if (!bIsTurning && BehaviourComp.HasValidTarget())
		{
			if (BehaviourComp.Target.HasControl() == HasControl())
			{
				// We're control side aligned with target, should be receiving crumbs any second now...
				if (!FMath::IsNearlyZero(FRotator::NormalizeAxis(Owner.ActorRotation.Yaw - StartYaw), 5.f))
					StartTurn(BehaviourComp.Target);
			}
			else
			{
				// Waiting for control side alignment.
				StartYaw = Owner.ActorRotation.Yaw;
			}
		}

		// Attack target when proper time has passed and we're facing target
		if (BehaviourComp.GetStateDuration() > Settings.FaceTargetDuration)
		{
			// Can only stop homing when target is in our sights
			FVector ToTarget = BehaviourComp.Target.ActorLocation - Owner.ActorLocation;
			if (Owner.ActorForwardVector.DotProduct(ToTarget.GetSafeNormal2D()) > 0.86f)
			{
				BehaviourComp.State = EBeetleState::Telegraphing;

				// We can now switch to a different target next time we enter this state.
				BehaviourComp.bKeepTarget = false; 
				return;
			}
		}

		TurnAlpha.AccelerateTo(1.f, Settings.FaceTargetDuration, DeltaTime);
		FVector ToTarget = BehaviourComp.Target.ActorLocation - Owner.ActorLocation;
		FVector TurnDest = Owner.ActorLocation + Math::SlerpVectorTowards(ToTarget, Owner.ActorForwardVector, 1.f - TurnAlpha.Value);
		MoveDataComp.TurnInPlace(TurnDest, Settings.FaceTargetDuration * 1.2f);	
	}

	void StartTurn(AHazeActor Target)
	{
		bIsTurning = true;

		// Since we might change control side we don't want to start turning anim until we actually start turning
		// We can do the turn in place though as that only affects control side, while remote side will use crumbs.
		AnimComp.PlayBlendSpace(AnimFeature.TurnFast, 0.1f, 1.5f);
		FVector ToTarget = (Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
		float TurnValue = (Owner.ActorRightVector.DotProduct(ToTarget) > 0.f) ? 1.f : -1.f;
		TurnValue *= FMath::GetMappedRangeValueClamped(FVector2D(-0.7f, 1.f), FVector2D(1.f, 0.1f), ToTarget.DotProduct(Owner.ActorForwardVector));
		Owner.SetBlendSpaceValues(TurnValue, 0.f, true);
	}
}
