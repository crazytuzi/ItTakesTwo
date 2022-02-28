
import Cake.FlyingMachine.Melee.Capability.FlyingMachineMeleeCapabilityBase;
import Peanuts.DamageFlash.DamageFlashStatics;
import Cake.FlyingMachine.Melee.Component.FlyingMachineMeleeData;
import Cake.FlyingMachine.Melee.LocomotionFeatures.LocomotionFeaturePlaneFightHitReaction;
import Cake.FlyingMachine.Melee.FlyingMachineMeleeComponent;


UCLASS(Abstract)
class UFlyingMachineMeleeHitReactionCapability : UFlyingMachineMeleeCapabilityBase
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(MeleeTags::Melee);
	default CapabilityTags.Add(MeleeTags::MeleeHitReaction);
	default CapabilityTags.Add(MeleeTags::MeleeTakeDamage);

	default CapabilityDebugCategory = MeleeTags::Melee;

	ULocomotionFeaturePlaneFightHitReaction ActiveFeature;
	FMovementCharacterJumpHybridData VerticalTranslation;
	UFlyingMachineMeleeComponent FightMeleeComponent;
	bool bActivatedInAir = false;
	bool bIsStillInAir = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		FightMeleeComponent = Cast<UFlyingMachineMeleeComponent>(MeleeComponent);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasPendingImpact())
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!IsStateActive(EHazeMeleeStateType::HitReaction))
			return EHazeNetworkDeactivation::DeactivateLocal;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{		
		SetMutuallyExclusive(MeleeTags::MeleeHitReaction, true);
		SetMutuallyExclusive(MeleeTags::MeleeHitReaction, false);

		FHazeMeleeTarget CurrentTarget;
	 	if(MeleeComponent.GetCurrentTarget(CurrentTarget))
		{
			// Snap the impact to the correct direction
			if(CurrentTarget.bIsToTheRightOfMe)
				FaceRight();
			else
				FaceLeft();
		}

		// By default, the feature will be activated by the controlside
		// We can override it by sending in a feature here
		// But the feature can't be send i network since it is not garanteed to have the crumbs
		// In the same order as the heroes crumb component
		ActiveFeature = Cast<ULocomotionFeaturePlaneFightHitReaction>(ActivateState(EHazeMeleeStateType::HitReaction));
		if(ActiveFeature.VictimVerticalUpForce > 0)
			VerticalTranslation.StartJump(ActiveFeature.VictimVerticalUpForce);

		bActivatedInAir = !MeleeComponent.IsGrounded();
		bIsStillInAir = bActivatedInAir;
		if(bActivatedInAir)
		{
			// In air should loop the current animation until we hit the ground
			SetCurrentAnimationLoopType(EHazeMeleeAnimationLoopType::StayAtCurrentAnimation);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ActiveFeature = nullptr;
		DeactivateState(EHazeMeleeStateType::HitReaction);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FHazeMelee2DSpineData Spline;
		MeleeComponent.GetSplineData(Spline);

		FVector UpMoveAmount = VerticalTranslation.CalculateJumpVelocity(
		DeltaTime, 
		true, 
		FightMeleeComponent.MaxFallSpeed, 
		FightMeleeComponent.GravityAmount, 
		Spline.WorldUp);

		FVector2D MoveAmount;
		MoveAmount.Y = UpMoveAmount.DotProduct(Spline.WorldUp);

		MoveAmount *= DeltaTime;
		MeleeComponent.AddDeltaMovement(n"Jump", MoveAmount.X, MoveAmount.Y);

		if(bIsStillInAir && MoveAmount.Y < 0)
		{	
			if(MeleeComponent.IsGrounded())
			{
				// We have landed so continue in the animation chain
				bIsStillInAir = false;
				AdvanceAnimation(EHazeMeleeAnimationAdvanceType::Immediately, EHazeMeleeAnimationLoopType::DeactivateAtEnd);
			}
		}
	}

}
