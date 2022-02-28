import Rice.Props.PropBaseActor;
UCLASS(HideCategories = "Physics Collision Rendering Cooking Tags LOD Activation AssetUserData")
class UGardenUnwitherComponent : USceneComponent
{
	UStaticMeshComponent StaticMeshComp;

	UPROPERTY()
	bool bStartUnwithered = false;

	UPROPERTY(NotEditable)
	float BlendTarget = 0;
	UPROPERTY(NotEditable)
	float BlendValue = 0;
	UPROPERTY()
	float BlendSpeed = 0.5f;

	UPROPERTY(NotEditable)
	UMaterialInterface Mat;

	UPROPERTY(NotEditable)
	UMaterialInstanceDynamic DynamicMat;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Initialize();

		DynamicMat = StaticMeshComp.CreateDynamicMaterialInstance(0);

		StaticMeshComp.SetMaterial(0, DynamicMat);
		DynamicMat.SetScalarParameterValue(n"HazeToggle_UsePainting", 0.0f);

		if(bStartUnwithered && BlendTarget != 1.0f)
		{
			BlendTarget = 1.0f;
			BlendValue = 1.0f;
			DynamicMat.SetScalarParameterValue(n"BlendValue", BlendTarget);
		}
		else if(!bStartUnwithered && BlendTarget != 0.0f)
		{
			BlendTarget = 0.0f;
			BlendValue = 0.0f;
			DynamicMat.SetScalarParameterValue(n"BlendValue", BlendTarget);
		}
	}
	
	void Initialize()
	{
		StaticMeshComp = Cast<UStaticMeshComponent>(AttachParent);
		Mat = StaticMeshComp.Materials[0];
	}

	UFUNCTION()
    void Wither()
    {
		BlendTarget = 0.0f;
	}

	UFUNCTION()
    void UnWither()
    {
		BlendTarget = 1.0f;
	}

    float MoveTowards(float Current, float Target, float StepSize)
    {
        return Current + FMath::Clamp(Target - Current, -StepSize, StepSize);
    }

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		BlendValue = MoveTowards(BlendValue, BlendTarget, DeltaTime * BlendSpeed);
		DynamicMat.SetScalarParameterValue(n"BlendValue", BlendValue);
	}
}