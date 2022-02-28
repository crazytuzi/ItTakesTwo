import Cake.LevelSpecific.Tree.Beetle.Behaviours.BeetleBehaviourCapability;
import Cake.LevelSpecific.Tree.Beetle.Attacks.BeetleShockwaveComponent;
import Vino.Movement.Components.MovementComponent;

class UBeetleBehaviourPounceCapability : UBeetleBehaviourCapability
{
	default State = EBeetleState::Pounce;
	
	UBeetleShockwaveComponent ShockwaveComp;
	UHazeMovementComponent MoveComp;
	FVector Destination;
	bool bInAir = false;
	float LaunchTime = 0.f;
	float PounceSpeed = 1000.f;
	float LandingHeight = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Super::Setup(SetupParams);
		ShockwaveComp = UBeetleShockwaveComponent::Get(Owner);
		MoveComp = UHazeMovementComponent::Get(Owner);
		HealthComp.OnTakeDamage.AddUFunction(this, n"OnTakeDamage");
		CheckActivation();
	}

	UFUNCTION()
	void OnTakeDamage(float RemainingHealth, AHazePlayerCharacter Attacker, float BatchDamage, const FVector& DamageDir)
	{
		CheckActivation();		
	}

	void CheckActivation()
	{
		if (HealthComp.GetHealthFraction() < Settings.PounceStartHealthFraction + KINDA_SMALL_NUMBER)
		{
			// Time to start using this special attack. Very first special attack can be taken immediately.
			int NumCharges = (BehaviourComp.bHasPerformedSpecialAttack) ? 0 : Settings.PounceInterval; 
			BehaviourComp.QueueSpecialAttack(EBeetleState::Pounce, NumCharges, Settings.PounceMinRange, BIG_NUMBER);
			HealthComp.OnTakeDamage.Unbind(this, n"OnTakeDamage");
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		BehaviourComp.UseAttackState(EBeetleState::Pounce);
		bInAir = false;
		BehaviourComp.ResetFullBodyImpact();

		AnimComp.OnShockwaveNotify.AddUFunction(this, n"TriggerShockwave");
		AnimComp.OnLaunchNotify.AddUFunction(this, n"Launch");
		AnimComp.PlayStartMH(AnimFeature.Pounce_Start, AnimFeature.Pounce_Mh, 0.1f);
		LandingHeight = Owner.ActorLocation.Z + 400.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);

		AnimComp.OnShockwaveNotify.Unbind(this, n"TriggerShockwave");
		AnimComp.OnLaunchNotify.Unbind(this, n"Launch");

		if (!BehaviourComp.IsValidTarget(HealthComp.LastAttacker))
			HealthComp.LastAttacker = nullptr;
		HealthComp.SetUnsappable();

		// Set up next attack
		BehaviourComp.QueueSpecialAttack(EBeetleState::Pounce, Settings.PounceInterval, Settings.PounceMinRange, BIG_NUMBER);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (!bInAir)
			return;

		// Check if we land on or otherwise hit a target
		BehaviourComp.CheckFullbodyImpact();

		if (HasLanded())
		{
			bInAir = false; 
			AnimComp.PlayAnim(AnimFeature.Pounce_Land, this, n"LandAnimDone", false, 0.05f);
			// Cut end of animation to increase pacing.
			// TODO: Remove when timing is set and animation fixed.
			System::SetTimer(this, n"LandAnimDone", 1.f, false); 
			return;
		}

		// Keep leaping 'til we land
		MoveDataComp.LeapTo(Destination, PounceSpeed);
	}

	bool HasLanded()
	{
		// Must have launched a while ago
		if (Time::GetGameTimeSince(LaunchTime) < 1.f)
			return false;

		// Near ground?
		if ((Owner.ActorLocation.Z < LandingHeight) && (Owner.ActualVelocity.Z < 0.f))
			return true;

		// Always count as landed if back on ground
		return MoveComp.IsGrounded();
	}

	UFUNCTION()
	void TriggerShockwave()
	{
		ShockwaveComp.TriggerShockwave();
	}

	UFUNCTION()
	void LandAnimDone()
	{
		if (IsActive())
		{
			if (Settings.bAdditionalAttackRecoveryWhenPlayerKilled && IAnyPlayerDead())
				BehaviourComp.State = EBeetleState::Recover;
			else
				BehaviourComp.State = EBeetleState::Pursue;
		}
	}

	UFUNCTION()
	void Launch()
	{
		if (!IsActive())
			return;

		bInAir = true;
		LaunchTime = Time::GetGameTimeSeconds();
		HealthComp.SetSappable();

		Destination = BehaviourComp.Target.ActorLocation;
		Destination.Z = Owner.ActorLocation.Z;
		FVector ToDest = (Destination - Owner.ActorLocation);
		float DistToDest = ToDest.Size();
		float DistanceReduction = FMath::GetMappedRangeValueClamped(FVector2D(Settings.PounceMinRange,6000.f), FVector2D(0.f, 1500.f), DistToDest);
		Destination -= ToDest.GetSafeNormal() * DistanceReduction;
		
		PounceSpeed = FMath::GetMappedRangeValueClamped(FVector2D(Settings.PounceMinRange,5000.f), FVector2D(0.2f, 1.f) * Settings.PounceSpeed, DistToDest);
	}
}