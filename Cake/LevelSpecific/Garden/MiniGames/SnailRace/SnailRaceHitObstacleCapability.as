import Cake.LevelSpecific.Garden.MiniGames.SnailRace.SnailRaceSnailActor;
import Cake.LevelSpecific.Garden.MiniGames.SnailRace.SnailRaceMushroomActor;
class USnailRaceHitObstacleCapability : UHazeCapability
{
	default CapabilityTags.Add(n"SnailRaceObstacle");
	default CapabilityDebugCategory = n"SnailRace";
	default CapabilityTags.Add(n"SnailRaceCapability");
	
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 80;

	ASnailRaceSnailActor Snail;
	
	FQuat SnailRotation;

	FHazeAcceleratedFloat Speed;
	FVector Velocity;
	float KnockBackTimer;
	FVector HitNormal;
	bool bShouldDeactivate;

	UPROPERTY()
	UNiagaraSystem HitEffect;

	UPROPERTY()
	UFoghornVOBankDataAssetBase MinigameDatabank;


	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Snail = Cast<ASnailRaceSnailActor>(Owner);
	}

	UFUNCTION()
	void UpdateScaleTimelike(float CurValue)
	{
		FVector Scalevector = FVector::OneVector;
		Scalevector.X = CurValue;

		Snail.Body.SetWorldScale3D(Scalevector);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (Cast<ASnailRaceSnailActor>(Snail.MoveComponent.ForwardHit.Actor) != nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(Snail.MoveComponent.ForwardHit.bBlockingHit)
		{
			return EHazeNetworkActivation::ActivateUsingCrumb;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bShouldDeactivate)
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		else if (IsActioning(n"StopMoving"))
		{
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if (Snail.HasControl())
		{
			Snail.NetSetBlockSnailValue(true);
		}
		Snail.SquishValue = 1;
		Snail.bIsStunned = true;
		Snail.BlockCapabilities(n"SnailRace", this);
		bShouldDeactivate = false;
		Speed.SnapTo(2000.f);
		Niagara::SpawnSystemAttached(HitEffect, Snail.RidingPlayer.Mesh, n"Head", Snail.RidingPlayer.Mesh.GetSocketLocation(n"Head") + FVector::UpVector * 20.f, FRotator::ZeroRotator, EAttachLocation::KeepWorldPosition, true, true);
		Snail.RidingPlayer.PlayerHazeAkComp.HazePostEvent(Snail.CollidedAudioEvent);
		HitNormal = Snail.MoveComponent.ForwardHit.Normal.ConstrainToPlane(Snail.MoveComponent.WorldUp).GetSafeNormal();
		if (Snail.RidingPlayer != nullptr)
			Snail.RidingPlayer.PlayForceFeedback(Snail.ImpactForceFeedback, false, true, n"SnailImpact");

		if (Snail.RidingPlayer.IsCody())
		{
			PlayFoghornVOBankEvent(MinigameDatabank, n"FoghornDBGameplayGlobalMinigameGenericFailCody", Snail.RidingPlayer);
		}
		else
		{
			PlayFoghornVOBankEvent(MinigameDatabank, n"FoghornDBGameplayGlobalMinigameGenericFailMay", Snail.RidingPlayer);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Snail.UnblockCapabilities(n"SnailRace", this);
				
		if (Snail.HasControl())
		{
			Snail.NetSetBlockSnailValue(false);
		}

		Snail.bIsStunned = false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		CheckCollision(DeltaTime);
		UpdateVelocity(DeltaTime);
	}

	void UpdateVelocity(float DeltaTime)
	{
		FHazeFrameMovement Movement = Snail.MoveComponent.MakeFrameMovement(n"MoveSnail");
		if(HasControl())
		{
			Speed.AccelerateTo(0, 1.2f, DeltaTime);
			Velocity = HitNormal * Speed.Value;
			Movement.ApplyDelta(Velocity * DeltaTime);

			Movement.ApplyGravityAcceleration(FVector::UpVector);
			Snail.MoveComponent.SetTargetFacingRotation(Snail.ActorRotation.Quaternion());
			Movement.ApplyTargetRotationDelta();
		}
		else
		{
			FHazeActorReplicationFinalized ConsumedParams;
			Snail.CrumbComponent.ConsumeCrumbTrailMovement(DeltaTime, ConsumedParams);
			Movement.ApplyConsumedCrumbData(ConsumedParams);
		}
		Snail.MoveComponent.Move(Movement);
		Snail.CrumbComponent.LeaveMovementCrumb();
	}

	void CheckCollision(float DeltaTime)
	{
		if (!Snail.HasControl())
			return;

		KnockBackTimer += DeltaTime;

		if(KnockBackTimer > 0.9f && Speed.Value < 10.f)
		{
			KnockBackTimer = 0;
			bShouldDeactivate = true;
		}
	}
}