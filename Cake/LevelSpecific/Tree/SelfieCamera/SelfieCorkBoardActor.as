import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraImage;

class ASelfieCorkBoardActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshCompBoard;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshPin1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshPin2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshPin3;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshImage1;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshImage2;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent MeshImage3;

	UPROPERTY(Category = "Setup")
	AHazeCameraActor Cam1;
	
	UPROPERTY(Category = "Setup")
	AHazeCameraActor Cam2;

	UPROPERTY(Category = "Setup")
	AHazeCameraActor Cam3;

	TArray<ASelfieCameraImage> CurrentImages;
	default CurrentImages.SetNum(3);

	TArray<FVector> LocationArray;

	TArray<FRotator> RotationArray;

	private int UsedIndex = -1;

	UFUNCTION()
	void SetNextImage(ASelfieCameraImage Image)
	{
		UsedIndex++;

		if (UsedIndex > CurrentImages.Num() - 1)
			UsedIndex = 0;
	}

	UFUNCTION()
	void DeleteLastImage(ASelfieCameraImage Image)
	{
		if (CurrentImages[UsedIndex] != nullptr)
			CurrentImages[UsedIndex].DestroyActor();

		CurrentImages[UsedIndex] = Image;
	}

	FVector GetImageTargetLocation()
	{
		FVector Loc;

		switch (UsedIndex)
		{
			case 0: Loc = MeshImage1.WorldLocation + FVector(0.f, 0.f, 25.f); break;
			case 1: Loc = MeshImage2.WorldLocation + FVector(0.f, 0.f, 25.f); break;
			case 2: Loc = MeshImage3.WorldLocation + FVector(0.f, 0.f, 25.f); break;
		}

		return Loc;
	}

	FRotator GetImageTargetRotation()
	{	
		FRotator Rot;
		
		switch (UsedIndex)
		{
			case 0: Rot = MeshImage1.WorldRotation; break;
			case 1: Rot = MeshImage2.WorldRotation; break;
			case 2: Rot = MeshImage3.WorldRotation; break;
		}

		return Rot;
	}

	AHazeCameraActor GetCamera()
	{
		AHazeCameraActor Cam;
		
		switch (UsedIndex)
		{
			case 0: Cam = Cam1; break;
			case 1: Cam = Cam2; break;
			case 2: Cam = Cam3; break;
		}

		return Cam;
	}
}