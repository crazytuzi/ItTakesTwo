import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Behaviours.FishBehaviourCapability;

class UFishBehaviourAttackChargeCapability : UFishBehaviourCapability
{
    default State = EFishState::Attack;

    FVector AttackDestination;
    FVector AttackDirection;
    float TrackTime = 0;
	bool bUsingMawCamera = false;
	bool bHitTarget = false;
	float CoolDownTime = 0.f;
	AHazePlayerCharacter CurrentPlayer; 

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Super::ShouldActivate() == EHazeNetworkActivation::DontActivate)
    		return EHazeNetworkActivation::DontActivate;
		if (Time::GetGameTimeSeconds() < CoolDownTime)
    		return EHazeNetworkActivation::DontActivate;
        return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
   		Super::OnActivated(ActivationParams);

        // Set destination
        UpdateAttackDestination();
        TrackTime = Time::GetGameTimeSeconds() + Settings.AttackRunTrackDuration;
		if (Settings.AttackRunTrackDuration == -1.f)
			TrackTime = BIG_NUMBER;

        // Make sure we handle hits
        BehaviourComponent.OnAttackRunHit.AddUFunction(this, n"OnAttackHit");

		AnimComp.SetGapingPercentage(100.f);
		AnimComp.SetAgitated(true);
		EffectsComp.SetEffectsMode(EFishEffectsMode::Attack);

		bUsingMawCamera = false;
		bHitTarget = false;
    }

    void UpdateAttackDestination()
    {
        AttackDestination = BehaviourComponent.GetAttackRunDestination(BehaviourComponent.GetTarget());
        AttackDirection = (AttackDestination - Owner.GetActorLocation()).GetSafeNormal();
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Super::OnDeactivated(DeactivationParams);

        BehaviourComponent.OnAttackRunHit.Unbind(this, n"OnAttackHit");
		AnimComp.SetGapingPercentage(0.f);
		if (!bHitTarget)
		{
			// Target may have been changed, so clear camera stuff for both players
			Game::GetCody().DeactivateCameraByInstigator(BehaviourComponent);
			Game::GetMay().DeactivateCameraByInstigator(BehaviourComponent);
			Game::GetCody().ClearPointOfInterestByInstigator(BehaviourComponent);	
			Game::GetMay().ClearPointOfInterestByInstigator(BehaviourComponent);	
		}
    }

    UFUNCTION()
    void OnAttackHit(AHazeActor Target)
    {
		if (!IsActive())
			return;

		if (!bHitTarget)
		{
			bHitTarget = true;
			AnimComp.Bite();	
		}

		// Don't attack again until a while after last successful attack
		CoolDownTime = Time::GetGameTimeSeconds() + 2.f;
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (Time::GetGameTimeSeconds() < TrackTime)
            UpdateAttackDestination();

        if (ShouldRecover())
        {
            BehaviourComponent.State = EFishState::Recover; 
            return;
        }

        if (BehaviourComponent.GetStateDuration() > 0.5f)
        {
            // Lunge!
			float Acc = bUsingMawCamera ? Settings.AttackMawCameraAcceleration : Settings.AttackRunAcceleration;
            BehaviourComponent.MoveTo(AttackDestination, Acc, Settings.AttackTurnDuration);

            // We can now do damage. Note that this will continue some short while after ending this behaviour.
            BehaviourComponent.PerformSustainedAttack(0.5f);
        }

		if (!bUsingMawCamera)
		{
			AHazePlayerCharacter TargetPlayer = Cast<AHazePlayerCharacter>(BehaviourComponent.Target);
			if ((EffectsComp.MawCamera != nullptr) && (TargetPlayer != nullptr))
			{
				FVector ToFood = (EffectsComp.MawCamera.WorldLocation - TargetPlayer.ActorLocation);
				if (ToFood.Size() < 5000.f)
				{
					float CosAngle = TargetPlayer.GetPlayerViewRotation().Vector().DotProduct(BehaviourComponent.MawForwardVector);
					if (CosAngle > 0.5f)
					{
						TargetPlayer.ActivateCamera(EffectsComp.MawCamera, FHazeCameraBlendSettings(3.f), BehaviourComponent);

						FHazePointOfInterest Target;
						Target.FocusTarget.Actor = TargetPlayer;
						TargetPlayer.ApplyPointOfInterest(Target, BehaviourComponent);
						bUsingMawCamera = true; 
					}
				}
			}
		}
    }

    bool ShouldRecover()
    {
		if (!HasControl())
			return false;

        // Have we lost target?
        if (!BehaviourComponent.CanHuntTarget(BehaviourComponent.GetTarget()))
            return true;

		if (bHitTarget)
			return true;

        // Keep on coming!    
        return false;
    }
}

