
class UDataAssetLensFlare : UDataAsset
{
    UPROPERTY()
    UTexture2D Texture;

    UPROPERTY()
    float Scale = 1000;

    UPROPERTY()
    FLinearColor Tint = FLinearColor(1, 1, 1, 1);

    UPROPERTY()
    bool ChromaHoop = false;
}

class ALensFlare : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent Flare;
    default Flare.CollisionProfileName = n"NoCollision";

    UPROPERTY(DefaultComponent)
    UStaticMeshComponent Hoop;
    default Hoop.CollisionProfileName = n"NoCollision";
    
    UPROPERTY()
    UDataAssetLensFlare Preset = Asset("/Game/Blueprints/Environment/LensFlare/DA_Flare_Simple.DA_Flare_Simple");

	UPROPERTY()
    UStaticMesh FlareMesh = Asset("/Game/Blueprints/Environment/LensFlare/Flare_Mesh.Flare_Mesh");
	UPROPERTY()
    UStaticMesh HoopMesh = Asset("/Game/Blueprints/Environment/LensFlare/Flare_HoopMesh.Flare_HoopMesh");

	UPROPERTY()
    UMaterial FlareMaterial = Asset("/Game/Blueprints/Environment/LensFlare/LensFlareMaterial.LensFlareMaterial");
	UPROPERTY()
    UTexture2D HoopTexture = Asset("/Game/Blueprints/Environment/LensFlare/Flare_Hoop.Flare_Hoop");

    UMaterialInstanceDynamic HoopMaterialDynamic;
    UMaterialInstanceDynamic FlareMaterialDynamic;

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		if(Preset == nullptr)
			return;
        FVector ForwardVector = GetActorRotation().GetForwardVector();

        FlareMaterialDynamic = Material::CreateDynamicMaterialInstance(FlareMaterial);
        Flare.SetStaticMesh(FlareMesh);
        Flare.SetMaterial(0, FlareMaterialDynamic);
        FlareMaterialDynamic.SetTextureParameterValue(n"Flare", Preset.Texture);
        FlareMaterialDynamic.SetScalarParameterValue(n"Scale", Preset.Scale * 0.01f);
        FlareMaterialDynamic.SetVectorParameterValue(n"Tint", Preset.Tint);
        FlareMaterialDynamic.SetVectorParameterValue(n"BlueprintForward", FLinearColor(ForwardVector.X, ForwardVector.Y, ForwardVector.Z, 0));
        Flare.SetWorldRotation(FRotator(0,0,0));

        Hoop.SetVisibility(Preset.ChromaHoop);
        if(Preset.ChromaHoop)
        {
            HoopMaterialDynamic = Material::CreateDynamicMaterialInstance(FlareMaterial);
            Hoop.SetStaticMesh(HoopMesh);
            Hoop.SetMaterial(0, HoopMaterialDynamic);
            HoopMaterialDynamic.SetTextureParameterValue(n"Flare", HoopTexture);
            HoopMaterialDynamic.SetScalarParameterValue(n"HazeToggle_IsHoop", 1.0f);
            HoopMaterialDynamic.SetVectorParameterValue(n"BlueprintForward", FLinearColor(ForwardVector.X, ForwardVector.Y, ForwardVector.Z, 0));
            Hoop.SetWorldRotation(FRotator(0,0,0));
        }
    }
    
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {

    }

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {

    }
}