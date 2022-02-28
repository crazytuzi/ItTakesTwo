UCLASS(Abstract)
class AShutterDoor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UBillboardComponent Billboard;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ShutterDoorRoot;

	UPROPERTY(DefaultComponent, Attach = ShutterDoorRoot)
	UStaticMeshComponent ShutterDoorMesh1;

	UPROPERTY(DefaultComponent, Attach = ShutterDoorRoot)
	UStaticMeshComponent ShutterDoorMesh2;

	UPROPERTY(DefaultComponent, Attach = ShutterDoorRoot)
	UStaticMeshComponent ShutterDoorMesh3;

	UPROPERTY(DefaultComponent, Attach = ShutterDoorRoot)
	UStaticMeshComponent ShutterDoorMesh4;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComponent;

	UPROPERTY()
	bool bOpenFromStart = true;

	TMap<UStaticMeshComponent, FVector> DoorLocationMap;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike MoveShutterDoorsTimeLike;
	default MoveShutterDoorsTimeLike.Duration = 0.5f;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent ShutterDoorsOutEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent ShutterDoorsInEvent;

	UPROPERTY()
	bool bUseScale = false;

	UPROPERTY()
	float EndOffset = 150.f;

	bool bOpen = false;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		DoorLocationMap.Empty();

		DoorLocationMap.Add(ShutterDoorMesh1, FVector(EndOffset, EndOffset, 0.f));
		DoorLocationMap.Add(ShutterDoorMesh2, FVector(EndOffset, -EndOffset, 0.f));
		DoorLocationMap.Add(ShutterDoorMesh3, FVector(-EndOffset, EndOffset, 0.f));
		DoorLocationMap.Add(ShutterDoorMesh4, FVector(-EndOffset, -EndOffset, 0.f));

		if (bOpenFromStart)
		{
			bOpen = true;
			for (auto CurDoor : DoorLocationMap)
			{
				CurDoor.Key.SetRelativeLocation(CurDoor.Value);
			}

			ShutterDoorRoot.SetRelativeRotation(FRotator(0.f, 179.f, 0.f));
		}
		else
		{
			for (auto CurDoor : DoorLocationMap)
			{
				CurDoor.Key.SetRelativeLocation(FVector::ZeroVector);
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveShutterDoorsTimeLike.BindUpdate(this, n"UpdateMoveTowardsMiddle");
		if (bOpenFromStart)
			bOpen = true;
	}

	UFUNCTION()
	void OpenShutterDoors()
	{
		if (bOpen)
			return;

		bOpen = true;
		MoveShutterDoorsTimeLike.PlayFromStart();
		UHazeAkComponent::HazePostEventFireForget(ShutterDoorsOutEvent, GetActorTransform());
	}

	UFUNCTION()
	void CloseShutterDoors(bool bSnapShut)
	{
		if (bSnapShut)
		{
			for (auto CurDoor : DoorLocationMap)
				CurDoor.Key.SetRelativeLocation(FVector::ZeroVector);
				
			return;
		}

		if (!bOpen)
			return;
			
		bOpen = false;
		UHazeAkComponent::HazePostEventFireForget(ShutterDoorsInEvent, GetActorTransform());
		MoveShutterDoorsTimeLike.ReverseFromEnd();
	}

	UFUNCTION()
	void UpdateMoveTowardsMiddle(float CurValue)
	{
		for (auto CurDoor : DoorLocationMap)
		{
			FVector CurLoc = FMath::Lerp(FVector::ZeroVector, CurDoor.Value, CurValue);
			CurDoor.Key.SetRelativeLocation(CurLoc);
			if (bUseScale)
			{
				float CurScale = FMath::Lerp(1.f, 0.1f, CurValue);
				CurDoor.Key.SetWorldScale3D(FVector(CurScale, CurScale, 1.f));
			}
		}

		float CurRotation = FMath::Lerp(0.f, 179.f, CurValue);
		ShutterDoorRoot.SetRelativeRotation(FRotator(0.f, CurRotation, 0.f));
	}
}