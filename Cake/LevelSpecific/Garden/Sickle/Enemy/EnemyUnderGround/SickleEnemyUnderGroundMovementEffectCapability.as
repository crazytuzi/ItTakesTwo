import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Vino.Movement.Components.MovementComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleCuttableComponent;
import Cake.LevelSpecific.Garden.Vine.VineImpactComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyUnderGround.SickleEnemyUnderGroundComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemyComponent;


class USickleEnemyUnderGroundMovementEffectCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default CapabilityTags.Add(n"SickleEnemyUnderGround");
	default CapabilityTags.Add(CapabilityTags::Movement);

	default TickGroup = ECapabilityTickGroups::GamePlay;

	ASickleEnemy AiOwner;
	USickleEnemyUnderGroundComponent AiComponent;
	UNiagaraComponent MovingEffect;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyUnderGroundComponent::Get(AiOwner);
		if(AiComponent.MoveUndergroundLoopEffect != nullptr)
		{
			MovingEffect = Niagara::SpawnSystemAttached(AiComponent.MoveUndergroundLoopEffect, AiOwner.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, false);
			MovingEffect.SetHiddenInGame(true);
		}			
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if(MovingEffect != nullptr)
		{
			MovingEffect.DestroyComponent(AiOwner);
			MovingEffect = nullptr;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(MovingEffect == nullptr)
			return EHazeNetworkActivation::DontActivate;

		FVector CurrentVelocity =  AiComponent.GetVelocity();
		CurrentVelocity = CurrentVelocity.ConstrainToPlane(FVector::UpVector);
		if(CurrentVelocity.SizeSquared() < 1)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(AiComponent.PassiveGroundDamageLocations.Num() > 0)
			return EHazeNetworkDeactivation::DontDeactivate;
			
		FVector CurrentVelocity =  AiComponent.GetVelocity();
		CurrentVelocity = CurrentVelocity.ConstrainToPlane(FVector::UpVector);
		if(CurrentVelocity.SizeSquared() > 1)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		MovingEffect.SetHiddenInGame(false);
		if(AiComponent.StartMoveUndergroundEffect != nullptr)
			Niagara::SpawnSystemAtLocation(AiComponent.StartMoveUndergroundEffect, AiOwner.GetActorLocation());
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		MovingEffect.SetHiddenInGame(true);
		if(AiComponent.StopMoveUndergroundEffect != nullptr)
			Niagara::SpawnSystemAtLocation(AiComponent.StopMoveUndergroundEffect, AiOwner.GetActorLocation());
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		
	}

	UFUNCTION(BlueprintOverride)
	FString GetDebugString()
	{
		FString Debug = "";
		return Debug;
	}
}