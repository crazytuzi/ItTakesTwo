
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Vino.Movement.MovementSystemTags;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyAir.SickleEnemyAirComponent;


class USickleEnemyAirWhippedByVineCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

  	ASickleEnemy AiOwner;
	USickleEnemyAirComponent AiComponent;
	UVineImpactComponent VineImpactComponent;
	USickleCuttableHealthComponent HealthComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyAirComponent::Get(AiOwner);
		VineImpactComponent = UVineImpactComponent::Get(AiOwner);
		HealthComponent = AiOwner.SickleCuttableComp;
	}

    UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!IsActioning(GardenSickle::TriggerVineWhip))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		ConsumeAction(GardenSickle::TriggerVineWhip);
		
		AiOwner.bIsBeeingHitByVine = true;

		FHazeFrameMovement FinalMovement = AiComponent.MakeFrameMovement(n"SickleEnemyAirWhipDamageMovement");
		FinalMovement.OverrideStepDownHeight(0.f);
		const FVector DiffToTarget = (Game::GetCody().GetActorLocation() - AiOwner.GetActorLocation()).ConstrainToPlane(AiComponent.WorldUp);
		if(!DiffToTarget.IsNearlyZero())
		{
			AiComponent.SetTargetFacingDirection(DiffToTarget.GetSafeNormal());
		}

		AiComponent.Move(FinalMovement);

		AiOwner.OnWhipDamageReceived(HealthComponent.MaxHealth * 1.1f, false);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AiOwner.bIsBeeingHitByVine = false;
		AiOwner.bIsTakingWhipDamage = false;
	}  
}
