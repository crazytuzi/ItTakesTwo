import Rice.Positions.GetClosestPlayer;
import Cake.LevelSpecific.Tree.Swarm.Animation.SwarmAnimationSettingsDataAsset;
import Cake.LevelSpecific.Tree.Swarm.SwarmActor;
import Cake.LevelSpecific.Tree.Queen.WaspShapes.WaspScissor.WaspScissorComponent;
import Cake.LevelSpecific.Tree.Queen.WaspShapes.WaspScissor.AnimNotify_SwarmScissorCut;

class WaspScissorBehaviourCapability : UHazeCapability
{
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 100;

	float CurSpeed;
	float Time;

	UWaspScissorcomponent ScissorComponent;

	bool bFlyTowardsPlayer = true;
	const float CenterRadius = 3000;
	const float MaxSpeed = 850;
	const float ChaseSpeed = 1700;

	bool bShouldDeactivate;
	bool bTurbo;

	FHazeAnimNotifyDelegate OnScissorCut;

	UHazeSmoothSyncVectorComponent SyncPos;
	UHazeSmoothSyncRotationComponent SyncRot;
	ASwarmActor Swarm;

	AHazePlayerCharacter GetTarget() property
	{
		return ScissorComponent.Player;
	}

	UPROPERTY()
	USwarmAnimationSettingsBaseDataAsset AnimData;

	UPROPERTY()
	USwarmAnimationSettingsBaseDataAsset AnimData_Spawn;

	FVector EscapeVector;

	float GetDesiredSpeed() property
	{
		float DotToTarget = (Target.ActorLocation - Owner.ActorLocation).GetSafeNormal().DotProduct(Owner.ActorForwardVector * -1);
		float DistToTarget = Owner.ActorLocation.Distance(Target.ActorLocation);

		if (Time < 4)
		{
			if (bTurbo)
			{
				return MaxSpeed * 1.2f;
			}
			else
			{
				return MaxSpeed * 0.75f;
			}
		}

		if (bTurbo)
		{
			return MaxSpeed * 4;
		}

		else
		{
			return MaxSpeed;
		}
	}

	float GetRotateSpeed() property
	{
		if (bFlyTowardsPlayer && DistanceToCenter > CenterRadius - CenterRadius * 0.9f)
		{
			return 1.5f;
		}
		else
		{
			return 1.f;
		}
	}

	float GetDistanceToCenter() property
	{
		return ScissorComponent.CenterPosition.ActorLocation.Distance(Owner.ActorLocation);
	}

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Swarm = Cast<ASwarmActor>(Owner);
		SyncPos = UHazeSmoothSyncVectorComponent::Get(Owner);
		SyncRot = UHazeSmoothSyncRotationComponent::Get(Owner);
		ScissorComponent = UWaspScissorcomponent::Get(Owner);
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
		Time = 0;
		CurSpeed = 0;
		SetupForTackingPlayer();

		OnScissorCut.BindUFunction(this, n"ScissorCut");

		Swarm.BindAnimNotifyDelegate(
			UAnimNotify_SwarmScissorCut::StaticClass(),
			OnScissorCut
		);

		System::SetTimer(this, n"SwitchToScissorSpawn", 0.1f, false);
		System::SetTimer(this, n"SwitchToScissor", 0.5f, false);
	}

	UFUNCTION()
	void ScissorCut(AHazeActor Actor,
		UHazeSkeletalMeshComponentBase SkelMesh,
		UAnimNotify AnimNotify)
	{
		bTurbo = true;
		System::SetTimer(this, n"ResetTurbo", 0.15f, false);
	}

	UFUNCTION()
	void ResetTurbo()
	{
		bTurbo = false;
	}
	
	void SetupForTackingPlayer()
	{
		FVector FaceDirection = Owner.ActorLocation - Target.ActorLocation;
		Owner.SetActorHiddenInGame(false);
		Owner.SetActorRotation(Math::MakeRotFromX(FaceDirection));
	}

	UFUNCTION()
	void SwitchToScissorSpawn()
	{
		ASwarmActor Swarmactor = Cast<ASwarmActor>(Owner);
		Swarmactor.PlaySwarmAnimation(AnimData_Spawn, this);
	}

	UFUNCTION()
	void SwitchToScissor()
	{
		ASwarmActor Swarmactor = Cast<ASwarmActor>(Owner);
		Swarmactor.PlaySwarmAnimation(AnimData, this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (HasControl())
		{
			Time += DeltaTime;

			FVector DesiredDirection;

			if (bFlyTowardsPlayer)
			{
				DesiredDirection = Target.ActorLocation - Owner.ActorLocation;
				DesiredDirection = DesiredDirection.GetSafeNormal();
				DesiredDirection.Z = 0;
			}

			else
			{
				DesiredDirection = EscapeVector;
				DesiredDirection = DesiredDirection.GetSafeNormal();
				DesiredDirection.Z = 0;
			}

			FRotator Rotation = Owner.ActorRotation;
			FRotator DesiredRotation = Math::MakeRotFromX(DesiredDirection * -1);
			
			FQuat FinalRot = FQuat::Slerp(Rotation.Quaternion(), DesiredRotation.Quaternion(), DeltaTime * RotateSpeed);

			FVector AdjustedForward = FinalRot.ForwardVector;
			AdjustedForward.Z = 0;
			FVector DesiredLocation = Owner.ActorLocation + AdjustedForward * -1 * CurSpeed * DeltaTime;
			CurSpeed = FMath::Lerp(CurSpeed, DesiredSpeed, DeltaTime * 10);

			SyncPos.Value = DesiredLocation;
			SyncRot.Value = FinalRot.Rotator();

			if (bFlyTowardsPlayer)
			{
				FVector DirToPlayer = (Target.ActorLocation - Owner.ActorLocation).GetSafeNormal();
				float DotToPlayer = DirToPlayer.DotProduct(Owner.ActorForwardVector * -1);

				if (DotToPlayer < 0.5f && Target.ActorLocation.Distance(Owner.ActorLocation) < 1000)
				{
					bFlyTowardsPlayer = false;
				}
			}
			else
			{
				if (DistanceToCenter > CenterRadius)
				{
					bFlyTowardsPlayer = true;
					EscapeVector = Owner.ActorForwardVector;
				}
			}
		}
		
		Owner.SetActorLocation(SyncPos.Value);
		Owner.SetActorRotation(SyncRot.Value);

		if (GetActionStatus(n"SwarmActive") == EActionStateStatus::Inactive)
		{
			SetDisperse();
		}
	}

	void SetDisperse()
	{
		ConsumeAction(n"SwarmActive");
		Owner.SetCapabilityActionState(n"FlyAway", EHazeActionState::Active);
		bShouldDeactivate = true;
	}
}