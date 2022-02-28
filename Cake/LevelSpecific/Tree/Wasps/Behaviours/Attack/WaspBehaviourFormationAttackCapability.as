import Cake.LevelSpecific.Tree.Wasps.Scenepoints.WaspFormationScenepoint;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspLocalBehaviourCapability;

class UWaspBehaviourFormationAttackCapability : UWaspLocalBehaviourCapability
{
    default State = EWaspState::Attack;

    uint8 AttackIndex = 0;
	UWaspFormationScenepointComponent Scenepoint = nullptr;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);
		Scenepoint = Cast<UWaspFormationScenepointComponent>(BehaviourComponent.CurrentScenepoint);
		ensure(Scenepoint != nullptr);
		BehaviourComponent.UseScenepoint(Scenepoint);

        // Choose attack variant 
		AttackIndex = (AttackIndex + 1) % AnimComp.AnimFeature.Attacks.Num();
		AnimComp.PlayAnimation(EWaspAnim::Attacks, AttackIndex, 0.1f);

		// Flash for a while at start of attack
		EffectsComp.FlashTime = Time::GetGameTimeSeconds() + 0.9f;
		EffectsComp.ShowAttackEffect(Scenepoint.GetFormationDestination());
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);
		AnimComp.StopAnimation(EWaspAnim::Attacks);
		EffectsComp.HideAttackEffect();
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		FVector AttackDestination = (Scenepoint.WorldLocation + Scenepoint.GetFormationDestination()) * 0.5f;

        if (ShouldRecover(AttackDestination))
        {
            BehaviourComponent.State = EWaspState::Recover; 
            return;
        }

		FVector OwnLocAtTargetHeight = Owner.GetActorLocation();
		OwnLocAtTargetHeight.Z = AttackDestination.Z;  
        if (BehaviourComponent.GetStateDuration() < 0.3f)
        {
            // Initial backwards swing...
            BehaviourComponent.MoveTo(OwnLocAtTargetHeight - Scenepoint.GetFormationDirection() * 1000.f, 2000.f);
        }
        else if (BehaviourComponent.GetStateDuration() > 0.5f)
        {
            // ...then all out charge!
            BehaviourComponent.MoveTo(AttackDestination, Settings.AttackRunAcceleration);

            // We can now do damage. Note that this will continue some short while after ending this behaviour.
            BehaviourComponent.PerformSustainedAttack(1.0f);
        }
        BehaviourComponent.RotateTowards(AttackDestination + Scenepoint.GetFormationDirection() * 1000.f);

		// Lock movement to target height
		BehaviourComponent.LockMovementHeight(AttackDestination.Z, 2.f);
    }

    bool ShouldRecover(const FVector& AttackDestination)
    {
        // Has attack gone for too long?
        if (BehaviourComponent.GetStateDuration() > 5.f)
            return true;

        // Have we passed destination? 
        FVector ToDestination = (AttackDestination - Owner.GetActorLocation());
        if (ToDestination.DotProduct(Scenepoint.FormationDirection) < 0.f)     
            return true;

        // Keep on coming!    
        return false;
    }
}