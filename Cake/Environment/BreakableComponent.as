import Cake.LevelSpecific.SnowGlobe.Mountain.TriggerableFX;

enum EBreakableType
{
    Pop,
    Explodable,
    BakedPhysics
};

struct FBreakableHitData
{
	UPROPERTY()
	FVector HitLocation = FVector(0,0,0);

	UPROPERTY()
	FVector DirectionalForce = FVector(0,0,0);

	UPROPERTY()
	float ScatterForce = 0.0f;

	UPROPERTY()
	int NumberOfHits = 1;
}

class UDataAssetBreakable : UDataAsset
{
	// Global
    UPROPERTY(Category="Global")
	EBreakableType Type;

    UPROPERTY(Category="All")
    UNiagaraSystem BreakParticle;

    UPROPERTY(Category="All")
    UNiagaraSystem HitParticle;


	UPROPERTY(Category = "All")
	UAkAudioEvent BreakAudioEvent;

	UPROPERTY(Category = "All")
	UAkAudioEvent HitAudioEvent;

    UPROPERTY(Category="All")
    int HitsToDestroy = 2;
	
    UPROPERTY(Category="All")
    UStaticMesh Mesh;


	// Explodable
    UPROPERTY(Category="Explodable", Meta = (EditCondition="Type == EBreakableType::Explodable", EditConditionHides))
    float ChunkMass = 1.0f;

    UPROPERTY(Category="Explodable", Meta = (EditCondition="Type == EBreakableType::Explodable", EditConditionHides))
    float ChunkRotaitonMultiplier = 1.0f;

    UPROPERTY(Category="Explodable", Meta = (EditCondition="Type == EBreakableType::Explodable", EditConditionHides))
    float ChunkFadeTime = 2.0f;

	// Optional mesh to swap to for the actual "exploding" animaiton.
    UPROPERTY(Category="Explodable", Meta = (EditCondition="Type == EBreakableType::Explodable", EditConditionHides))
    UStaticMesh OptionalExplodableMesh;
	

	// BakedPhysics
    UPROPERTY(Category="BakedPhysics", Meta = (EditCondition="Type == EBreakableType::BakedPhysics", EditConditionHides))
    USkeletalMesh BakedPhysicsMesh;
	
    UPROPERTY(Category="BakedPhysics", Meta = (EditCondition="Type == EBreakableType::BakedPhysics",  EditConditionHides))
    UAnimSequence BakedPhysicsAnimation;

    UPROPERTY(Category="BakedPhysics", Meta = (EditCondition="Type == EBreakableType::BakedPhysics",  EditConditionHides))
	FRotator AnimationRotationOffset = FRotator(90, 90, 0);
	
    UPROPERTY(Category="BakedPhysics", Meta = (EditCondition="Type == EBreakableType::BakedPhysics", EditConditionHides))
    UStaticMesh FinalMesh;
}

UCLASS(hidecategories="Physics Rendering Physics Activation Cooking Replication Input Actor HLOD Mobile AssetUserData")
class UBreakableComponent : UStaticMeshComponent
{
    UPROPERTY(NotVisible)
	float PreviewTime = 0.0f;

    UPROPERTY(Category="Breakable")
	float DefaultScatterForce = 8.0f;
	
    UPROPERTY(Category="Breakable", meta = (MakeEditWidget))
	FVector DefaultHitLocation;
	
    UPROPERTY(Category="Breakable")
	FVector DefaultDirectionalForce;

    UPROPERTY(NotVisible)
	bool Previewing = false;

    UPROPERTY(NotVisible)
	bool LastPreviewing = false;

    UPROPERTY(NotVisible)
	UMaterialInterface OriginalMaterial;
    
	UPROPERTY(NotVisible)
	UMaterialInstanceDynamic DynamicExplodableMaterial;
	
	default bTickInEditor = true;
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	
#if EDITOR
	UFUNCTION(CallInEditor, Category = "Breakable")
    void PreviewBreakable()
    {
		SetComponentTickEnabled(true);
		MainMesh = this;
		PreviewTime = 0.0f;
		if(!Previewing)
		{
			for(ATriggerableFX a : GetAllTriggerableEffects(Owner))
			{
				a.PreviewFX();
			}

			DynamicExplodableMaterial = Material::CreateDynamicMaterialInstance(ExplodableMaterial);
			OriginalMaterial = this.GetMaterial(0);
			this.SetMaterial(0, DynamicExplodableMaterial);
		}
	}

	void DonePreviewing()
	{
		this.SetMaterial(0, OriginalMaterial);
		SetComponentTickEnabled(false);
	}

	void DoPreview(float DeltaTime)
	{
		Previewing = PreviewTime < 2.0f;
		if(LastPreviewing != Previewing)
		{
			LastPreviewing = Previewing;
			if(!Previewing)
			{
				DonePreviewing();
			}
		}
		if(Previewing)
		{
			PreviewTime += DeltaTime;
		}

		if(Previewing && DynamicExplodableMaterial != nullptr)
		{
			DynamicExplodableMaterial.SetScalarParameterValue(n"Time", PreviewTime);
			FBreakableHitData d;
			d.HitLocation = DefaultHitLocation;
			d.ScatterForce = DefaultScatterForce;
			d.DirectionalForce = DefaultDirectionalForce;
			d.HitLocation = Owner.GetActorTransform().TransformPosition(d.HitLocation);
			SetExplodableParametersFromStruct(DynamicExplodableMaterial, d, BreakablePreset);
		}
	}
#endif

    UPROPERTY(Category = "Breakable")
	UDataAssetBreakable BreakablePreset = Asset("/Game/Blueprints/Environment/Breakable/Test_Explodable.Test_Explodable");

    UPROPERTY(Category = "Breakable")
	bool GroundCollision = true;

    UPROPERTY(Category = "Breakable")
	float GroundCollisionOffset = 0;

    UPROPERTY(Category = "Breakable")
	bool IsOnWater = false;

    UPROPERTY(NotVisible)
	EBreakableType Type;

    UPROPERTY(NotVisible)
	int CurrentHealth = -1;

    UPROPERTY(NotVisible)
	bool Broken = false;

    UPROPERTY(NotVisible)
	UStaticMeshComponent MainMesh;

    UPROPERTY(NotVisible)
	UHazeSkeletalMeshComponentBase BakedPhysicsMesh;

    UPROPERTY(NotVisible)
	UStaticMeshComponent FinalMesh;

    UPROPERTY(NotVisible)
	float ExplosionTime = 0;

    UPROPERTY()
	float CullDistanceMultiplier = 1.0f;
	
    UPROPERTY(NotVisible)
	bool BreakablePresetIsValid = false;
	
	UPROPERTY(Category = "Breakable", AdvancedDisplay)
	UMaterial BaseTranslucentMaterial = Asset("/Game/MasterMaterials/MasterMaterials/Master_Env_Glass.Master_Env_Glass");

	UPROPERTY(Category = "Breakable", AdvancedDisplay)
	UMaterial BaseTilerMaterial = Asset("/Game/MasterMaterials/MasterMaterials/Master_Env_Tiler.Master_Env_Tiler");

	UPROPERTY(Category = "Breakable", AdvancedDisplay)
    UMaterial ExplodableMaterial = Asset("/Game/Blueprints/LevelSpecific/Tree/Materials/Explodable.Explodable");

	UPROPERTY(Category = "Breakable", AdvancedDisplay)
    UMaterial ExplodableMaterialTranslucent = Asset("/Game/Blueprints/LevelSpecific/Tree/Materials/Explodable_Glass.Explodable_Glass");

	UPROPERTY(Category = "Breakable", AdvancedDisplay)
	UMaterial ExplodableMaterialTiler = Asset("/Game/Blueprints/LevelSpecific/Tree/Materials/Explodable_Tiler.Explodable_Tiler");

    TArray<UMaterialInstanceDynamic> ExplodableDynamicMaterials;

    UPROPERTY(NotVisible)
    UBillboardComponent Bill;

	UPROPERTY(Category = "Breakable", AdvancedDisplay)
	UTexture2D BadBlueprintTexture = Asset("/Engine/EditorResources/BadBlueprintSprite.BadBlueprintSprite");

	UPROPERTY(Category = "Breakable")
	bool DetachOnBreak = false;

	// Helper function to hide & disable collision.
	void SetComponentEnabled(UPrimitiveComponent Component, bool bEnalbed)
	{
		if(Component == nullptr)
			return;
		Component.SetVisibility(bEnalbed);
		Component.SetCollisionEnabled(bEnalbed ? ECollisionEnabled::QueryAndPhysics : ECollisionEnabled::NoCollision);
	}

	bool CheckIfBreakablePresetIsValid(UDataAssetBreakable DataAsset)
	{
		if(DataAsset == nullptr)
			return false;

		Type = BreakablePreset.Type;

		switch(DataAsset.Type)
		{
			case EBreakableType::Pop:
			{
				if(DataAsset.Mesh == nullptr)
					return false;
			}
			break;
			case EBreakableType::Explodable:
			{
				if(DataAsset.Mesh == nullptr)
					return false;
			}
			break;
			case EBreakableType::BakedPhysics:
			{
				//if(DataAsset.Mesh == nullptr)
				//	return false;
				if(DataAsset.BakedPhysicsMesh == nullptr)
					return false;
				if(DataAsset.BakedPhysicsAnimation == nullptr)
					return false;
				//if(DataAsset.FinalMesh == nullptr)
				//	return false;
			}
			break;
			default:
			{
				return false;
			}
		}
		return true;
	}
	
	UFUNCTION(CallInEditor, Category = "Breakable")
    void ConstructionScript_Hack()
    {
		BreakablePresetIsValid = CheckIfBreakablePresetIsValid(BreakablePreset);

		if(!BreakablePresetIsValid)
		{
			SetStaticMesh(nullptr);
			Bill = UBillboardComponent::Create(this.Owner);
			Bill.SetSprite(BadBlueprintTexture);
			Bill.ScreenSize = 0.01f;
			return;
		}

		SetStaticMesh(BreakablePreset.Mesh);
		SetComponentEnabled(this, true);
		SetCullingDistance();
    }

	void SetCullingDistance()
	{
		float dist = Editor::GetDefaultCullingDistance(this) * CullDistanceMultiplier;
		this.SetCullDistance(dist);
		if(MainMesh != nullptr)
			MainMesh.SetCullDistance(dist);
		if(BakedPhysicsMesh != nullptr)
			BakedPhysicsMesh.SetCullDistance(dist);
		if(FinalMesh != nullptr)
			FinalMesh.SetCullDistance(dist);
	}
    
   	UFUNCTION()
	void Init()
	{
		ConstructionScript_Hack();
		
		BreakablePresetIsValid = CheckIfBreakablePresetIsValid(BreakablePreset);
		
		if(!BreakablePresetIsValid)
			return;

		//if(BreakablePreset.OptionalExplodableMesh == nullptr)
		//{
		//	// Reset materials.
		//}

		Broken = false;
		ExplosionTime = 0;
		CurrentHealth = BreakablePreset.HitsToDestroy;

		switch(Type)
		{
			case EBreakableType::Pop:
			{
				MainMesh = this;
				SetComponentEnabled(MainMesh, true);
			}
			break;
			case EBreakableType::Explodable:
			{
				if(BreakablePreset.OptionalExplodableMesh != nullptr)
				{
					if(MainMesh == nullptr)
						MainMesh = UStaticMeshComponent::Create(this.Owner);
					MainMesh.CastShadow = this.CastShadow;
					MainMesh.CollisionEnabled = this.CollisionEnabled;
					MainMesh.CollisionProfileName = this.CollisionProfileName;
					MainMesh.SetRelativeTransform(this.GetRelativeTransform());
					
					this.SetStaticMesh(BreakablePreset.Mesh);
					MainMesh.SetStaticMesh(BreakablePreset.OptionalExplodableMesh);
					
					SetComponentEnabled(MainMesh, false);
					SetComponentEnabled(this, true);
				}
				else
				{
					MainMesh = this;
					SetComponentEnabled(MainMesh, true);
				}

			}
			break;
			case EBreakableType::BakedPhysics:
			{
				MainMesh = this;
				SetComponentEnabled(MainMesh, true);

				if(BakedPhysicsMesh == nullptr)
					BakedPhysicsMesh = UHazeSkeletalMeshComponentBase::Create(this.Owner);
				BakedPhysicsMesh.CastShadow = this.CastShadow;
				BakedPhysicsMesh.CollisionEnabled = this.CollisionEnabled;
				BakedPhysicsMesh.CollisionProfileName = this.CollisionProfileName;
				MainMesh.SetRelativeTransform(this.GetRelativeTransform());
					
				BakedPhysicsMesh.SetSkeletalMesh(BreakablePreset.BakedPhysicsMesh);
				BakedPhysicsMesh.SetRelativeRotation(BreakablePreset.AnimationRotationOffset);
				
				if(FinalMesh == nullptr)
					FinalMesh = UStaticMeshComponent::Create(this.Owner);
				FinalMesh.CastShadow = this.CastShadow;
				FinalMesh.CollisionEnabled = this.CollisionEnabled;
				FinalMesh.CollisionProfileName = this.CollisionProfileName;
				FinalMesh.SetRelativeTransform(this.GetRelativeTransform());
				
				FinalMesh.SetStaticMesh(BreakablePreset.FinalMesh);
				
				SetComponentEnabled(MainMesh, true);
				SetComponentEnabled(BakedPhysicsMesh, false);
				SetComponentEnabled(FinalMesh, false);
			}
			break;
		}
		
		for (int i = 0; i < MainMesh.Materials.Num(); i++)
		{
			MainMesh.SetMaterial(i, MainMesh.StaticMesh.GetMaterial(i));
		}
		SetCullingDistance();
	}
	
   	UFUNCTION(Category="Breakable", CallInEditor)
	void Reset()
	{
		Init();
	}
	
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		Init();
    }

	UFUNCTION()
	void Hit(FBreakableHitData HitData)
	{
		if(!BreakablePresetIsValid)
			return;

		if(Broken)
			return;

		if(BreakablePreset.HitParticle != nullptr)
			Niagara::SpawnSystemAtLocation(BreakablePreset.HitParticle, HitData.HitLocation);

		if(BreakablePreset.HitAudioEvent != nullptr)
			UHazeAkComponent::HazePostEventFireForget(BreakablePreset.HitAudioEvent, MainMesh.GetWorldTransform());

		CurrentHealth -= HitData.NumberOfHits;
		if(CurrentHealth <= 0)
		{
			Break(HitData);
		}
	}

	FVector MoveTowards(FVector Current, FVector Target, float StepSize)
    {
		FVector Delta = Target - Current;
		float Distance = Delta.Size();
		float ClampedDistance = FMath::Min(Distance, StepSize);
		FVector Direction = Delta / Distance;
        return Current + Direction * ClampedDistance;
    }

	UFUNCTION()
	void SetBreakTime(float Time)
	{

	}

	UFUNCTION(Category="Breakable", CallInEditor)
	void BreakWithDefaultBlutility()
	{
		FBreakableHitData NewHitData;
		NewHitData.DirectionalForce = DefaultDirectionalForce;
		NewHitData.HitLocation = DefaultHitLocation;
		NewHitData.ScatterForce = DefaultScatterForce;
		NewHitData.HitLocation = Owner.GetActorTransform().TransformPosition(NewHitData.HitLocation);
		Break(NewHitData);
	}

	UFUNCTION()
	void BreakWithDefault(FBreakableHitData HitData)
	{
		FBreakableHitData NewHitData = HitData;
		NewHitData.DirectionalForce = DefaultDirectionalForce;
		NewHitData.HitLocation = DefaultHitLocation;
		NewHitData.ScatterForce = DefaultScatterForce;
		NewHitData.HitLocation = Owner.GetActorTransform().TransformPosition(NewHitData.HitLocation);
		Break(NewHitData);
	}

	UFUNCTION()
	void Break(FBreakableHitData HitData)
	{
		if(!BreakablePresetIsValid)
			return;

		if(Broken)
			return;
		
		SetComponentTickEnabled(true);

		FBreakableHitData NewHitData;

		bool UseDefault = false;
		if(HitData.HitLocation == FVector::ZeroVector && HitData.DirectionalForce == FVector::ZeroVector && HitData.ScatterForce == 0.0f)
		{
			UseDefault = true;
		}

		NewHitData.DirectionalForce = HitData.DirectionalForce;
		NewHitData.HitLocation = HitData.HitLocation;
		NewHitData.ScatterForce = HitData.ScatterForce;

		if(UseDefault)
		{
			NewHitData.DirectionalForce = DefaultDirectionalForce;
			NewHitData.HitLocation = DefaultHitLocation;
			NewHitData.ScatterForce = DefaultScatterForce;
			NewHitData.HitLocation = Owner.GetActorTransform().TransformPosition(NewHitData.HitLocation);
		}

		Broken = true;
		CurrentHealth = 0;

		for(ATriggerableFX a : GetAllTriggerableEffects(Owner))
		{
			a.TriggerFX();
		}

		if(BreakablePreset.BreakParticle != nullptr)
			Niagara::SpawnSystemAtLocation(BreakablePreset.BreakParticle, MainMesh.GetWorldLocation());

		if(BreakablePreset.BreakAudioEvent != nullptr)
			UHazeAkComponent::HazePostEventFireForget(BreakablePreset.BreakAudioEvent, MainMesh.GetWorldTransform());

		switch(BreakablePreset.Type)
		{
			case EBreakableType::Pop:
			{
				SetComponentEnabled(MainMesh, false);
			}
			break;
			case EBreakableType::Explodable:
			{
				SetComponentEnabled(MainMesh, true);
				if(BreakablePreset.OptionalExplodableMesh != nullptr)
				{
					SetComponentEnabled(this, false);
				}
				MainMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				
				if(DetachOnBreak)
				{
					MainMesh.DetachFromParent(true);
					this.DetachFromParent(true);
				}

				ExplodableDynamicMaterials.Empty();
				
				for(int i = 0; i < MainMesh.GetNumMaterials(); i++)
            	{
					// Swap to simulation material
					bool IsTranslucent = (MainMesh.GetMaterial(i).GetBaseMaterial() == BaseTranslucentMaterial);
					bool IsTiler = (MainMesh.GetMaterial(i).GetBaseMaterial() == BaseTilerMaterial);
					UMaterialInstanceDynamic NewMaterial;
					if(IsTiler)
						NewMaterial = Material::CreateDynamicMaterialInstance(ExplodableMaterialTiler);
					else
						NewMaterial = Material::CreateDynamicMaterialInstance(IsTranslucent ? ExplodableMaterialTranslucent : ExplodableMaterial);
					
					ExplodableDynamicMaterials.Add(NewMaterial); // still add it even if nullptr to maintain same array size
					
					if(NewMaterial == nullptr) // Not sure why this becomes null, but sometimes in networked it does.
						continue;
					
					UMaterialInstance OldMaterial = Cast<UMaterialInstance>(this.GetMaterial(i));

					// If it's a dynamic material instance, grab its parent.
					if(Cast<UMaterialInstanceDynamic>(OldMaterial) != nullptr)
					{
						auto ParentMat = Cast<UMaterialInstance>(this.GetMaterial(i)).Parent;
						OldMaterial = Cast<UMaterialInstance>(ParentMat);
					}

					MainMesh.SetMaterial(i, NewMaterial);

					if(OldMaterial != nullptr)
					{
						CopyMaterialParameters(OldMaterial, NewMaterial);
					}

					SetExplodableParametersFromStruct(NewMaterial, NewHitData, BreakablePreset);
				}
				MainMesh.SetRelativeTransform(this.GetRelativeTransform());

				ExplosionTime = 0;
			}
			break;
			case EBreakableType::BakedPhysics:
			{
				FHazePlaySlotAnimationParams a = FHazePlaySlotAnimationParams();
				a.Animation = BreakablePreset.BakedPhysicsAnimation;
				a.bLoop = false;
				a.BlendTime = 0;

				FHazeAnimationDelegate OnBlendingIn;
				FHazeAnimationDelegate OnBlendingOut;
				OnBlendingOut.BindUFunction(this, n"AnimationFinished");
				BakedPhysicsMesh.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, a);
				
				SetComponentEnabled(MainMesh, false);
				SetComponentEnabled(BakedPhysicsMesh, true);
				SetComponentEnabled(FinalMesh, false);
			}
			break;
		}
		SetCullingDistance();
	}

	void CopyMaterialParameters(UMaterialInstance OldMaterial, UMaterialInstanceDynamic NewMaterial)
	{
		// Get original parameters
		auto ScalarParameters = OldMaterial.ScalarParameterValues;
		auto VectorParameters = OldMaterial.VectorParameterValues;
		auto TextureParameters = OldMaterial.TextureParameterValues;
		
		// Apply parameters to new materials.
		for(int j = 0; j < ScalarParameters.Num(); j++)
		{
			NewMaterial.SetScalarParameterValue(ScalarParameters[j].ParameterInfo.Name, ScalarParameters[j].ParameterValue);
		}
		for(int j = 0; j < VectorParameters.Num(); j++)
		{
			NewMaterial.SetVectorParameterValue(VectorParameters[j].ParameterInfo.Name, VectorParameters[j].ParameterValue);
			if(VectorParameters[j].ParameterInfo.Name == n"AlbedoColor")
			{
				FLinearColor NewColor = FLinearColor(
					FMath::Pow(VectorParameters[j].ParameterValue.R, 2.2f) / 2.0f,
					FMath::Pow(VectorParameters[j].ParameterValue.G, 2.2f) / 2.0f,
					FMath::Pow(VectorParameters[j].ParameterValue.B, 2.2f) / 2.0f,
					FMath::Pow(VectorParameters[j].ParameterValue.A, 2.2f) / 2.0f);
				NewMaterial.SetVectorParameterValue(n"BaseColor Tint", NewColor);
			}
		}
		for(int j = 0; j < TextureParameters.Num(); j++)
		{
			NewMaterial.SetTextureParameterValue(TextureParameters[j].ParameterInfo.Name, TextureParameters[j].ParameterValue);
		}
	}

	void SetExplodableParametersFromStruct(UMaterialInstanceDynamic Material, FBreakableHitData HitData, UDataAssetBreakable Preset)
	{
		// If the provided HitLocation is outside of the objects radius we move it to the surface of the radius.
		FVector Origin; FVector Bounds; float Radius = 0;
		System::GetComponentBounds(this, Origin, Bounds, Radius);
		FVector ProjectedHitLocation = MoveTowards(Origin, HitData.HitLocation, Radius);
		ProjectedHitLocation = HitData.HitLocation;
		// Number to scale force with so that the input 1 feels like a good default.
		float StrengthConvenienceMultiplier = 10000.0f;
		
		StrengthConvenienceMultiplier /= Preset.ChunkMass;

		Material.SetVectorParameterValue(n"HitLocation", FLinearColor(ProjectedHitLocation.X, ProjectedHitLocation.Y, ProjectedHitLocation.Z, 0.0f));
		Material.SetVectorParameterValue(n"DirectionalForce", FLinearColor(HitData.DirectionalForce.X, HitData.DirectionalForce.Y, HitData.DirectionalForce.Z, 0.0f) * StrengthConvenienceMultiplier);
		Material.SetScalarParameterValue(n"Radius", Radius * 2.0f);
		Material.SetScalarParameterValue(n"ScatterForce", HitData.ScatterForce * StrengthConvenienceMultiplier);
		
		
		Material.SetScalarParameterValue(n"PlaneHeight", GroundCollision ? (this.GetWorldLocation().Z + GroundCollisionOffset) : -292999.0f);
		Material.SetScalarParameterValue(n"IsOnWater", IsOnWater ? 1.0f : 0.0f);
		Material.SetScalarParameterValue(n"RotationForce", Preset.ChunkRotaitonMultiplier);
		Material.SetScalarParameterValue(n"FadeTime", Preset.ChunkFadeTime * 0.25f);
	}

	UFUNCTION()
	void AnimationFinished()
	{
		if(Broken)
		{
			SetComponentEnabled(MainMesh, false);
			SetComponentEnabled(BakedPhysicsMesh, false);
			SetComponentEnabled(FinalMesh, true);
		}
	}
	
    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		
	#if EDITOR
			if(!GetWorld().IsGameWorld())
			{
				DoPreview(DeltaTime);
				return;
			}
	#endif
		if(!BreakablePresetIsValid)
			return;

		switch(BreakablePreset.Type)
		{
			case EBreakableType::Pop:
			{
				
			}
			break;
			case EBreakableType::Explodable:
			{
				if(Broken)
				{
					ExplosionTime += DeltaTime;
					for(int i = 0; i < MainMesh.GetNumMaterials(); i++)
					{
						if(ExplodableDynamicMaterials.Num() <= i)
							break;
							
						if(ExplodableDynamicMaterials[i] == nullptr)
							break;
							
						ExplodableDynamicMaterials[i].SetScalarParameterValue(n"Time", ExplosionTime*0.5f);
					}
					if(ExplosionTime > BreakablePreset.ChunkFadeTime || ExplosionTime < 0.0f)
					{
						SetComponentEnabled(MainMesh, false);
						SetComponentTickEnabled(false);
					}
				}
			}
			break;
			case EBreakableType::BakedPhysics:
			{

			}
			break;
		}
    }
}