
class AShoesHanging : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent RootCompShoeOne;
	UPROPERTY(DefaultComponent, Attach = RootCompShoeOne)
	UStaticMeshComponent Shoe;
	UPROPERTY(DefaultComponent, Attach = Shoe)
	UStaticMeshComponent AcornOne;
	UPROPERTY(DefaultComponent, Attach = Shoe)
	UStaticMeshComponent AcornTwo;

	bool bStartMoving = false;
	UPROPERTY()
	bool bShoesOne = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		bStartMoving = true;
	}
	
	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if(!bStartMoving)
			return;

		if(bShoesOne)
		{
			FRotator RelativeRotationShoeOne;
			RelativeRotationShoeOne.Yaw = FMath::Sin(Time::GameTimeSeconds * 0.35f) * 33.f;
			RelativeRotationShoeOne.Roll = FMath::Sin(Time::GameTimeSeconds * 0.5f) * 2.f;
			RelativeRotationShoeOne.Pitch = FMath::Sin(Time::GameTimeSeconds * 0.5f) * 1.5f;
			Shoe.SetRelativeRotation(RelativeRotationShoeOne);
		}
		if(!bShoesOne)
		{
			FRotator RelativeRotationShoeOne;
			RelativeRotationShoeOne.Yaw = FMath::Sin(Time::GameTimeSeconds * 0.75f) * 10.f;
			RelativeRotationShoeOne.Roll = FMath::Sin(Time::GameTimeSeconds * 0.5f) * 2.f;
			RelativeRotationShoeOne.Pitch = FMath::Sin(Time::GameTimeSeconds * 0.5f) * 3.f;
			Shoe.SetRelativeRotation(RelativeRotationShoeOne);
		}
	}
}

