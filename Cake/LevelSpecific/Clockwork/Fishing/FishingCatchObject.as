class AFishingCatchObject : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent Anchor;

	UPROPERTY(DefaultComponent, Attach = Anchor)
	UStaticMeshComponent MeshComp;
	default MeshComp.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldStatic, ECollisionResponse::ECR_Overlap);
	default MeshComp.GenerateOverlapEvents = true; 

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.AutoDisableRange = 6000.f;

	bool bCanRotateMesh;
	bool bHaveResetRotation;

	FRotator InitialRotation;

	UPROPERTY()
	float CullDistanceMultiplier = 1.0f;

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		MeshComp.SetCullDistance(Editor::GetDefaultCullingDistance(MeshComp) * CullDistanceMultiplier);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InitialRotation = MeshComp.RelativeRotation;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bCanRotateMesh)
		{
			FRotator RotMovement = FRotator(0.f, 150.f, 250.f);
			FRotator NewRot = MeshComp.GetRelativeRotation() + (RotMovement * DeltaTime);
			MeshComp.SetRelativeRotation(NewRot);

			if (bHaveResetRotation)
			{
				bHaveResetRotation = false;
			}
		}
		else
		{
			if (!bHaveResetRotation)
			{
				MeshComp.SetRelativeRotation(InitialRotation);
				bHaveResetRotation = true;
			}
		}
	}
}