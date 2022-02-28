import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourCapability;
import Cake.LevelSpecific.Tree.Beetle.Attacks.BeetlePlayerDamageEffect;
import Vino.PlayerHealth.PlayerHealthStatics;

class UBeetleBehaviourChargeCapability : UBeetleBehaviourCapability
{
	default State = EBeetleState::Attack;
	
	FRotator PrevRotation;
	float CauseDamageTime;
	bool bHitTarget;
	bool bHoming = true;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		BehaviourComp.UseAttackState(EBeetleState::Attack);
	
		AnimComp.PlayAnim(AnimFeature.ChargeStart, this, n"OnStartAnimDone");
		PrevRotation = Owner.ActorRotation;

		bHitTarget = false;
		bHoming = true;
		CauseDamageTime = Time::GetGameTimeSeconds() + 0.2f;

		BehaviourComp.OnStartAttack.Broadcast();
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// We become impervious to sap shortly after exiting state
		BehaviourComp.OnStopAttack.Broadcast();
	}

	UFUNCTION()
	void OnStartAnimDone()
	{
		if (IsActive())
			AnimComp.PlayBlendSpace(AnimFeature.Charge); 
    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if ((BehaviourComp.GetStateDuration() > Settings.ChargeDuration) || !BehaviourComp.HasValidTarget())
		{
			BehaviourComp.State = EBeetleState::Recover;
			return;
		}

		if (HasMissedTarget())
		{
			// Make a frustrated attack
			BehaviourComp.State = EBeetleState::Stomp;
			return;
		}

		// We can only hit once from charge state (since we want to enter gore state when we do).
		// Note that in networked play we can hit once on each side!
		if (!bHitTarget && (Time::GetGameTimeSeconds() > CauseDamageTime))
		{
			AHazePlayerCharacter TargetPlayer = Cast<AHazePlayerCharacter>(BehaviourComp.Target);
			if (TargetPlayer != nullptr)
			{
				// Should we hit primary target?
				if (BehaviourComp.CanHitTarget(TargetPlayer))
					HitTarget(TargetPlayer);	
				// Are we hitting other player by accident?
				if (BehaviourComp.CanHitTarget(TargetPlayer.OtherPlayer))
					HitTarget(TargetPlayer.OtherPlayer);
			}
		}

		if (bHoming && ShouldStopHoming())
			bHoming = false;

		if (bHoming)
			MoveDataComp.MoveTo(BehaviourComp.Target.ActorLocation, Settings.HomingChargeSpeed, Settings.ChargeTurnDuration);
		else
			MoveDataComp.MoveTo(Owner.ActorLocation + Owner.ActorForwardVector * 10000.f, Settings.StraightChargeSpeed, 100.f);

		// Until using ABP
		if (DeltaTime > 0.f)
		{
			FRotator DeltaRot = Math::NormalizedDeltaRotator(Owner.ActorRotation, PrevRotation);
			float YawVelocity = DeltaRot.Yaw / DeltaTime;
			Owner.SetBlendSpaceValues(FMath::Clamp(YawVelocity * 0.01f, -1.0f, 1.0f));
			PrevRotation = Owner.ActorRotation;
		}
	}

	bool ShouldStopHoming()
	{
		// Check time
		if (BehaviourComp.StateDuration < Settings.ChargeHomingMinDuration)
			return false;

		// Check distance
		FVector ToTarget = BehaviourComp.Target.ActorLocation - Owner.ActorLocation;
		if (ToTarget.SizeSquared2D() > FMath::Square(Settings.ChargeStopHomingRange))
			return false;

		// Can only stop homing when target is in our sights
		if (Owner.ActorForwardVector.DotProduct(ToTarget.GetSafeNormal2D()) < 0.86f)
			return false;
		return true;
	}

	bool HasMissedTarget()
	{
		// Never concede a miss while homing
		if (bHoming)
			return false;
		
		// Outside miss angle?
		FVector ToTarget = BehaviourComp.Target.ActorLocation - Owner.ActorLocation;//BehaviourComp.AttackHitDetectionCenter.WorldLocation;
		const float MissDot = FMath::Cos(FMath::DegreesToRadians(Settings.MissAngle));
		if (Owner.ActorForwardVector.DotProduct(ToTarget.GetSafeNormal2D()) > MissDot)
			return false;
		
		return true;
	}

	void HitTarget(AHazePlayerCharacter Target)
	{
		// Target can only be hit on it's own control side
		if (!Target.HasControl())
			return;
		bHitTarget = true;

		// To ensure best synced crumb trail we use our crumb component when hitting a target 
		// on our control side and the targets crumb component when hitting on on our remote side.
		UHazeCrumbComponent HitCrumbComp = CrumbComp;
		if (!HasControl())
			HitCrumbComp = UHazeCrumbComponent::Get(Target);			

		FHazeDelegateCrumbParams CrumbParams;
		CrumbParams.AddObject(n"Target", Target);
		CrumbParams.AddVector(n"Force", GetImpactForce(Target));
		HitCrumbComp.LeaveAndTriggerDelegateCrumb(FHazeCrumbDelegate(this, n"CrumbGore"), CrumbParams);
	}

	UFUNCTION()
	void CrumbGore(const FHazeDelegateCrumbData& CrumbData)
	{
		AHazePlayerCharacter GoreTarget = Cast<AHazePlayerCharacter>(CrumbData.GetObject(n"Target"));
		if (GoreTarget == nullptr)
			return;

		GoreTarget.SetCapabilityAttributeVector(n"KnockdownDirection", CrumbData.GetVector(n"Force"));
		GoreTarget.SetCapabilityActionState(n"KnockDown", EHazeActionState::Active);

        // Do damage
		DamagePlayerHealth(GoreTarget, 1.0f, TSubclassOf<UPlayerDamageEffect>(UBeetlePlayerDamageEffect::StaticClass()));

		// Change state and play anim if appropriate (when hitting something on control side or when we get this on control side after something was hit on remote)
		if ((BehaviourComp.State == EBeetleState::Attack) || (BehaviourComp.State == EBeetleState::Recover))
		{
			BehaviourComp.State = EBeetleState::Gore;
			
			if (!HasControl()) // On remote side we want to play gore animation immediately, not wait for gore crumb to come back
				AnimComp.PlayAnim(AnimFeature.Gore, BehaviourComp, n"OnGoreComplete");
		}

		BehaviourComp.OnHitTarget.Broadcast();
	}

	FVector GetImpactForce(AHazePlayerCharacter GoreTarget)
	{
		FVector Direction = (GoreTarget.ActorLocation - Owner.ActorLocation);
		Direction.Z = FMath::Max(500.f, Direction.Z);
		return Direction.GetSafeNormal() * Settings.AttackForce;
	}
}