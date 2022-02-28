
import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

UCLASS(Abstract)
class ASeekingTentacleEye : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent TentacleRoot;

	UPROPERTY(DefaultComponent, Attach = TentacleRoot)
	UHazeSkeletalMeshComponentBase TentacleMesh;

	UPROPERTY(DefaultComponent, Attach = TentacleMesh, AttachSocket = Tentacle8)
	USceneComponent EyeRoot;

	UPROPERTY(DefaultComponent, Attach = EyeRoot)
	UStaticMeshComponent EyeMesh;

	UPROPERTY(DefaultComponent, Attach = EyeRoot)
	USpotLightComponent SearchLight;

	UPROPERTY(DefaultComponent, Attach = EyeRoot)
	UStaticMeshComponent VisionCone;

	UPROPERTY()
	TArray<AActor> ScanPoints;

	bool bScanning = false;

	AActor CurrentScanPoint;

	int CurrentScanIndex = 1;

	float ScanRotationSpeed = 15.f;

	float StopTimeAtScanPoint = 4.f;

	bool bIncrementing = true;

	bool bPlayersSpotted = false;

	float CurrentPupilScale = 0.75f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		EyeRoot.SetWorldRotation(FRotator(FRotator(0.f, ActorRotation.Yaw, 0.f)));
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		VisionCone.OnComponentBeginOverlap.AddUFunction(this, n"EnterCone");
		VisionCone.OnComponentEndOverlap.AddUFunction(this, n"ExitCone");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		EyeRoot.SetWorldRotation(FRotator(FRotator(0.f, ActorRotation.Yaw, 0.f)));

		if (bScanning)
		{
			FVector DirToScanPoint = ScanPoints[CurrentScanIndex].ActorLocation - ActorLocation;
			DirToScanPoint = Math::ConstrainVectorToPlane(DirToScanPoint, FVector::UpVector);
			DirToScanPoint.Normalize();
			FRotator TargetRot = DirToScanPoint.Rotation();
			FRotator CurRot = FMath::RInterpConstantTo(ActorRotation, TargetRot, DeltaTime, ScanRotationSpeed);
			SetActorRotation(CurRot);

			if (FMath::IsNearlyEqual(CurRot.Yaw, TargetRot.Yaw, 0.1f))
			{
				if (CurrentScanIndex == ScanPoints.Num() - 1)
				{
					CurrentScanIndex--;
					bIncrementing = false;
				}
				else if (CurrentScanIndex == 0)
				{
					CurrentScanIndex++;
					bIncrementing = true;
				}
				else if (bIncrementing)
				{
					CurrentScanIndex++;
				}
				else
				{
					CurrentScanIndex--;
				}

				bScanning = false;
				System::SetTimer(this, n"StartScanning", StopTimeAtScanPoint, false);
			}
		}

		float TargetPupilScale;
		if (bPlayersSpotted)
			TargetPupilScale = 1.15f;
		else
			TargetPupilScale = 0.85f;

		CurrentPupilScale = FMath::FInterpTo(CurrentPupilScale, TargetPupilScale, DeltaTime, 2.f);
		EyeMesh.SetScalarParameterValueOnMaterials(n"PupilScale", CurrentPupilScale);
	}

	UFUNCTION()
	void StartScanning()
	{
		bScanning = true;
	}

	UFUNCTION()
	void UpdateScanPoints(TArray<AActor> NewScanPoints, int NewIndex)
	{
		CurrentScanIndex = NewIndex;
		ScanPoints = NewScanPoints;
	}

	UFUNCTION(NotBlueprintCallable)
	void EnterCone(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
	{
		AParentBlob ParentBlob = Cast<AParentBlob>(OtherActor);
		if (ParentBlob != nullptr)
		{
			bPlayersSpotted = true;
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void ExitCone(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
	{
		AParentBlob ParentBlob = Cast<AParentBlob>(OtherActor);
		if (ParentBlob != nullptr)
		{
			bPlayersSpotted = false;
		}
	}

	UFUNCTION()
	void TriggerPushback()
	{
		AParentBlob ParentBlob = GetActiveParentBlobActor();

		if (ParentBlob != nullptr)
		{
			FVector PushForce = (ActorForwardVector * 8000.f) + FVector(0.f, 0.f, 3000.f);
			// ParentBlob.AddImpulse(PushForce);
		}
	}
}