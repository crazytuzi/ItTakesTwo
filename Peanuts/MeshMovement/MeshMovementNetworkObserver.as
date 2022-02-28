import Peanuts.MeshMovement.MeshMovementLocalObserver;

class UMeshMovementNetworkObserver : UMeshMovementObserver
{
	UPROPERTY()
    float SyncDelayMs = 20;
    float TransformSyncDelayMultiplier;
    
    FVector SyncLocation;
    FQuat SyncRotation;

    FVector SyncLinearVelocity;
    FVector SyncAngularVelocityInDegrees;

    // Used by control side to trigger a sync
    float VelocitySyncTimer = 0.f;
    float TransformSyncTimer = 0.f;

    // Used by remote side to lerp 
    float RemoteLerpIndex;
    float RemoteLerpSpeed = 15;

	bool bHasControl;

	// Used to disable component by checking for zero-velocities spanning ComponentDisableThreshold seconds
	bool bDisableCheckEnabled;

    void Start(bool bIsControlSide)
    {
        RemoteLerpIndex = BIG_NUMBER;

        bHasControl = bIsControlSide;
        TransformSyncDelayMultiplier = SyncDelayMs / 2;

        VelocitySyncTimer = SyncDelayMs;
        TransformSyncTimer = TransformSyncDelayMultiplier;

		bDisableCheckEnabled = false;

		UMeshMovementObserver::Start(bIsControlSide);
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds)
    {
        if(bHasControl)
		{
			ControlDisableCheckTick(DeltaSeconds);
            ControlTick(DeltaSeconds);
		}
        else
		{
            RemoteTick(DeltaSeconds);
		}
    }

    void ControlTick(float DeltaSeconds)
    {
        // Handle velocity sync
        VelocitySyncTimer += DeltaSeconds * 1000;
        if(VelocitySyncTimer < SyncDelayMs)
            return;
        
        VelocitySyncTimer = 0.f;
        TransformSyncTimer++;
        NetSyncVelocity(MeshComponent.GetPhysicsLinearVelocity(), MeshComponent.GetPhysicsAngularVelocityInDegrees());

        // Handle transform sync
        if(TransformSyncTimer < TransformSyncDelayMultiplier)
            return;

        TransformSyncTimer = 0.f;
        NetSyncTransform(HazeActor.GetActorLocation(), HazeActor.GetActorRotation().Quaternion());
    }

    void RemoteTick(float DeltaSeconds)
    {
        RemoteLerpIndex += DeltaSeconds * RemoteLerpSpeed;

        if(RemoteLerpIndex > 1.f)
            return;

        HazeActor.SetActorLocation(FMath::Lerp(MeshComponent.GetWorldLocation(), SyncLocation, RemoteLerpIndex));
        HazeActor.SetActorRotation(FQuat::FastLerp(MeshComponent.GetWorldRotation().Quaternion(), SyncRotation, RemoteLerpIndex));

		if(!bDisableCheckEnabled && SyncLinearVelocity.IsNearlyZero() && SyncAngularVelocityInDegrees.IsNearlyZero())
			NetStartDisableCheck();
    }

    void RemoteOnVelocitySync()
    {
        // Immediately set velocity on remote
        MeshComponent.SetPhysicsLinearVelocity(SyncLinearVelocity);
        MeshComponent.SetPhysicsAngularVelocityInDegrees(SyncAngularVelocityInDegrees);
    }

    void RemoteTransformSync()
    {
        // Start transform-lerping
        RemoteLerpIndex = 0.f;
    }

	void ControlDisableCheckTick(float DeltaSeconds)
	{
		if(!bDisableCheckEnabled)
			return;

		if(!SyncLinearVelocity.IsNearlyZero() || !SyncAngularVelocityInDegrees.IsNearlyZero())
			return;
		
		NetSyncTransform(HazeActor.GetActorLocation(), HazeActor.GetActorRotation().Quaternion());
		NetDisableComponent();
	}

	UFUNCTION(NetFunction)
	void NetStartDisableCheck()
	{
		bDisableCheckEnabled = true;
	}

    UFUNCTION(NetFunction, Unreliable)
    void NetSyncVelocity(FVector NetVelocity, FVector NetAngularVelocity)
    {
        SyncLinearVelocity = NetVelocity;
        SyncAngularVelocityInDegrees = NetAngularVelocity;
        
        if(!bHasControl)
            RemoteOnVelocitySync();
    }

    UFUNCTION(NetFunction, Unreliable)
    void NetSyncTransform(FVector NetLocation, FQuat NetRotation)
    {
        SyncLocation = NetLocation;
        SyncRotation = NetRotation;

        if(!bHasControl)
            RemoteTransformSync();
    }

    UFUNCTION(NetFunction)
    void NetDisableComponent()
    {
        MeshStoppedMoving();
    }
}
