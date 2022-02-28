
import Vino.Movement.Helpers.MovementJumpHybridData;
import Cake.FlyingMachine.Melee.MeleeTags;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeData;

//import void CanActivate(AHazeActor) from "Examples.Example_Functions";
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightAttack;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightHitReaction;

class UFlyingMachineMeleeComponent : UHazeMelee2DComponent
{
	// Move Params
	const float ClosestMoveDistance = 220.f;
	const float GravityAmount = -6000.f;
	const float MaxFallSpeed = 3000.f;

	// Time Params
	const float TimeDilationAmountInImpact = 0.001f;
	const float TimeDilationCountDownDelay = 0.f;
	private float TimeDilationStartValue = 0.f;
	private float FreezeReleaseDelayLeft = 0.f;
	private float FreezeTimeStart = 0;
	private float FreezeTimeLeft = 0;

	FMeleePendingControlData PendingActivationData;

	bool bWaitingForFinish = false;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
   
    }

	UFUNCTION(BlueprintOverride)
    void OnRemovedFromFight()
    {
		ResetTimeDilation();
    }

	UFUNCTION()
	void ActivateFinishHimState()
	{
		bWaitingForFinish = true;
	}

	bool HasPendingAttack()const
	{
		if(PendingActivationData.Feature == nullptr)
			return false;

		return PendingActivationData.Feature.Tag == n"MeleeAttack";
	}

	bool HasPendingAttackShootNut()const
	{
		if(PendingActivationData.Feature == nullptr)
			return false;

		return PendingActivationData.Feature.Tag == n"MeleeAttackNut";
	}

	bool HasPendingAttackGrabPlayer()const
	{
		if(PendingActivationData.Feature == nullptr)
			return false;

		return PendingActivationData.Feature.Tag == n"MeleeAttackGrab";
	}

	bool HasPendingDodge()const
	{
		if(PendingActivationData.Feature == nullptr)
			return false;

		return PendingActivationData.Feature.Tag == n"Dodge";
	}

	void SetTimeDilationTime(float CountDownDelay, float Time, float StartAmount)
	{
		if(Time > 0)
		{
			FreezeReleaseDelayLeft = FMath::Max(CountDownDelay, 0.f);
			FreezeTimeLeft = Time;
			FreezeTimeStart = FreezeTimeLeft;
			TimeDilationStartValue = FMath::Max(StartAmount, 0.0001f);
			Owner.CustomTimeDilation = TimeDilationStartValue;
		}
	}

	void ResetTimeDilation()
	{
		FreezeTimeLeft = 0.f;
		FreezeReleaseDelayLeft = 0.f;
		Owner.CustomTimeDilation = 1.f;
		FreezeTimeStart = 0.f;
	}


	UFUNCTION(BlueprintOverride)
	void OnValidImpactToMe(UHazeMeleeImpactAsset ImpactAsset, FHazeMeleeTarget Instigator)
	{
		auto HazeOwner = Cast<AHazeActor>(GetOwner());
		HazeOwner.SetCapabilityAttributeObject(n"WasHit", ImpactAsset);		
	}

	UFUNCTION(BlueprintOverride)
	void OnValidImpactToTarget(UHazeMeleeImpactAsset ImpactAsset)
	{
		auto HazeOwner = Cast<AHazeActor>(GetOwner());
		HazeOwner.SetCapabilityAttributeObject(n"PerformedHit", ImpactAsset);	
	}
	

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaTime)
    {
		if(FreezeTimeStart > 0)
		{
			const float UndilatedDeltaTime = DeltaTime / Owner.CustomTimeDilation;
			const float DilationAlpha = 1 - (FreezeTimeLeft / FreezeTimeStart);
			Owner.CustomTimeDilation = FMath::EaseIn(TimeDilationStartValue, 1.f, DilationAlpha, 3.f);
			
			if(FreezeReleaseDelayLeft > 0)
			{
				FreezeReleaseDelayLeft -= UndilatedDeltaTime;
				if(FreezeReleaseDelayLeft <= 0)
				{
					FreezeTimeLeft = FMath::Max(FreezeTimeLeft - FMath::Abs(FreezeReleaseDelayLeft), 0.f);
				}
			}
			else
			{
				FreezeTimeLeft = FMath::Max(FreezeTimeLeft - UndilatedDeltaTime, 0.f);
			}

			if(FreezeTimeLeft <= 0)
			{
				ResetTimeDilation();
			}
		}
						
		if(FreezeTimeLeft > 0)
		{
			FreezeTimeLeft -= DeltaTime;
			if(FreezeTimeLeft <= 0)
			{
				FreezeTimeLeft = 0;
				Owner.CustomTimeDilation = 1.f;
			}
			else
			{
				const float DilationAlpha = 1 - (FreezeTimeLeft / FreezeTimeStart);
				Owner.CustomTimeDilation = FMath::Lerp(TimeDilationStartValue, 1.f, FMath::Pow(DilationAlpha, 2.f));
			}
		}
    }

	UFUNCTION(BlueprintOverride)
	void PrepareNextFrame()
	{
	
	}

	UFUNCTION(BlueprintOverride)
	bool CanActivateAsset(ULocomotionFeatureMeleeBase MeleeBaseAsset)const
	{
		auto AttackAsset = Cast<ULocomotionFeaturePlaneFightAttackBase>(MeleeBaseAsset);
		if(AttackAsset != nullptr)
			return CanActivateAttack(AttackAsset);

		auto HitReaction = Cast<ULocomotionFeaturePlaneFightHitReaction>(MeleeBaseAsset);
		if(HitReaction != nullptr)
			return CanActivateHitReaction(HitReaction);

		return true;
	}


	// The validation function of the asset
	bool CanActivateAttack(ULocomotionFeaturePlaneFightAttackBase MeleeAsset) const
	{
		// We cant activate the same feature again
		if(CurrentActiveFeature == MeleeAsset)
			return false;

		// Validate the target
		FHazeMeleeTarget CurrentTarget;
		const bool bHasTarget = GetCurrentTarget(CurrentTarget);
		if(bHasTarget)
		{
			if(MeleeAsset.TriggerMinRange >= 0 && CurrentTarget.Distance.X < MeleeAsset.TriggerMinRange)
				return false;
			
			float TotalMaxRange = MeleeAsset.TriggerMaxRange;
			if(MeleeAsset.TriggerMaxRangePlayerVelocityBonusAmount > 0)
				TotalMaxRange += CurrentTarget.MovingTowardsMeHorizontalSpeed > 10 ? MeleeAsset.TriggerMaxRangePlayerVelocityBonusAmount : 0;
			if(MeleeAsset.TriggerMaxRange >= 0 && CurrentTarget.Distance.X > TotalMaxRange)
				return false;
		}

		return true;
	}

	bool HasPendingKillingBlow() const
	{
		FHazeMeleeTarget AttackerTarget;
		UHazeMeleeImpactAsset PendingAsset = nullptr; 
		float AssetDamage = 0;
		GetPendingImpact(PendingAsset, AttackerTarget, AssetDamage);
		if(PendingAsset == nullptr)
			return false;

		if(AssetDamage < GetHealth())
			return false;

		return true;
	}


	// The validation function of the asset
	bool CanActivateHitReaction(ULocomotionFeaturePlaneFightHitReaction HitReactionAsset) const
	{
		FHazeMeleeTarget AttackerTarget;
		UHazeMeleeImpactAsset PendingAsset = nullptr; 
		float AssetDamage = 0;
		GetPendingImpact(PendingAsset, AttackerTarget, AssetDamage);
		if(PendingAsset == nullptr)
			return false;

		// Validation Type
		if(HitReactionAsset.ValidationType == EPlaneFightHitReactionValidationType::KillingBlow)
		{
			if(AssetDamage < GetHealth())
				return false;
		}

		// Characteristics
		if(!HitReactionAsset.Validation.CanActivate(this, AttackerTarget))
			return false;

		// Feature compare
		if(HitReactionAsset.AnyValidImpactFeature.Num() > 0)
		{
			bool bFound = false;
			for(UHazeMeleeImpactAsset RequiredImpact : HitReactionAsset.AnyValidImpactFeature)
			{	
				if(RequiredImpact == nullptr || PendingAsset != RequiredImpact)
					continue;

				bFound = true;
				break;
			}

			if(bFound == false)
				return false;
		}

		return true;
	}	
}