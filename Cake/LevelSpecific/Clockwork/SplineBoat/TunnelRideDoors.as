
class ATunnelRideDoors : AHazeActor
{
	//doors rotate open and close 
	//trigger references this script to call open and close  
	//Meshes attached to scene comps that rotate

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DoorHinge1;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DoorHinge2;
	
	UPROPERTY(DefaultComponent, Attach = DoorHinge1)
	UStaticMeshComponent DoorMeshComp1;
	default DoorMeshComp1.SetWorldScale3D(FVector(0.65f, 1.f, 1.f));

	UPROPERTY(DefaultComponent, Attach = DoorHinge2)
	UStaticMeshComponent DoorMeshComp2;
	default DoorMeshComp2.SetWorldScale3D(FVector(-0.65f, 1.f, 1.f));

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeAkComponent AkComp;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent DoorsOpening;

	bool bCanOpen;
	bool bDoorsAreActivated;

	float Dot;

	float MinAngleRotation = 30.f;
	float EndAngle = 1.f;

	float CurrentRotationSpeed;
	float MinRotationSpeed = 8.f;
	float MaxRotationSpeed = 32.f;

	float InterpTime = 2.2f;

	FVector HingeRightVector;
	FVector HingeForwardDefaultVector;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		DoorMeshComp1.SetCullDistance(Editor::GetDefaultCullingDistance(DoorMeshComp1) * CullDistanceMultiplier);
		DoorMeshComp2.SetCullDistance(Editor::GetDefaultCullingDistance(DoorMeshComp2) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{	
		HingeForwardDefaultVector = DoorHinge1.GetForwardVector();
		AddCapability(n"TunnelRideDoorsCapability");
	}

	void ActivateDoors()
	{
		if (!bDoorsAreActivated)
			bDoorsAreActivated = true;
	}

	void AudioDoorsOpening()
	{
		AkComp.HazePostEvent(DoorsOpening);
	}
}