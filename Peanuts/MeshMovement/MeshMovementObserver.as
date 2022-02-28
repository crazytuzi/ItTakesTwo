event void FMeshMovementAction(UMeshComponent Mesh);

class UMeshMovementObserver : UActorComponent
{
	AHazeActor HazeActor;
	UMeshComponent MeshComponent;	
	
	UPROPERTY()
	FMeshMovementAction OnMeshStoppedMoving;

	UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        HazeActor = Cast<AHazeActor>(Owner);

        MeshComponent = UMeshComponent::Get(Owner);
        if(MeshComponent == nullptr)
            Warning("HazeNetworkMeshSyncComponent - There is no mesh on actor " + HazeActor.Name);

        SetComponentTickEnabled(false);
    }

	void Start(bool bIsControlSide)
	{
		SetComponentTickEnabled(true);
	}

	protected void MeshStoppedMoving()
	{
		Stop();
		OnMeshStoppedMoving.Broadcast(MeshComponent);
	}

	void Stop()
	{
		SetComponentTickEnabled(false);
	}
}