import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Rice.Positions.GetClosestPlayer;

class WaspHoneyCombBehaviourCapability : UHazeCapability
{
	ASwarmActor Swarm;
	bool bShouldDeactivate;
	float BlendSpaceY = 0;
	float TimeSinceActivated = 0;
	FVector LastFrameMoveDir;
	const float TimeUntilGrow = 0.1f;

	UPROPERTY()
	USwarmAnimationSettingsBaseDataAsset AnimData;

	UPROPERTY()
	USwarmAnimationSettingsBaseDataAsset AnimData_Spawn;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Swarm = Cast<ASwarmActor>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"SwarmActive"))
		{
			return EHazeNetworkActivation::ActivateLocal;
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
			return EHazeNetworkDeactivation::DeactivateLocal;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		FRotator DefaultRotation;
		Swarm.SetActorRotation(DefaultRotation);
		ConsumeAction(n"SwarmActive");
		bShouldDeactivate = false;
		Swarm.SkelMeshComp.SetBlendSpacePlayRate(1.f);
		Swarm.SkelMeshComp.SetBlendSpaceValues(0, 0, false);
		
		SwitchToHoneyCombSpawn();
		System::SetTimer(this , n"SwitchToHoneyComb", TimeUntilGrow, false);
		System::SetTimer(this , n"SetDisperse", 3, false);

		BlendSpaceY = 0;
		LastFrameMoveDir = Game::May.ActorLocation - Owner.ActorLocation;
		LastFrameMoveDir.Z = 0;
		LastFrameMoveDir.Normalize();

		TimeSinceActivated = 0;
	}

	UFUNCTION()
	void SwitchToHoneyCombSpawn()
	{
		ASwarmActor Swarmactor = Cast<ASwarmActor>(Owner);
		Swarmactor.PlaySwarmAnimation(AnimData_Spawn, this, 0.00f);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (TimeSinceActivated > TimeUntilGrow)
		{
			MoveUpdate(DeltaTime);
			GrowUpdate(DeltaTime);
		}
		
		TimeSinceActivated += DeltaTime;
	}

	UFUNCTION()
	void GrowUpdate(float DeltaTime)
	{
		if (TimeSinceActivated > TimeUntilGrow)
		{
			Swarm.SkelMeshComp.SetBlendSpacePlayRate(0.1f);
			Swarm.SkelMeshComp.SetBlendSpaceValues(0, BlendSpaceY, false);
			BlendSpaceY += DeltaTime * 0.055f;
			BlendSpaceY = FMath::Clamp(BlendSpaceY, 0.f, 1.f);
		}
	}

	UFUNCTION()
	void MoveUpdate(float DeltaTime)
	{
		FVector HitNormal;
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(Owner);
		const float TraceDistance = 500;
		const float MoveSpeed = 0;
		FVector UppOffset = FVector::UpVector * 10;

		Swarm.SkelMeshComp.SetBlendSpaceValues(0, -1.5f, false);

		FVector Movepos = Owner.ActorLocation + (LastFrameMoveDir.GetSafeNormal() * TraceDistance);

		for (auto player : Game::Players)
		{
			ActorsToIgnore.Add(player);
		}
		
		Owner.SetActorLocation(Owner.ActorLocation + LastFrameMoveDir * MoveSpeed * DeltaTime);
	}



	UFUNCTION()
	void SwitchToHoneyComb()
	{
		ASwarmActor Swarmactor = Cast<ASwarmActor>(Owner);
		Swarmactor.PlaySwarmAnimation(AnimData, this, 3.f);
	}

	UFUNCTION()
	void SetDisperse()
	{
		ConsumeAction(n"SwarmActive");
		Owner.SetCapabilityActionState(n"FlyAway", EHazeActionState::Active);
		bShouldDeactivate = true;
	}

	UFUNCTION()
	void Deactivate()
	{
		bShouldDeactivate = true;
	}
}