import Cake.LevelSpecific.Tree.Swarm.Animation.SwarmAnimationSettingsDataAsset;
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
class UWaspFlyAwayBehaviourCapability : UHazeCapability
{
	UPROPERTY()
	USwarmAnimationSettingsBaseDataAsset AnimData_Disperse;

	UPROPERTY()
	USwarmAnimationSettingsBaseDataAsset AnimData_ReadyToRespawn;

	ASwarmActor Swarm;
	bool bShouldDeactivate = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Swarm = Cast<ASwarmActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"FlyAway"))
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bShouldDeactivate)
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bShouldDeactivate = false;
		ConsumeAction(n"FlyAway");
		SwitchToDissolve();

		System::SetTimer(this, n"SwitchToReadyToSpawn", 2.8f, false);
		System::SetTimer(this, n"Deactivate", 4, false);

		Swarm.BlockCapabilities(n"SwarmCoreNotifyOverlappingPlayers", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.DisableActor(Owner);
		Swarm.UnblockCapabilities(n"SwarmCoreNotifyOverlappingPlayers", this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector FlyDirection = FVector::UpVector;
		FlyDirection *= 1200 * DeltaTime;

		Owner.SetActorLocation(Owner.ActorLocation + FlyDirection);
	}

	UFUNCTION()
	void Deactivate()
	{
		bShouldDeactivate = true;
	}

	void SwitchToDissolve()
	{
		ASwarmActor Swarmactor = Cast<ASwarmActor>(Owner);
		Swarmactor.PlaySwarmAnimation(AnimData_Disperse, this, 1.f);
	}

	void SwitchToReadyToSpawn()
	{
		ASwarmActor Swarmactor = Cast<ASwarmActor>(Owner);
		Swarmactor.PlaySwarmAnimation(AnimData_Disperse, this, 0.01f);
	}
}