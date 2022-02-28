import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.PlayRoom.Circus.Marble.MarbleCheckpointTube;
import Peanuts.Audio.AudioStatics;

class AMarbleBall : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComponent;

	UPROPERTY()
	UPhysicalMaterial CurrentPhysicalMaterial;

	UPROPERTY()
	float CurrentVelocity;

	float LastFrameVelocity;

	UPROPERTY()
	float DeltaVelocity;

	UPROPERTY()
	FHitResult CurrentHitResult;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StartEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent StopEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ImpactEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent TeleportEvent;

	UPROPERTY()
	bool bCanSetVeloRtpc = true;

	UPROPERTY()
	bool bCanPlayHitEvent = true;

	UPROPERTY()
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UHazeCrumbComponent CrumbComponent;
	default ReplicateAsPhysicsObject();

	FVector PhysicsVelocity;

	AMarbleCheckpointTube Checkpoint;

    default Mesh.BodyInstance.bSimulatePhysics = true;

	bool bShouldBeDestroyed;

	UFUNCTION(BlueprintPure)
	bool GetIsFalling()
	{
		return !CurrentHitResult.bBlockingHit;
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeAkComponent.HazePostEvent(StartEvent);		
	}	

	UFUNCTION(BlueprintEvent)
	void OnHitEvent(FHitResult Hit)
	{
		
	}

	UFUNCTION(BlueprintPure)
	FVector GetPhysicalVelocity() property
	{
		if (HasControl())
		{
			return Mesh.GetPhysicsLinearVelocity();
		}

		else
		{
			return PhysicsVelocity;
		}
	}

	void SetMarblePhysicsVelocity(FVector Velocity) property
	{
		PhysicsVelocity = Velocity;
	}

	UFUNCTION(BlueprintEvent)
	void DestroyMarbleFX()
	{
		// Run in BP
	}

	UFUNCTION()
	void SetMarbleDestroyed(AMarbleCheckpointTube NewCheckpoint)
	{
		bShouldBeDestroyed = true;
		Checkpoint = NewCheckpoint;
	}
};