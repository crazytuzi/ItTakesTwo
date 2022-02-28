import Cake.LevelSpecific.Tree.Swarm.Animation.SwarmAnimationSettingsDataAsset;
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Queen.WaspShapes.WaspGrindSplineBlocker.WasGrindBlockerComponent;

class UWaspGrindBlockerBehaviourCapability : UHazeCapability
{
	UPROPERTY()
	USwarmAnimationSettingsBaseDataAsset AnimData;

	UPROPERTY()
	USwarmAnimationSettingsBaseDataAsset AnimData_Spawn;

	UWaspGrindBlockerComponent BlockerComponent;
	ASwarmActor Swarm;

	bool bShouldDeactivate;
	
	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Swarm = Cast<ASwarmActor>(Owner);
		BlockerComponent = UWaspGrindBlockerComponent::Get(Owner);
		Swarm.BlockCapabilities(n"SwarmCoreNotifyOverlappingPlayers", this);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (BlockerComponent.bStartBlock)
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
		ASwarmActor Swarmactor = Cast<ASwarmActor>(Owner);
		Swarmactor.TeleportSwarm(BlockerComponent.StartPosition.ActorTransform);
		Swarmactor.PlaySwarmAnimation(AnimData_Spawn, this, 0.f);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bShouldDeactivate = false;

		ASwarmActor Swarmactor = Cast<ASwarmActor>(Owner);
		Swarmactor.PlaySwarmAnimation(AnimData, this, 3.f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		Owner.SetActorLocation(FMath::Lerp(Owner.ActorLocation, BlockerComponent.EndPosition.ActorLocation, DeltaTime * 2.f));

		if (Owner.ActorLocation.Distance(BlockerComponent.EndPosition.ActorLocation) < 15)
		{
			bShouldDeactivate = true;

			BlockerComponent.bStartBlock = false;
		}
	}
}