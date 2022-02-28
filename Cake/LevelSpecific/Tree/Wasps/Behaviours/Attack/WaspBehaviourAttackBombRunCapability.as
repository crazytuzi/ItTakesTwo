import Cake.LevelSpecific.Tree.Wasps.Behaviours.WaspBehaviourCapability;
import Cake.LevelSpecific.Tree.Wasps.Weapons.WaspBombSlotComponent;
import Cake.LevelSpecific.Tree.Wasps.Attacks.PlayerResponses.WaspExplosionHitResponseCapability;
import Vino.Combustible.CombustibleComponent;
import Cake.LevelSpecific.Tree.Wasps.Teams.WaspBomberTeam;

class UWaspBehaviourAttackBombRunCapability : UWaspBehaviourCapability
{
    default State = EWaspState::Attack;

    FVector AttackDestination;
    FVector AttackDirection;
    float TrackTime = 0;
    float DropBombTime = 0.f;
    float DropBombInterval = 0.7f;

    AWaspBomb Bomb = nullptr;
    UWaspBombSlotComponent BombSlot;
    UWaspBomberTeam BomberTeam;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
        Super::Setup(SetupParams);

        // Add response capability for all players when there are members of the team
        BehaviourComponent.Team.AddPlayersCapability(UWaspExplosionHitResponseCapability::StaticClass());
        BomberTeam = Cast<UWaspBomberTeam>(Owner.GetJoinedTeam(n"WaspBomberTeam"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Super::OnActivated(ActivationParams);

        // Set destination
        UpdateAttackDestination();
        TrackTime = Time::GetGameTimeSeconds() + Settings.AttackRunTrackDuration;

        BombSlot = UWaspBombSlotComponent::Get(Owner);
        ensure(BombSlot != nullptr);
        DropBombTime = Time::GetGameTimeSeconds() + DropBombInterval;

        HealthComp.OnHitByMatch.AddUFunction(this, n"OnMatchImpact");
		AnimComp.PlayAnimation(EWaspAnim::Dash, 0.2f);
    }

    void UpdateAttackDestination()
    {
        // Fly past above target
        AttackDestination = BehaviourComponent.GetAttackRunDestination(BehaviourComponent.GetTarget());
        AttackDestination.Z += 500.f;
        
        AttackDirection = (AttackDestination - Owner.GetActorLocation());
        AttackDirection.Z = 0.f;
        AttackDirection = AttackDirection.GetSafeNormal();
        
        // Continue a ways beyond target
        AttackDestination += AttackDirection * Settings.EngageMinDistance;
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        Super::OnDeactivated(DeactivationParams);
		
		AnimComp.StopAnimation(EWaspAnim::Dash, 0.2f);
        if (Bomb != nullptr)
            Bomb.Unwield();

        HealthComp.OnHitByMatch.Unbind(this, n"OnMatchImpact");
    }

    UFUNCTION(BlueprintOverride)
    void TickActive(float DeltaTime)
    {
        if (HealthComp.IsSapped())
        {
            // Sapped!
            BehaviourComponent.State = EWaspState::Stunned; 
            return;
        }

        if (ShouldRecover())
        {
            BehaviourComponent.State = EWaspState::Recover; 
            return;
        }

        if (Time::GetGameTimeSeconds() < TrackTime)
            UpdateAttackDestination();

        // Head towards target!
        BehaviourComponent.MoveTo(AttackDestination, Settings.AttackRunAcceleration);
        BehaviourComponent.RotateTowards(AttackDestination + AttackDirection * 1000.f);

        WieldBomb();
        if (Bomb != nullptr)
        {
            if (Time::GetGameTimeSeconds() > DropBombTime)
            {
                // Down the hatch
                Bomb.Drop(UHazeBaseMovementComponent::Get(Owner).GetVelocity());
                Bomb = nullptr;
                DropBombTime = Time::GetGameTimeSeconds() + DropBombInterval;
            }         
        }
    }

    UFUNCTION()
    void OnMatchImpact()   
    {
        if (Bomb != nullptr)
        {
            // Oops! Hit by match while carrying a bomb.
            Bomb.Explode();
            HealthComp.Die();
        }
    }

    void WieldBomb()
    {
        if (Bomb != nullptr)
            return;

        Bomb = BomberTeam.GetAvailableBomb();
        if (Bomb != nullptr)
            Bomb.Wield(BombSlot);
    }

    bool ShouldRecover()
    {
        // Have we lost target?
        if (!BehaviourComponent.HasValidTarget())
            return true;

        // Has attack gone for too long?
        if (BehaviourComponent.GetStateDuration() > 5.f)
            return true;

        // Have we passed destination? 
        FVector ToDestination = (AttackDestination - Owner.GetActorLocation());
        if (ToDestination.DotProduct(AttackDirection) < 0.f)     
            return true;

        // Keep on coming!    
        return false;
    }
}

