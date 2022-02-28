import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Vino.Checkpoints.Statics.LivesStatics;
import Cake.LevelSpecific.Garden.Sickle.Player.SickleComponent;
import Cake.LevelSpecific.Garden.Sickle.SickleTags;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyGround.SickleEnemyGroundComponent;


class USickleEnemyGroundWhippedCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");

	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	
	ASickleEnemy AiOwner;
	USickleEnemyGroundComponent AiComponent;
	USickleCuttableHealthComponent HealthComponent;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyGroundComponent::Get(AiOwner);
		HealthComponent = AiOwner.SickleCuttableComp;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(AiComponent.bHasShield)
			return EHazeNetworkActivation::DontActivate;

		if(!IsActioning(GardenSickle::TriggerVineWhip))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
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
		AiOwner.OnWhipDamageReceived(HealthComponent.MaxHealth * 0.5f, false);

		if(HealthComponent.Health > 0)
		{
			FSickleEnemyHit Impact = AiComponent.WhipHit;
			if(!AiComponent.IsGrounded())	
				Impact.KnockBackAmount = FVector::ZeroVector;

			FVector DirToCody = (Game::GetCody().GetActorLocation() - AiOwner.GetActorLocation()).ConstrainToPlane(FVector::UpVector).GetSafeNormal();
			if(DirToCody.IsNearlyZero())
				DirToCody = -Game::GetCody().GetActorForwardVector();

			AiComponent.ApplyHitWithRotation(Impact, DirToCody.Rotation());
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AiOwner.bIsBeeingHitByVine = false;
		AiOwner.bIsTakingWhipDamage = false;
	} 
}