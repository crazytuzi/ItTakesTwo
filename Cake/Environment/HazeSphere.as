
enum EFogVolume
{
    Sphere,
    Box,
};

enum EColorType
{
    Color,
    Gradient,
    Temperature,
};

enum EScaleType
{
    Free,
    Uniform,
    Locked,
};

enum ERotationType
{
    Free,
    Uniform,
    Locked,
};

struct FHazeSphereData
{
    UStaticMesh Mesh;
    EScaleType ScaleType;
    ERotationType RotationType;
    // Scale factor is the length longest line through the object.
    float ScaleFactor;
}

struct BlendFloat
{
	BlendFloat(float Start, float Target)
	{
		this.Start = Start;
		this.Target = Target;
	}
	float Blend(float T)
	{
		return FMath::Lerp(Start, Target, T);
	}
	float Start;
	float Target;
}
struct BlendColor
{
	BlendColor(FLinearColor Start, FLinearColor Target)
	{
		this.Start = Start;
		this.Target = Target;
	}
	FLinearColor Blend(float T)
	{
		return FLinearColor(FMath::Lerp(Start.R, Target.R, T),
							FMath::Lerp(Start.G, Target.G, T),
							FMath::Lerp(Start.B, Target.B, T), 
							FMath::Lerp(Start.A, Target.A, T));
	}
	FLinearColor Start;
	FLinearColor Target;
}
//Rendering
UCLASS(hidecategories="StaticMesh Materials Physics  Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class UHazeSphereComponent : UStaticMeshComponent
{
    default CollisionProfileName = n"NoCollision";
	default CastShadow = false;
	default PrimaryComponentTick.bStartWithTickEnabled = false;

    UPROPERTY()
    EFogVolume Type = EFogVolume::Sphere;
	
	UPROPERTY()
    float Opacity = 1.0f;
	BlendFloat BlendOpacity;
    

    UPROPERTY()
    float Softness = 1.0f;
	BlendFloat BlendSoftness;
    
    UPROPERTY()
    EColorType ColorType = EColorType::Color;
    
    UPROPERTY(Meta = (EditCondition="ColorType != EColorType::Temperature", EditConditionHides))
    FLinearColor ColorA = FLinearColor(0.428691f, 0.502887f, 0.545725f, 1.0f);
	BlendColor BlendColorA;

    UPROPERTY(Meta = (EditCondition="ColorType == EColorType::Gradient", EditConditionHides))
    FLinearColor ColorB = FLinearColor(0.545725f, 0.502887f, 0.428691f, 1.0f);
	BlendColor BlendColorB;

    UPROPERTY(Meta = (EditCondition="ColorType == EColorType::Temperature", EditConditionHides))
    float MinTemperature = 0.0f;
	BlendFloat BlendMinTemperature;

    UPROPERTY(Meta = (EditCondition="ColorType == EColorType::Temperature", EditConditionHides))
    float MaxTemperature = 5000.0f;
	BlendFloat BlendMaxTemperature;

    UPROPERTY(Meta = (EditCondition="ColorType != EColorType::Color", EditConditionHides))
    float Contrast = 1.0f;
	BlendFloat BlendContrast;
	
    UPROPERTY(Meta = (EditCondition="ColorType != EColorType::Color", EditConditionHides))
    float Offset = 0.5f;
	BlendFloat BlendOffset;

	private float CurrentLerpTime = 0;
	private float TotalLerpTime = 0;

    UPROPERTY(Category="Rendering")
	int TranslucencyPriority = 0;

    UPROPERTY(Category="zzInternal")
    UMaterialInstance HazeSphereMaterial = Asset("/Game/Blueprints/Environment/HazeSphere/HazeSphere_Mat_Expensive.HazeSphere_Mat_Expensive");
    UPROPERTY(Category="zzInternal")
    UMaterialInstance HazeSphereMaterial_Cheap = Asset("/Game/Blueprints/Environment/HazeSphere/HazeSphere_Mat_Cheap.HazeSphere_Mat_Cheap");
	
    UPROPERTY(Category="zzInternal")
    UMaterialInstance HazeSphereMaterial_Upgraded = Asset("/Game/Blueprints/Environment/HazeSphere/HazeSphere_Mat_Expensive_Upgraded.HazeSphere_Mat_Expensive_Upgraded");
    UPROPERTY(Category="zzInternal")
    UMaterialInstance HazeSphereMaterial_Cheap_Upgraded = Asset("/Game/Blueprints/Environment/HazeSphere/HazeSphere_Mat_Cheap_Upgraded.HazeSphere_Mat_Cheap_Upgraded");

    UPROPERTY(Category="Data")
    EColorType OldColorType = EColorType::Color;
	
    UPROPERTY(Category="Data")
	bool Upgraded = true;

    UPROPERTY()
	float CullingDistanceMultiplier = 1.0;

    UPROPERTY(Category="Data")
    UMaterialInstanceDynamic HazeSphereMaterialDynamic;

    UPROPERTY(Category="Data")
    UMaterialInstanceDynamic HazeSphereMaterialDynamic_Cheap;

    UPROPERTY(Category="zzInternal")
    UStaticMesh CubeMesh = Asset("/Game/Blueprints/Environment/HazeSphere/HazeCube_Inverted.HazeCube_Inverted");
    UPROPERTY(Category="zzInternal")
    UStaticMesh SphereMesh = Asset("/Game/Blueprints/Environment/HazeSphere/HazeSphere_lodding.HazeSphere_lodding");

    UPROPERTY(NotEditable)
	FHazeSphereData Data;

	// TODO(mwestphal): When lucas adds a proper solution instead of this hack, add a warning message whenever this function is called
    UFUNCTION()
    void ConstructionScript_Hack()
    {
        FVector Scale = GetWorldScale();
        float minscale = FMath::Min(Scale.X, FMath::Min(Scale.Y, Scale.Z));
        float maxscale = FMath::Max(Scale.X, FMath::Max(Scale.Y, Scale.Z));

        if(Type == EFogVolume::Sphere)
        {
            Data.Mesh = SphereMesh;
            Data.ScaleType = EScaleType::Uniform;
            Data.RotationType = ERotationType::Locked;
            Data.ScaleFactor = 1.0f * minscale;

			float SphereScale = minscale;
			if(Scale.X == Scale.Y && Scale.Z != Scale.Y)
				SphereScale = Scale.Z;
			if(Scale.X == Scale.Z && Scale.Y != Scale.Z)
				SphereScale = Scale.Y;
			if(Scale.Y == Scale.Z && Scale.X != Scale.Z)
				SphereScale = Scale.X;
			// Enforce uniform Scale
			SetWorldScale3D(FVector(SphereScale, SphereScale, SphereScale));
        }
        else if(Type == EFogVolume::Box)
        {
            Data.Mesh = CubeMesh;
            Data.ScaleType = EScaleType::Free;
            Data.RotationType = ERotationType::Free;
            Data.ScaleFactor = 1.732f * minscale;
        }

		SetTranslucentSortPriority(TranslucencyPriority);
		SetCullDistance(Data.ScaleFactor * 1500 * CullingDistanceMultiplier);

        SetStaticMesh(Data.Mesh);
		if(Upgraded)
		{
			HazeSphereMaterialDynamic = Material::CreateDynamicMaterialInstance(HazeSphereMaterial_Upgraded);
			HazeSphereMaterialDynamic_Cheap = Material::CreateDynamicMaterialInstance(HazeSphereMaterial_Cheap_Upgraded);
		}
		else
		{
			HazeSphereMaterialDynamic = Material::CreateDynamicMaterialInstance(HazeSphereMaterial);
			HazeSphereMaterialDynamic_Cheap = Material::CreateDynamicMaterialInstance(HazeSphereMaterial_Cheap);
		}

        SetMaterial(0, HazeSphereMaterialDynamic);
        SetMaterial(1, nullptr);
        SetMaterial(2, HazeSphereMaterialDynamic_Cheap);

		UpdateAllMaterialParameters();
		
		// Prevent from having negative size
		if(Scale.X < 0.05f)
			SetWorldScale3D(FVector(0.05f, Scale.Y, Scale.Z));
		if(Scale.Y < 0.05f)
			SetWorldScale3D(FVector(Scale.X, 0.05f, Scale.Z));
		if(Scale.Z < 0.05f)
			SetWorldScale3D(FVector(Scale.X, Scale.Y, 0.05f));

    }
    
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		BlendOpacity = BlendFloat(Opacity, Opacity);
		BlendSoftness = BlendFloat(Softness, Softness);
		BlendColorA = BlendColor(ColorA, ColorA);
		BlendColorB = BlendColor(ColorB, ColorB);
		BlendMinTemperature = BlendFloat(MinTemperature, MinTemperature);
		BlendMaxTemperature = BlendFloat(MaxTemperature, MaxTemperature);
		BlendContrast = BlendFloat(Contrast, Contrast);
		BlendOffset = BlendFloat(Offset, Offset);
    }

	void UpdateAllMaterialParameters()
	{
		if(HazeSphereMaterialDynamic == nullptr)
			return;
			
        HazeSphereMaterialDynamic.SetScalarParameterValue(n"Type", Type);
        HazeSphereMaterialDynamic.SetScalarParameterValue(n"ColorType", ColorType);
		HazeSphereMaterialDynamic.SetVectorParameterValue(n"ColorA", FLinearColor(ColorA.R, ColorA.G, ColorA.B, ColorA.A));
        HazeSphereMaterialDynamic.SetVectorParameterValue(n"ColorB", FLinearColor(ColorB.R, ColorB.G, ColorB.B, ColorB.A));
        HazeSphereMaterialDynamic.SetScalarParameterValue(n"MinTemperature", MinTemperature);
        HazeSphereMaterialDynamic.SetScalarParameterValue(n"MaxTemperature", MaxTemperature);
        HazeSphereMaterialDynamic.SetScalarParameterValue(n"Opacity", Opacity);
        HazeSphereMaterialDynamic.SetScalarParameterValue(n"Softness", Softness);
        HazeSphereMaterialDynamic.SetScalarParameterValue(n"Contrast", Contrast);
        HazeSphereMaterialDynamic.SetScalarParameterValue(n"Offset", Offset);
        HazeSphereMaterialDynamic.SetScalarParameterValue(n"Scale", Data.ScaleFactor);
        HazeSphereMaterialDynamic.SetScalarParameterValue(n"CullDistance", Data.ScaleFactor * 1500 * CullingDistanceMultiplier);
			
        HazeSphereMaterialDynamic_Cheap.SetScalarParameterValue(n"Type", Type);
        HazeSphereMaterialDynamic_Cheap.SetScalarParameterValue(n"ColorType", ColorType);
		HazeSphereMaterialDynamic_Cheap.SetVectorParameterValue(n"ColorA", FLinearColor(ColorA.R, ColorA.G, ColorA.B, ColorA.A));
        HazeSphereMaterialDynamic_Cheap.SetVectorParameterValue(n"ColorB", FLinearColor(ColorB.R, ColorB.G, ColorB.B, ColorB.A));
        HazeSphereMaterialDynamic_Cheap.SetScalarParameterValue(n"MinTemperature", MinTemperature);
        HazeSphereMaterialDynamic_Cheap.SetScalarParameterValue(n"MaxTemperature", MaxTemperature);
        HazeSphereMaterialDynamic_Cheap.SetScalarParameterValue(n"Opacity", Opacity);
        HazeSphereMaterialDynamic_Cheap.SetScalarParameterValue(n"Softness", Softness);
        HazeSphereMaterialDynamic_Cheap.SetScalarParameterValue(n"Contrast", Contrast);
        HazeSphereMaterialDynamic_Cheap.SetScalarParameterValue(n"Offset", Offset);
        HazeSphereMaterialDynamic_Cheap.SetScalarParameterValue(n"Scale", Data.ScaleFactor);
        HazeSphereMaterialDynamic_Cheap.SetScalarParameterValue(n"CullDistance", Data.ScaleFactor * 1500 * CullingDistanceMultiplier);
	}

	void SetEverything(float Opacity, FLinearColor ColorA, FLinearColor ColorB, float Softness, float MinTemperature, float MaxTemperature, float Contrast, float Offset)
	{
		this.Opacity = Opacity;
		this.Softness = Softness;
		this.ColorA = ColorA;
		this.ColorB = ColorB;
		this.Contrast = Contrast;
		this.Offset = Offset;
		UpdateAllMaterialParameters();
	}

    UFUNCTION()
	void SetGradient(float Opacity = 1.0f,
	FLinearColor ColorA = FLinearColor(0.428691f, 0.502887f, 0.545725f, 1.0f),
	FLinearColor ColorB = FLinearColor(0.545725f, 0.502887f, 0.428691f, 1.0f),
	float Softness = 1.0f, float Contrast = 1.0f, float Offset = 0.5f)
	{
		ColorType = EColorType::Gradient;
		this.Opacity = Opacity;
		this.Softness = Softness;
		this.ColorA = ColorA;
		this.ColorB = ColorB;
		this.Contrast = Contrast;
		this.Offset = Offset;
		UpdateAllMaterialParameters();
	}
	
    UFUNCTION()
	void SetGradientOverTime(float Time = 2.0f
	float Opacity = 1.0f,
	FLinearColor ColorA = FLinearColor(0.428691f, 0.502887f, 0.545725f, 1.0f),
	FLinearColor ColorB = FLinearColor(0.545725f, 0.502887f, 0.428691f, 1.0f),
	float Softness = 1.0f, float Contrast = 1.0f, float Offset = 0.5f)
	{
		ColorType = EColorType::Gradient;

		CurrentLerpTime = Time;
		TotalLerpTime = Time;
		SetComponentTickEnabled(true);

		BlendOpacity = BlendFloat(this.Opacity, Opacity);
		BlendSoftness = BlendFloat(this.Softness, Softness);
		BlendContrast = BlendFloat(this.Contrast, Contrast);
		BlendOffset = BlendFloat(this.Offset, Offset);
		BlendColorA = BlendColor(this.ColorA, ColorA);
		BlendColorB = BlendColor(this.ColorB, ColorB);
	}
	
    UFUNCTION()
	void SetTemperature(float Opacity = 1.0f, float MinTemperature = 0.0f, float MaxTemperature = 5000.0f, float Softness = 1.0f, float Contrast = 1.0f, float Offset = 0.5f)
	{
		ColorType = EColorType::Temperature;
		this.Opacity = Opacity;
		this.Softness = Softness;
		this.MinTemperature = MinTemperature;
		this.MaxTemperature = MaxTemperature;
		this.Contrast = Contrast;
		this.Offset = Offset;
		UpdateAllMaterialParameters();
	}
	
    UFUNCTION()
	void SetTemperatureOverTime(float Time = 2.0f, float Opacity = 1.0f, float MinTemperature = 0.0f, float MaxTemperature = 5000.0f, float Softness = 1.0f, float Contrast = 1.0f, float Offset = 0.5f)
	{
		ColorType = EColorType::Temperature;

		CurrentLerpTime = Time;
		TotalLerpTime = Time;
		SetComponentTickEnabled(true);

		BlendOpacity = BlendFloat(this.Opacity, Opacity);
		BlendSoftness = BlendFloat(this.Softness, Softness);
		BlendContrast = BlendFloat(this.Contrast, Contrast);
		BlendOffset = BlendFloat(this.Offset, Offset);
		BlendMinTemperature = BlendFloat(this.MinTemperature, MinTemperature);
		BlendMaxTemperature = BlendFloat(this.MaxTemperature, MaxTemperature);
	}


    UFUNCTION()
	void SetColor(float Opacity = 1.0f, float Softness = 1.0f, FLinearColor Color = FLinearColor(0.428691f, 0.502887f, 0.545725f, 1.0f))
	{
		ColorType = EColorType::Color;
		this.Opacity = Opacity;
		this.Softness = Softness;
		this.ColorA = Color;
		UpdateAllMaterialParameters();
	}

    UFUNCTION()
	void SetColorOverTime(float Time = 2.0f, float Opacity = 1.0f, float Softness = 1.0f, FLinearColor Color = FLinearColor(0.428691f, 0.502887f, 0.545725f, 1.0f))
	{
		ColorType = EColorType::Color;
		CurrentLerpTime = Time;
		TotalLerpTime = Time;
		SetComponentTickEnabled(true);

		BlendColorA = BlendColor(this.ColorA, Color);
		BlendOpacity = BlendFloat(this.Opacity, Opacity);
		BlendSoftness = BlendFloat(this.Softness, Softness);
	}
	

    UFUNCTION()
	void SetOpacityValue(float Opacity = 1.0f)
	{
		this.Opacity = Opacity;
		UpdateAllMaterialParameters();
	}

    UFUNCTION()
	void SetOpacityOverTime(float Time = 2.0f, float Opacity = 1.0f)
	{
		CurrentLerpTime = Time;
		TotalLerpTime = Time;
		SetComponentTickEnabled(true);
		BlendOpacity = BlendFloat(this.Opacity, Opacity);
		UpdateAllMaterialParameters();
	}

    UFUNCTION()
	void SetSoftnessValue(float Softness = 1.0f)
	{
		this.Softness = Softness;
		UpdateAllMaterialParameters();
	}

    UFUNCTION()
	void SetSoftnessOverTime(float Time = 2.0f, float Softness = 1.0f)
	{
		CurrentLerpTime = Time;
		TotalLerpTime = Time;
		SetComponentTickEnabled(true);
		BlendSoftness = BlendFloat(this.Softness, Softness);
		UpdateAllMaterialParameters();
	}

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		//float Kill = (Opacity > 0.0f) ? 1.0f : 0.0f;
		//SetCullDistance(Data.ScaleFactor * 1000 * Kill);
		if(CurrentLerpTime > 0)
		{
			CurrentLerpTime -= DeltaTime;
			float NormalizedLerpTime = 1.0f - FMath::Clamp(CurrentLerpTime / TotalLerpTime, 0.0f, 1.0f);
			SetEverything(	BlendOpacity.Blend(NormalizedLerpTime),
							BlendColorA.Blend(NormalizedLerpTime), 
							BlendColorB.Blend(NormalizedLerpTime), 
							BlendSoftness.Blend(NormalizedLerpTime), 
							BlendMinTemperature.Blend(NormalizedLerpTime),
							BlendMaxTemperature.Blend(NormalizedLerpTime),
							BlendContrast.Blend(NormalizedLerpTime),
							BlendOffset.Blend(NormalizedLerpTime)
			);
		}
		else
		{
			SetComponentTickEnabled(false);
		}
    }
}

UCLASS(hidecategories="StaticMesh Materials Physics Collision Lighting Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class AHazeSphere : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent, ShowOnActor)
    UHazeSphereComponent HazeSphereComponent;

    UPROPERTY(Category="DEPRECATED", Meta = (EditCondition="!Upgraded", EditConditionHides))
	bool Never = false;

    UPROPERTY(Category="DEPRECATED", Meta = (EditCondition="!Upgraded", EditConditionHides))
    EFogVolume Type = EFogVolume::Sphere;

    UPROPERTY(Category="DEPRECATED", Meta = (EditCondition="!Upgraded", EditConditionHides))
    FLinearColor Color = FLinearColor(0.428691f, 0.502887f, 0.545725f, 1.0f);
    
    UPROPERTY(Category="DEPRECATED", Meta = (EditCondition="!Upgraded", EditConditionHides))
    float Opacity = 1.0f;
	
    UPROPERTY(Category="DEPRECATED", Meta = (EditCondition="!Upgraded", EditConditionHides))
    float Softness = 1.0f;
    
    UFUNCTION(CallInEditor, Category="Default")
	void UPGRADE()
	{
		if(Upgraded == false)
		{
			HazeSphereComponent.Opacity = FMath::Pow(HazeSphereComponent.Opacity, HazeSphereComponent.Softness*1.5);
			HazeSphereComponent.Opacity = FMath::Sqrt(HazeSphereComponent.Opacity);
		}
		Upgraded = true;
		ConstructionScript();
	}

    UPROPERTY(Category="Default")
    bool Upgraded = false;
    
    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		bool IsDefault = true;
		if(Softness != 1 || Opacity != 1 || Color != FLinearColor(0.428691f, 0.502887f, 0.545725f, 1.0f) || Type != EFogVolume::Sphere)
		{
			IsDefault = false;
		}
		
		if(IsDefault)
		{
			Upgraded = true;
		}

		if(!Upgraded)
		{
			HazeSphereComponent.Type = Type;
			HazeSphereComponent.ColorType = EColorType::Color;
			HazeSphereComponent.ColorA = Color;
			HazeSphereComponent.ColorB = Color;
			HazeSphereComponent.Opacity = Opacity;
			HazeSphereComponent.Softness = Softness;
		}

		HazeSphereComponent.Upgraded = Upgraded;

		HazeSphereComponent.ConstructionScript_Hack();
    }
}