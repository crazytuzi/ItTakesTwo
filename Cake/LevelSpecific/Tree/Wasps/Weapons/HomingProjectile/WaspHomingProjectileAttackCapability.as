import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;
import Cake.LevelSpecific.Tree.Wasps.Weapons.HomingProjectile.WaspHomingProjectile;

class UWaspHomingProjectileAttackCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Attack;

	UWaspHomingProjectileComponent HomingComp;
    FVector AttackDestination;
    FVector AttackDirection;
    float TrackTime = 0;

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
        Super::OnActivated(ActivationParams);

		HomingComp = UWaspHomingProjectileComponent::Get(Owner);
		Owner.DetachFromActor(EDetachmentRule::KeepWorld);

        // Set destination
        UpdateAttackDestination();
        TrackTime = Time::GetGameTimeSeconds() + Settings.AttackRunTrackDuration;

		// Trigger attack effects and sound
		//TODO
		UHazeAkComponent AudioComp  = UHazeAkComponent::Get(Owner);
		AudioComp.HazePostEvent(HomingComp.StartFlyingEvent);

        // Make sure we handle hits
        BehaviourComponent.OnAttackRunHit.AddUFunction(this, n"OnAttackHit");

		// Update quick attack sequence
		if (BehaviourComponent.QuickAttackSequenceCount == 0)
			BehaviourComponent.QuickAttackSequenceCount = FMath::Max(Settings.NumQuickAttacks - 1, 0);
		else
			BehaviourComponent.QuickAttackSequenceCount--;			

		Owner.SetActorEnableCollision(true);
		HomingComp.Launched();
    }

    void UpdateAttackDestination()
    {
		if (BehaviourComponent.GetTarget() == nullptr)
			return; // Can be null in network

        AttackDestination = BehaviourComponent.GetAttackRunDestination(BehaviourComponent.GetTarget());
        AttackDirection = (AttackDestination - Owner.GetActorLocation()).GetSafeNormal();
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        Super::OnDeactivated(DeactivationParams);
        BehaviourComponent.OnAttackRunHit.Unbind(this, n"OnAttackHit");
    }

    UFUNCTION()
    void OnAttackHit(AHazeActor Target)
    {
        if (IsActive() && HasControl())
        {
            // We've hit something, go straight to recovery
            BehaviourComponent.State = EWaspState::Recover; 
        }
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
		FVector ToTarget = (BehaviourComponent.Target.GetActorLocation() - Owner.GetActorLocation()).GetSafeNormal2D();
		float ToTargetDot = Owner.GetActorForwardVector().DotProduct(ToTarget);

        if (Time::GetGameTimeSeconds() < TrackTime && ToTargetDot > 0.707f)
		{
            UpdateAttackDestination();
		}
		else
		{
			AttackDestination += BehaviourComponent.TargetGroundVelocity.Value * DeltaTime;
		} 

        if (ShouldRecover())
        {
            BehaviourComponent.State = EWaspState::Recover; 
            return;
        }

        BehaviourComponent.MoveTo(AttackDestination, Settings.AttackRunAcceleration);

		// We can now do damage. Note that this will continue some short while after ending this behaviour.
		BehaviourComponent.PerformSustainedAttack(0.5f);
        BehaviourComponent.RotateTowards(AttackDestination + AttackDirection * 1000.f);
    }

    bool ShouldRecover()
    {
		if (!HasControl())
			return false;

        // Have we lost target?
        if (!BehaviourComponent.HasValidTarget())
            return true;

        // Has attack gone for too long?
        if (BehaviourComponent.GetStateDuration() > 10.f)
            return true;

        // Have we passed destination? 
        FVector ToDestination = (AttackDestination - Owner.GetActorLocation());
        if (ToDestination.DotProduct(AttackDirection) < 0.f)     
            return true;

        // Keep on coming!    
        return false;
    }
}

