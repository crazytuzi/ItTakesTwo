import Cake.LevelSpecific.Clockwork.HorseDerby.HorseDerbyObstacleManagerComponent;

class UHorseDerbyObstacleMovementCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 50;

	UHorseDerbyObstacleManagerComponent ManagerComp;
	AHorseDerbyObstacleActor ObstacleActor;
	UHazeSplineFollowComponent SplineFollowComp;
	ADerbyHorseSplineTrack ActiveSplineTrack;

	EHazeUpdateSplineStatusType SplineStatus;
	float Speed;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		ObstacleActor = Cast<AHorseDerbyObstacleActor>(Owner);
		SplineFollowComp = ObstacleActor.SplineFollowComp;
		ManagerComp = Cast<UHorseDerbyObstacleManagerComponent>(GetAttributeObject(n"ObstacleManager"));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!ObstacleActor.IsActorDisabled())
			return EHazeNetworkActivation::ActivateFromControl;
		else
			return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(SplineStatus == EHazeUpdateSplineStatusType::AtEnd || ObstacleActor.IsActorDisabled())
			return EHazeNetworkDeactivation::DeactivateFromControl;
		else
			return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{

	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{	
		if(ObstacleActor != nullptr && ObstacleActor.SplineTrack != nullptr)
			ActiveSplineTrack = ObstacleActor.SplineTrack;
		
		if(ManagerComp != nullptr)
			Speed = ManagerComp.ObstacleSpeed;

		SplineFollowComp.ActivateSplineMovement(ActiveSplineTrack.SplineComp);

		float Dist = ActiveSplineTrack.GetSplineDistanceAtGamePosition(EDerbyHorseState::GameActive);
		FVector SpawnLocation = ActiveSplineTrack.SplineComp.GetLocationAtDistanceAlongSpline(Dist + ActiveSplineTrack.ObstacleSpawnDistance, ESplineCoordinateSpace::World);
		FHazeSplineSystemPosition SystemPosition;
		SplineFollowComp.UpdateSplineMovement(SpawnLocation, SystemPosition);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		SplineFollowComp.DeactivateSplineMovement();

		Speed = 0.f;

		if(!ObstacleActor.IsActorDisabled())
			ObstacleActor.DisableEvent.Broadcast(ObstacleActor);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!ObstacleActor.bReverseResetDirection)
			MoveTowardsEnd(DeltaTime);
		else
			MoveTowardsSpawn(DeltaTime);
	}

	void MoveTowardsEnd(float DeltaTime)
	{
		FHazeSplineSystemPosition SystemPosition;
		SplineStatus = SplineFollowComp.UpdateSplineMovement(-Speed * DeltaTime, SystemPosition);
		ObstacleActor.SetActorLocation(SystemPosition.WorldLocation + ObstacleActor.Offset);
	}

	void MoveTowardsSpawn(float DeltaTime)
	{
		FHazeSplineSystemPosition SystemPosition;
		SplineStatus = SplineFollowComp.UpdateSplineMovement(Speed * DeltaTime, SystemPosition);
		ObstacleActor.SetActorLocation(SystemPosition.WorldLocation + ObstacleActor.Offset);
	}
}