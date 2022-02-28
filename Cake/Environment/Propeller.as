class UDataAssetPropeller : UDataAsset
{
    UPROPERTY()
    UStaticMesh Mesh;
    
    UPROPERTY()
    UTexture2D SpinningFastTexture;

    UPROPERTY()
    float SpinningFastTextureZOffset = 10;

    UPROPERTY()
    float SpinningFastTextureSize = 140;
}

class APropeller : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent Model;

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent FastSpinningPlane;

    UPROPERTY()
    UDataAssetPropeller Preset = Asset("/Game/Blueprints/Environment/Propeller/DA_Propeller.DA_Propeller");

    UStaticMesh FastSpinningPlaneMesh = Asset("/Game/Blueprints/Environment/Propeller/FastSpinningPlaneMesh.FastSpinningPlaneMesh");
    UMaterial FastSpinningPlaneMaterial = Asset("/Game/Blueprints/Environment/Propeller/FastSpinningPlaneMaterial.FastSpinningPlaneMaterial");
    UMaterialInstanceDynamic FastSpinningPlaneMaterialInstanceDynamic;

    UPROPERTY()
    float TargetSpeed = 1000.0;

    float Speed = 0.0;
    float CurrentRotation = 0.0;
    float StartSpeedDistance = 0.0;
    float TimeToReach = 0.1;
    
    void SetSpeed(float TargetSpeed, float TimeToReach = 0)
    {
        this.StartSpeedDistance = TargetSpeed - Speed;
        this.TimeToReach = FMath::Max(0.0001f, TimeToReach);
        this.TargetSpeed = TargetSpeed;
    }

    float MoveTowards(float Current, float Target, float StepSize)
    {
        return Current + FMath::Clamp(Target - Current, -StepSize, StepSize);
    }

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
        Model.SetStaticMesh(Preset.Mesh);
        FastSpinningPlane.SetStaticMesh(FastSpinningPlaneMesh);
        FastSpinningPlane.SetRelativeScale3D(FVector(Preset.SpinningFastTextureSize, Preset.SpinningFastTextureSize, Preset.SpinningFastTextureSize));
        FastSpinningPlane.SetRelativeLocation(FVector(0, 0, Preset.SpinningFastTextureZOffset));
        
        FastSpinningPlaneMaterialInstanceDynamic = Material::CreateDynamicMaterialInstance(FastSpinningPlaneMaterial);
        FastSpinningPlaneMaterialInstanceDynamic.SetTextureParameterValue(n"Texture", Preset.SpinningFastTexture);
        FastSpinningPlane.SetMaterial(0, FastSpinningPlaneMaterialInstanceDynamic);

    }
    
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
        SetSpeed(TargetSpeed, 0.2);
    }

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
        Speed = MoveTowards(Speed, TargetSpeed, (StartSpeedDistance / TimeToReach) * DeltaTime);

        CurrentRotation += Speed * DeltaTime;

        Model.SetRelativeRotation(FRotator(0, CurrentRotation, 0));
        FastSpinningPlane.SetRelativeRotation(FRotator(0, CurrentRotation, 0));
    }
}