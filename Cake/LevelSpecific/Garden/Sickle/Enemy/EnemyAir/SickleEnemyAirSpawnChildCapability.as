import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemy;
import Cake.LevelSpecific.Garden.Sickle.Enemy.EnemyAir.SickleEnemyAirComponent;
import Cake.LevelSpecific.Garden.Sickle.Enemy.SickleEnemySpawnManagerComponent;


class USickleEnemyAirSpawnChildCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SickleEnemyAlive");
	default TickGroup = ECapabilityTickGroups::Input;

	const float ResetTime = 10.f;

	ASickleEnemy AiOwner;
	USickleEnemyAirComponent AiComponent;
	USickleEnemySpawnManagerComponent SpawnManager;

	float TimeLeftToReset = 0;
	int ActivationCount = 0;
	float OriginalDelayBetweenSpawns = 0;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		AiOwner = Cast<ASickleEnemy>(Owner);
		AiComponent = USickleEnemyAirComponent::Get(AiOwner);
		SpawnManager = USickleEnemySpawnManagerComponent::Get(AiOwner);
		SpawnManager.DisableSpawning(this);
		SpawnManager.OnEnemySpawned.AddUFunction(this, n"OnChildSpawned");
		OriginalDelayBetweenSpawns = SpawnManager.DelayBetweenSpawns;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(AiOwner.bIsBeeingHitByVine)
			return EHazeNetworkActivation::DontActivate;

		if(AiComponent.CurrentFlyHeight < AiComponent.FlyHeight - 10.f)
			return EHazeNetworkActivation::DontActivate;;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(AiOwner.bIsBeeingHitByVine)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(AiComponent.CurrentFlyHeight < AiComponent.FlyHeight - 100.f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		SpawnManager.EnableSpawning(this);
		SpawnManager.ResetSpawnCount();
		TimeLeftToReset = ResetTime;
		if(ActivationCount == 0)
			SpawnManager.DelayBetweenSpawns = OriginalDelayBetweenSpawns;
		else
			SpawnManager.DelayBetweenSpawns = 1.f;
		ActivationCount++;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SpawnManager.DisableSpawning(this);
	}  

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(SpawnManager.TeamMemberCount == 0 
			&& SpawnManager.RespawnPoolRemaining == 0)
		{
			if(TimeLeftToReset > 0)
			{
				TimeLeftToReset -= DeltaTime;
			}
			else
			{
				SpawnManager.ResetSpawnCount();
				TimeLeftToReset = ResetTime;
				SpawnManager.DelayBetweenSpawns = OriginalDelayBetweenSpawns; 
			}
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void OnChildSpawned(ASickleEnemy Enemy)
	{
		AiOwner.Mesh.SetAnimBoolParam(n"GaveBirth", true);
	}
}