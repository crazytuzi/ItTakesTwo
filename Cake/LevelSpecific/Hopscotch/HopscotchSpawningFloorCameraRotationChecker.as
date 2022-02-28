import Vino.Camera.Components.CameraUserComponent;

event void FHopscotchSpawningFloorCameraRotationCheckerSignature(float CodyCamRotSpeed, float MayCamRotSpeed, float CombinedCamRotSpeed);

class AHopscotchSpawningFloorCameraRotationChecker : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UBoxComponent BoxCollision;

	UPROPERTY()
	FHopscotchSpawningFloorCameraRotationCheckerSignature RotationSpeedEvent;

	TArray<AHazePlayerCharacter> PlayerArray;

	bool bShouldCheckCameraRotation = false;

	UCameraUserComponent CodyCamUserComp;
	UCameraUserComponent MayCamUserComp;

	float CodyCamRotSpeed = 0.f;
	float MayCamRotSpeed = 0.f;
	float CombinedRotSpeed = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"BoxCollisionOverlap");
		BoxCollision.OnComponentEndOverlap.AddUFunction(this, n"BoxCollisionEndOverlap");
		
		CodyCamUserComp = UCameraUserComponent::Get(Game::GetCody());
		MayCamUserComp = UCameraUserComponent::Get(Game::GetMay());
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (!bShouldCheckCameraRotation)
			return;

		CodyCamRotSpeed = CodyCamUserComp.GetDesiredRotationVelocity().Euler().Size();
		MayCamRotSpeed = MayCamUserComp.GetDesiredRotationVelocity().Euler().Size();
		CombinedRotSpeed = CodyCamRotSpeed + MayCamRotSpeed;

		RotationSpeedEvent.Broadcast(CodyCamRotSpeed, MayCamRotSpeed, CombinedRotSpeed);
	}

	UFUNCTION()
	void BoxCollisionOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		PlayerArray.AddUnique(Player);	
		CheckPlayerArray();		
	}

	UFUNCTION()
	void BoxCollisionEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		PlayerArray.Remove(Player);
		CheckPlayerArray();
	}

	void CheckPlayerArray()
	{
		bShouldCheckCameraRotation = PlayerArray.Num() > 0; 	
	}	
}