import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;
import Cake.LevelSpecific.Tree.Wasps.Attacks.PlayerResponses.WaspGrappleDefenseCapability;

class UWaspBehaviourGrappleCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Grapple;

    AHazeActor Victim;
    float SuccessTime = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        Super::Setup(SetupParams);

        // Add response capability for all players when there are members of the team
        BehaviourComponent.Team.AddPlayersCapability(UWaspGrappleDefenseCapability::StaticClass());
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

        // Don't want any others to grapple for a while
        BehaviourComponent.ReportGrapple();

        // Play start anim
        FHazeAnimationDelegate OnAnimDone;
        OnAnimDone.BindUFunction(this, n"OnAnimGrappleStartDone");
        Owner.PlaySlotAnimation(OnBlendingOut = OnAnimDone, Animation = AnimComp.AnimFeature.Grapple_Enter.Wasp, BlendTime = 0.1);   

        // Set victim in defending state and attach
        Victim = BehaviourComponent.GetTarget();
        Victim.SetCapabilityAttributeObject(n"GrapplingWasp", Owner);	
        Owner.AttachToActor(Victim);

		Owner.SetCapabilityAttributeValue(n"WaspGrappleDefenseFailTime", 0.f);
        SuccessTime = 0.f;

        HealthComp.OnHitByMatch.AddUFunction(this, n"OnHitByProjectile");
        HealthComp.OnHitBySap.AddUFunction(this, n"OnHitByProjectile");
    }

    UFUNCTION()
    void OnAnimGrappleStartDone()
    {
        if (IsActive())
            Owner.PlaySlotAnimation(Animation = AnimComp.AnimFeature.Grapple_MH.Wasp, bLoop = true);   
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        Super::OnDeactivated(DeactivationParams);
        Owner.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);        
        HealthComp.OnHitByMatch.Unbind(this, n"OnHitByProjectile");
        HealthComp.OnHitBySap.Unbind(this, n"OnHitByProjectile");
    }

    void OnAbort()
    {
        Owner.PlaySlotAnimation(Animation = AnimComp.AnimFeature.Grapple_Aborted.Wasp, BlendTime = 0.1f);   
        BehaviourComponent.State = EWaspState::Recover; 

        // Allow victim to react to aborted attack
        if (Victim != nullptr)
           Victim.SetCapabilityAttributeObject(n"GrapplingWasp", nullptr);	
    }

    void OnSuccess()
    {
        SuccessTime = Time::GetGameTimeSeconds() + AnimComp.AnimFeature.Grapple_Kill.Wasp.SequenceLength * 0.6f;
        Owner.PlaySlotAnimation(Animation = AnimComp.AnimFeature.Grapple_Kill.Wasp, BlendTime = 0.1f);   
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if ((SuccessTime == 0.f) && 
            (GetAttributeValue(n"WaspGrappleDefenseFailTime") > 0.f))
        {
            // Defender has failed, stingytime!
            OnSuccess();
        }

        if (SuccessTime == 0.f)
        {
            // Still struggling
            if (Victim == nullptr)
            {
                // Lost target!
                OnAbort();
                return;
            }
        }
        else if (Time::GetGameTimeSeconds() > SuccessTime)
        {
            // We've succeeded, recover
            BehaviourComponent.State = EWaspState::Recover; 

            // Do damage
			auto PlayerVictim = Cast<AHazePlayerCharacter>(Victim);
			if (PlayerVictim != nullptr)
				PlayerVictim.DamagePlayerHealth(0.2f);
            return;
        }

        BehaviourComponent.ReportGrapple();
    }

    UFUNCTION()
    void OnHitByProjectile()
    {
        if (Time::GetGameTimeSince(BehaviourComponent.StateChangeTime) > 1.0f)
        {
            // We've taken a hit while grappling, abort!  
            OnAbort();
        }
    }

    bool ShouldRecover()
    {
        // Keep on coming!    
        return false;
    }
}

