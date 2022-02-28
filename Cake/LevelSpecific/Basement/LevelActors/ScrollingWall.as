import Cake.LevelSpecific.Basement.ParentBlob.ParentBlobPlayerComponent;

event void FTransitionToNextRoom();

UCLASS(Abstract)
class AScrollingWall : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY()
	UStaticMesh Mesh;

	UPROPERTY()
	TArray<UMaterialInstance> MaterialOverride;

	UPROPERTY()
	int Segments = 20;

	UPROPERTY()
	float SegmentDistance = 1250.f;

	UPROPERTY()
	FVector MeshScale = FVector(0.5f, 0.5f, 0.5f);

	UPROPERTY(NotVisible)
	TArray<UStaticMeshComponent> MeshComps;

	UPROPERTY()
	bool bActive = false;

	UPROPERTY()
	FVector InvisibleWallOffset = FVector(2500.f, 0.f, 0.f);

	UPROPERTY()
	FTransitionToNextRoom TransitionToNextRoom;

	float TimeRequiredToTransition = 5.f;
	float CurrentTime = 0.f;
	bool bTransitioned = false;

	UPROPERTY(NotEditable)
	float CurrentScale = 0.5f;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike ScaleChangeTimeLike;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshComps.Empty();

		for (int Index = 0, Count = Segments; Index < Count; ++ Index)
		{
			UStaticMeshComponent CurMeshComp = UStaticMeshComponent::Create(this);
			CurMeshComp.SetStaticMesh(Mesh);

			for (int OverrideIndex = 0, OverrideCount = MaterialOverride.Num(); OverrideIndex < OverrideCount; ++ OverrideIndex)
			{
				CurMeshComp.SetMaterial(OverrideIndex, MaterialOverride[OverrideIndex]);
			}

			CurMeshComp.SetRelativeLocation(FVector(Index * SegmentDistance, 0.f, 0.f));
			CurMeshComp.SetRelativeScale3D(MeshScale);
			CurMeshComp.SetRelativeRotation(FRotator(0.f, 90.f, 0.f));

			MeshComps.Add(CurMeshComp);
		}
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ScaleChangeTimeLike.SetPlayRate(0.2f);
		ScaleChangeTimeLike.BindUpdate(this, n"UpdateScaleChange");
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateScaleChange(float CurValue)
	{
		float CurScale = FMath::Lerp(0.5f, 0.4f, CurValue);

		for (UStaticMeshComponent CurMeshComp : MeshComps)
		{
			CurMeshComp.SetRelativeScale3D(FVector(CurScale, 0.5f, CurScale));
		}
	}

	UFUNCTION()
	void StartScaling()
	{
		bActive = true;
		// ScaleChangeTimeLike.PlayFromStart();
	}

	UFUNCTION()
	void StopScaling()
	{
		bActive = false;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (GetActiveParentBlobActor() == nullptr)
			return;

		/*FHitResult Hit = GetActiveParentBlobActor().MoveComp.ForwardHit;
		if (Hit.Component != nullptr && Hit.Component == InvisibleWall)	
		{
			StartScaling();
			CurrentTime += DeltaTime;
			if (!bTransitioned && CurrentTime >= TimeRequiredToTransition)
			{
				TransitionToNextRoom.Broadcast();
				bTransitioned = true;
			}
		}
		else
		{
			StopScaling();
		}

		if (!bActive)
			return;

		AParentBlob TBO = GetActiveParentBlobActor();

		FVector Vel = Math::ConstrainVectorToDirection(TBO.DesiredVelocity, ActorForwardVector);
		float Speed = Vel.Size();

		int CurIndex = 0;
		for (UStaticMeshComponent CurMeshComp : MeshComps)
		{
			CurMeshComp.AddRelativeLocation(FVector(-Speed * DeltaTime, 0.f, 0.f));
			float CurX = CurMeshComp.RelativeLocation.X;
			if (CurX < 0.f)
			{
				CurMeshComp.SetRelativeLocation(FVector((Segments * SegmentDistance) + CurX, 0.f, 0.f));
			}

			CurIndex++;
		}*/

		if (!bActive)
			return;

		float PlayerSpeed = GetActiveParentBlobActor().ActorVelocity.Y;
		float ScaleMultiplier = PlayerSpeed * 0.0001f * DeltaTime;
		CurrentScale += ScaleMultiplier;
		CurrentScale = FMath::Clamp(CurrentScale, 0.1f, 0.5f);
		
		for (UStaticMeshComponent CurMeshComp : MeshComps)
		{
			// CurMeshComp.SetRelativeScale3D(FVector(CurrentScale, 0.5f, CurrentScale));
		}
	}
}