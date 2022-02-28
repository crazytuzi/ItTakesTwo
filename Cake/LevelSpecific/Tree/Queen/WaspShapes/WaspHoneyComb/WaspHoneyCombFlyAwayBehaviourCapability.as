import Cake.LevelSpecific.Tree.Swarm.Animation.SwarmAnimationSettingsDataAsset;
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
class UWaspHoneyCombFlyAwayBehaviourCapability : UHazeCapability
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
		if (bShouldDeactivate || IsActioning(n"StopFlyAway"))
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

		System::SetTimer(this, n"SwitchToDissolve", 0.5f, false);
		System::SetTimer(this, n"Deactivate", 1, false);

		Swarm.BlockCapabilities(n"SwarmCoreNotifyOverlappingPlayers", this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Owner.DisableActor(Owner);
		Swarm.UnblockCapabilities(n"SwarmCoreNotifyOverlappingPlayers", this);
		ConsumeAction(n"StopFlyAway");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		FVector FlyDirection = FVector::UpVector;
		FlyDirection *= -2000 * DeltaTime;

		Owner.SetActorLocation(Owner.ActorLocation + FlyDirection);
	}

	UFUNCTION()
	void Deactivate()
	{
		bShouldDeactivate = true;
	}

	UFUNCTION()
	void SwitchToDissolve()
	{
		ASwarmActor Swarmactor = Cast<ASwarmActor>(Owner);
		Swarm.SkelMeshComp.SetBlendSpacePlayRate(1.f);
		Swarm.SkelMeshComp.SetBlendSpaceValues(0, 0, false);
		Swarmactor.PlaySwarmAnimation(AnimData_Disperse, this, 0.f);
	}
}