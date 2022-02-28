
class UDataAssetGodray : UDataAsset
{
    UPROPERTY()
	EGodrayType Type;

	UPROPERTY()
	FLinearColor Color = FLinearColor(0.442708, 0.363321, 0.175, 1);

    UPROPERTY()
    float CloseFadeDistance = 2000.0;

    UPROPERTY()
    float WorldClipHeight = 300000.0;

    UPROPERTY(Category="Procedual")
    float Tiling = 4;

    UPROPERTY(Category="Procedual")
    float Speed = 0.5;

    UPROPERTY(Category="Procedual", Meta = (EditCondition="Type == EGodrayType::Procedual2", EditConditionHides))
    float Angle = 1.5;

    UPROPERTY(Category="Procedual", Meta = (EditCondition="Type == EGodrayType::Procedual2", EditConditionHides))
    float GlowStrength = 0.5;

	UPROPERTY(Meta = (EditCondition="Type == EGodrayType::Texture", EditConditionHides))
	UTexture2D Texture;

	UPROPERTY(Meta = (EditCondition="Type == EGodrayType::Texture", EditConditionHides))
	UStaticMesh Mesh;
}

enum EGodrayType
{
    Texture,
    Procedual1,
    Procedual2
};

UCLASS(hidecategories="StaticMesh Physics Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class AGodray : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
    UGodrayComponent Component;

    UPROPERTY(DefaultComponent)
    UBillboardComponent Billboard;
	default Billboard.Sprite = Asset("/Game/Editor/EditorBillboards/Godray.Godray");
	default Billboard.bIsEditorOnly = true;
#if EDITOR
	default Billboard.bUseInEditorScaling = true;
#endif
	
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		Component.ConstructionScript_Hack();
    }
}

UCLASS(hidecategories="StaticMesh Physics Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class UGodrayComponent : UStaticMeshComponent
{
	UPROPERTY()
	UMaterial GodrayTexture = Asset("/Game/MasterMaterials/Godray.Godray");
	UPROPERTY()
	UMaterial GodrayProcedual1 = Asset("/Game/Blueprints/Environment/Godray/Godray_Procedual1.Godray_Procedual1");
	UPROPERTY()
	UMaterial GodrayProcedual2 = Asset("/Game/Blueprints/Environment/Godray/Godray_Procedual2.Godray_Procedual2");

    default CollisionProfileName = n"NoCollision";
	default StaticMesh = Asset("/Game/Blueprints/Environment/Godray/GodrayCard.GodrayCard");
    default SetMaterial(0, Asset("/Game/MasterMaterials/Godray.Godray"));

    UPROPERTY(NotVisible)
    UMaterialInstanceDynamic GodrayMaterialInstanceDynamic;

	UPROPERTY()
	UDataAssetGodray Template = Asset("/Game/Blueprints/Environment/Godray/DA_Spotlight1.DA_Spotlight1");

	UPROPERTY()
	float Opacity = 1.0f;

	UPROPERTY() // Exposing as a property to allow bp_hazeplane setting rotate false,
	bool Rotate = true;

    UFUNCTION()
	void SetOpacityValue(float Opacity)
	{
		this.Opacity = Opacity;
		GodrayMaterialInstanceDynamic.SetVectorParameterValue(n"Color", Template.Color * this.Opacity);
	}

    UFUNCTION()
    void ConstructionScript_Hack()
    {
		if(Template == nullptr)
			return;
			
		#if EDITOR
		// Give artists direct feedback on changes made on data asset component(s)
		Template.OnAssetChanged.Clear(); // Remove any previous delegates,
		Template.OnAssetChanged.AddUFunction(this, n"ConstructionScript_Hack");
		#endif

		if (Template.Type == EGodrayType::Texture)
			SetMaterial(0, GodrayTexture);
		else if(Template.Type == EGodrayType::Procedual1)
			SetMaterial(0, GodrayProcedual1);
		else if(Template.Type == EGodrayType::Procedual2)
			SetMaterial(0, GodrayProcedual2);

        FVector Scale = GetWorldScale();
        float minscale = FMath::Min(Scale.X, FMath::Min(Scale.Y, Scale.Z));
        float maxscale = FMath::Max(Scale.X, FMath::Max(Scale.Y, Scale.Z));
		SetCullDistance(maxscale * 1000);

		GodrayMaterialInstanceDynamic = CreateDynamicMaterialInstance(0);
		GodrayMaterialInstanceDynamic.SetVectorParameterValue(n"Color", Template.Color * Opacity);
		GodrayMaterialInstanceDynamic.SetTextureParameterValue(n"Texture", Template.Texture);
		
		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"Tiling", Template.Tiling);
		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"Speed", Template.Speed);
		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"Scale", maxscale * 10);
		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"CloseFadeDistance", Template.CloseFadeDistance);
		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"WorldClipHeight", Template.WorldClipHeight);
		//GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"Procedual", (Template.Type == EGodrayType::Procedual1) ? 1 : 0);


		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"Angle", Template.Angle);
		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"GlowStrength", Template.GlowStrength);


		GodrayMaterialInstanceDynamic.SetScalarParameterValue(n"Rotate", Rotate ? 1 : 0);

		// Make both Scale X and Y affect width.
		//FVector Scale = Owner.GetActorScale3D();
		//float AverageScaleA = (Scale.X+Scale.Y) / 2.0;
		//Owner.SetActorScale3D(FVector(AverageScaleA, AverageScaleA, Scale.Z));
		
		
		// Prevent from having negative size
		if(Scale.X < 0.05f)
			SetWorldScale3D(FVector(0.05f, Scale.Y, Scale.Z));
		if(Scale.Y < 0.05f)
			SetWorldScale3D(FVector(Scale.X, 0.05f, Scale.Z));
		if(Scale.Z < 0.05f)
			SetWorldScale3D(FVector(Scale.X, Scale.Y, 0.05f));
			
    }
}
