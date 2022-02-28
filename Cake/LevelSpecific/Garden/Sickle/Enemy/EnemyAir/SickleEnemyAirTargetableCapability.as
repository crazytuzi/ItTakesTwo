
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyAir.SickleEnemyAirComponent;


class USickleEnemyAirTargetableCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::GamePlay;

  	ASickleEnemy AiOwner;
	USickleEnemyAirComponent AiComponent;
	USickleCuttableHealthComponent HealthComp;

	bool bWasLockedByVine = false;
	bool bHasSetTargetableGroundedState = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyAirComponent::Get(AiOwner);
		HealthComp = AiOwner.SickleCuttableComp;
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		MakeTargetableAir();		
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{

	}  

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bWasLockedByVine && AiOwner.bIsBeeingHitByVine)
		{
			// Vine attach
			bWasLockedByVine = true;
		}
		else if(bWasLockedByVine && !AiOwner.bIsBeeingHitByVine)
		{
			// Vine detach
			bWasLockedByVine = false;
			MakeTargetableAir();
		}

		// Make targetable when ground reached
		if(!bHasSetTargetableGroundedState && AiOwner.bIsBeeingHitByVine && AiComponent.IsGrounded())
		{
			MakeTargetableGround();
		}
	}

	void MakeTargetableGround()
	{
		bHasSetTargetableGroundedState = true;
		HealthComp.bInvulnerable = false;
		HealthComp.ChangeValidActivator(EHazeActivationPointActivatorType::May);
		HealthComp.InitializeDistance(EHazeActivationPointDistanceType::Selectable, AiComponent.GetOriginalSelectableDistance());
	}

	void MakeTargetableAir()
	{
		bHasSetTargetableGroundedState = false;
		if(AiComponent.bDodgePlayer)
		{
			MakeUntargetable();
		}
		else
		{
			HealthComp.bInvulnerable = false;
			HealthComp.ChangeValidActivator(EHazeActivationPointActivatorType::May);
			if(AiComponent.SelectableDistanceInAir >= 0)
				HealthComp.InitializeDistance(EHazeActivationPointDistanceType::Selectable, AiComponent.SelectableDistanceInAir);
		}
	}

	void MakeUntargetable()
	{
		bHasSetTargetableGroundedState = false;
		HealthComp.bInvulnerable = true;
		HealthComp.ChangeValidActivator(EHazeActivationPointActivatorType::None);
	}
}
