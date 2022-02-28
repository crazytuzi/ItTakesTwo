class UMeshPhysicsReplicationComponent : USceneComponent
{
	UMeshComponent ReplicatedMeshComponent;

    FQuat SyncRotation;
	FVector SyncLocation;

	float VelocitySyncRate;
	float VelocitySyncTimer;

	float TransformSyncRate;
	float TransformSyncTimer;

	// Transform synchs are interpolated on remote
	float RemoteLerpAlpha;
	float RemoteLerpSpeed;

	bool bHasControl;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetComponentTickEnabled(false);
	}

	// Component needs to be attached to target mesh component before attempting to start replication
	void StartReplication(bool bIsControlSide, float VelocitySyncInterval = 0.1f, float TransformSyncInterval = 0.5f)
	{
		ReplicatedMeshComponent = Cast<UMeshComponent>(GetAttachParent());
		if(ReplicatedMeshComponent == nullptr)
		{
			Warning("UMeshPhysicsReplicationComponent needs to be attached to a mesh component!");
			DestroyComponent(this);
		}

		bHasControl = bIsControlSide;

		VelocitySyncRate = VelocitySyncInterval;
		TransformSyncRate = TransformSyncInterval;
		VelocitySyncTimer = TransformSyncTimer = 0.f;

		RemoteLerpAlpha = 1.f;
		RemoteLerpSpeed = TransformSyncInterval / VelocitySyncInterval;

		SetComponentTickEnabled(true);
	}

	// Not really "instant", but you know what I mean ;)
	void RequestInstantReplicationForFrame()
	{
		VelocitySyncTimer = VelocitySyncRate;
		TransformSyncTimer = TransformSyncRate;
	}

	void StopReplication()
	{
		SetComponentTickEnabled(false);
	}

	void ControlTick(float DeltaSeconds)
	{
		// Check for velocity synch
		VelocitySyncTimer += DeltaSeconds;
		if(VelocitySyncTimer >= VelocitySyncRate)
		{
			NetSyncVelocity(ReplicatedMeshComponent.GetPhysicsLinearVelocity(), ReplicatedMeshComponent.GetPhysicsAngularVelocityInDegrees());
			VelocitySyncTimer = 0.f;
		}

		// Check for transform synch
		TransformSyncTimer += DeltaSeconds;
		if(TransformSyncTimer >= TransformSyncRate)
		{
			NetSyncTransform(ReplicatedMeshComponent.GetWorldLocation(), ReplicatedMeshComponent.GetWorldRotation().Quaternion());
			TransformSyncTimer = 0.f;
		}
	}

	void RemoteTick(float DeltaSeconds)
	{
		RemoteLerpAlpha += DeltaSeconds * RemoteLerpSpeed;
		if(RemoteLerpAlpha > 1.f)
			return;

		ReplicatedMeshComponent.SetWorldLocation(FMath::Lerp(ReplicatedMeshComponent.GetWorldLocation(), SyncLocation, RemoteLerpAlpha));
		ReplicatedMeshComponent.SetWorldRotation(FQuat::FastLerp(ReplicatedMeshComponent.GetWorldRotation().Quaternion(), SyncRotation, RemoteLerpAlpha));
	}

 	UFUNCTION(NetFunction, Unreliable)
    void NetSyncVelocity(FVector NetVelocity, FVector NetAngularVelocity)
    {
		ReplicatedMeshComponent.SetPhysicsLinearVelocity(NetVelocity);
		ReplicatedMeshComponent.SetPhysicsAngularVelocityInDegrees(NetAngularVelocity);
    }

    UFUNCTION(NetFunction, Unreliable)
    void NetSyncTransform(FVector NetLocation, FQuat NetRotation)
    {
        SyncLocation = NetLocation;
        SyncRotation = NetRotation;
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(bHasControl)
			ControlTick(DeltaSeconds);
		else
			RemoteTick(DeltaSeconds);
	}
}