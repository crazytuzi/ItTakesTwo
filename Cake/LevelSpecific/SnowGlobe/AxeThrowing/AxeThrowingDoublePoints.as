import Cake.LevelSpecific.SnowGlobe.AxeThrowing.IceAxeActor;

enum EMovementTypeDoublePoints
{
	Move,
	Rotate
}

enum ERotationAxisDoublePoints
{
	Pitch,
	Yaw,
	Roll
}

enum ERotationDirectionDoublePoints
{
	Negative,
	Positive
}

class AAxeThrowingDoublePoints : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshHoopComp;
	default MeshHoopComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = MeshHoopComp)
	UStaticMeshComponent MeshDoublePointsComp;
	default MeshDoublePointsComp.SetCollisionResponseToAllChannels(ECollisionResponse::ECR_Block);

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent HoopBase;

	UPROPERTY(DefaultComponent, Attach = MeshHoopComp)
	USphereComponent Collision;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp;

	UPROPERTY(Category = "Capability")
	TSubclassOf<UHazeCapability> Capability;

	UPROPERTY(Category = "Setup")
	EMovementTypeDoublePoints MovementType;

	UPROPERTY(Category = "Setup")
	ERotationAxisDoublePoints RotationAxis;

	UPROPERTY(Category = "Setup")
	ERotationDirectionDoublePoints RotationDirection;

	UPROPERTY(Category = "Setup")
	float MovementAmount = 250.f;

	UPROPERTY(Category = "Setup")
	float RotationAmount = 90.f;

	UPROPERTY(Category = "Setup")
	float Radial = 167;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent HoopActivated;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent HoopDeactivated;

	bool bIsActive;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddCapability(Capability);
		Collision.OnComponentBeginOverlap.AddUFunction(this, n"HandleBeginOverlap");
	}

	UFUNCTION()
	void HandleBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, FHitResult& Hit)
	{
		if (!bIsActive)
			return;

		auto Axe = Cast<AIceAxeActor>(OtherActor);
		
		if (Axe == nullptr)
			return;

		Axe.bIsDoublePoints = true;
	}

	void ActivateHoop()
	{
		if (bIsActive)
			return;

		bIsActive = true;
		AkComp.HazePostEvent(HoopActivated);
	}

	void DeactivateHoop()
	{
		if (!bIsActive)
			return;

		bIsActive = false;
		AkComp.HazePostEvent(HoopDeactivated);
	}
}