import Cake.LevelSpecific.Garden.WallWalkingAnimal.WallWalkingAnimal;
import Vino.PlayerHealth.PlayerHealthStatics;


class UWallWalkingAnimalStandingOnPurpleGuckCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::GamePlay;

	//Spawned at the same time as deatheffect if set.
	UPROPERTY(Category = "Setup")
	UNiagaraSystem StandingTooLongEffect;

	//Spawns attached at start of Activation if set.
	UPROPERTY(Category = "Setup")
	UNiagaraSystem SapDegradingEffect;

	UPROPERTY()
	TSubclassOf<UPlayerDeathEffect> DeathEffect;

	AWallWalkingAnimal TargetAnimal;
	bool bHasTriggerdDeath = false;
	float MoveSpeedMultiplier = 1.f;

	UNiagaraComponent SpawnedSystem;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		TargetAnimal = Cast<AWallWalkingAnimal>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(TargetAnimal.bFallingOffWall)
			return EHazeNetworkActivation::DontActivate;

		if(TargetAnimal.StandingOnPrupleGuckTime <= 0)
			return EHazeNetworkActivation::DontActivate;
        
        return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(TargetAnimal.bFallingOffWall)
			return EHazeNetworkDeactivation::DeactivateLocal;

		if(TargetAnimal.StandingOnPrupleGuckTime <= 0)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}


	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetAnimal.SetCapabilityAttributeValue(n"AudioSpiderIsInPurpleSap", 1.f);
		MoveSpeedMultiplier = 1.f;

		if(SapDegradingEffect != nullptr)
			SpawnedSystem = Niagara::SpawnSystemAttached(SapDegradingEffect, TargetAnimal.RootComponent, NAME_None, FVector::ZeroVector, FRotator::ZeroRotator, EAttachLocation::SnapToTarget, true);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TargetAnimal.SetCapabilityAttributeValue(n"AudioSpiderIsInPurpleSap", 0.f);
		TargetAnimal.SetMovementSpeedMultiplierLocal(1.f);
		bHasTriggerdDeath = false;

		if(SpawnedSystem != nullptr)
			SpawnedSystem.Deactivate();
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!bHasTriggerdDeath)
		{
			if(TargetAnimal.StandingOnPrupleGuckTime > TargetAnimal.MaxStandOnGuckTime)
			{
				bHasTriggerdDeath = true;
				
				if(StandingTooLongEffect != nullptr)
					Niagara::SpawnSystemAtLocation(StandingTooLongEffect, TargetAnimal.GetActorLocation());
				
				KillPlayer(TargetAnimal.Player, DeathEffect);
			}
			else
			{
				const float Alpha = 1.f - (TargetAnimal.StandingOnPrupleGuckTime / TargetAnimal.MaxStandOnGuckTime);
				TargetAnimal.SetMovementSpeedMultiplierLocal(Alpha);
			}
		}
	}
}