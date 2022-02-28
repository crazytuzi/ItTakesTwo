import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.RecordCrusherEvent.ClockworkRecordCrusher;

event void FClockFaceDestroyed();

class AClockworkLastBossRecordCrusherClockFace : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent ClockMesh;

	UPROPERTY(DefaultComponent, Attach = ClockMesh)
	UStaticMeshComponent MinuteHandMesh;

	UPROPERTY(DefaultComponent, Attach = ClockMesh)
	UStaticMeshComponent HourHandMesh;

	UPROPERTY(DefaultComponent, Attach = ClockMesh)
	UStaticMeshComponent DestroyClockCollision;

	UPROPERTY()
	FClockFaceDestroyed ClockFaceDestroyed;

	UPROPERTY()
	UMaterialInterface NonEmissiveMat;

	UPROPERTY()
	UMaterialInterface EmissiveMat;

	default PrimaryActorTick.bStartWithTickEnabled = false;

	bool bShouldRotateHands = false;
	bool bClockIsDestroyed = false;

	float RotateHandSpeed = -600.f;
	float CurrentRotateHandSpeed = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DestroyClockCollision.OnComponentBeginOverlap.AddUFunction(this, n"ClockCollisionOverlap");

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldRotateHands)
		{
			SetActorTickEnabled(false);
			return;
		}

		MinuteHandMesh.AddLocalRotation(FRotator(0.f, 0.f, CurrentRotateHandSpeed * DeltaTime));
		HourHandMesh.AddLocalRotation(FRotator(0.f, 0.f, CurrentRotateHandSpeed * DeltaTime * 0.625));
	}

	UFUNCTION()
	void ClockCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		if (!HasControl())
			return;
		
		AClockworkRecordCrusher Crusher = Cast<AClockworkRecordCrusher>(OtherActor);
		if(Crusher == nullptr)
			return;

		if (bClockIsDestroyed)
			return;
		
		NetDestroyClockFace(true);
	}

	UFUNCTION()
	void RotateClockHands(bool bClockwise)
	{
		if (bClockIsDestroyed)
			return;

		bShouldRotateHands = true;
		SetActorTickEnabled(true);

		if (bClockwise)
		{
			CurrentRotateHandSpeed = RotateHandSpeed;
		} else
		{
			CurrentRotateHandSpeed = RotateHandSpeed * -2.f;
		}
	}

	UFUNCTION()
	void StopRotatingHands()
	{
		bShouldRotateHands = false;
	}

	UFUNCTION(NetFunction)
	void NetDestroyClockFace(bool bEventIsActive)
	{
		if (!bClockIsDestroyed)
		{
			bClockIsDestroyed = true;	 
			StopRotatingHands();
			SetBrokenGlassHidden(false);
			ClockMesh.SetMaterial(0, NonEmissiveMat);
			
			if (bEventIsActive)
				ClockFaceDestroyed.Broadcast();
		}
	}

	UFUNCTION()
	void RepairClockFace()
	{
		bClockIsDestroyed = false; 
		StopRotatingHands();
		SetBrokenGlassHidden(true);
		bShouldRotateHands = true;
		SetActorTickEnabled(true);
		ClockMesh.SetMaterial(0, EmissiveMat);
	}

	UFUNCTION(BlueprintEvent)
	void SetBrokenGlassHidden(bool bGlassHidden)
	{}
}