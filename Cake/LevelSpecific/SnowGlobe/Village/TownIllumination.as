import Cake.LevelSpecific.SnowGlobe.SnowFolk.FrozenSnowFolk;
import Cake.LevelSpecific.SnowGlobe.Mountain.ExplodingIce;
import Cake.LevelSpecific.SnowGlobe.SnowFolk.SnowFolkMovementManager;
import Cake.LevelSpecific.SnowGlobe.MinigameReactionSnowFolk.ReactionSnowFolkManager;
import Vino.Movement.Grinding.GrindSpline;

struct FTownIlluminationDynamicMesh
{
	UPROPERTY()
	AActor Actor;
	UPROPERTY()
	UStaticMeshComponent Mesh;
	UPROPERTY(NotVisible, BlueprintReadOnly)
	FLinearColor InitialColor;
	UPROPERTY(NotVisible, BlueprintReadOnly)
	FName ParameterName;

	void SetIntensity(float Value)
	{
		if (Mesh == nullptr)
			return;

		Mesh.SetColorParameterValueOnMaterialIndex(0, ParameterName, InitialColor * Value);
	}
}

struct FTownIlluminationDynamicLight
{
	UPROPERTY()
	ALight Actor;
	UPROPERTY()
	ULightComponent Light;
	UPROPERTY(NotVisible, BlueprintReadOnly)
	float InitialIntensity;

	void SetIntensity(float Value)
	{
		if (Light == nullptr)
			return;

		Light.SetIntensity(InitialIntensity * Value);
	}
}

class ATownIllumination : AHazeActor
{
	default PrimaryActorTick.bStartWithTickEnabled = false;

	const FName PropParameterName = n"Emissive Tint";
	const FName SplineParameterName = n"EmissiveColor";

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent SceneRoot;

	UPROPERTY(DefaultComponent)
	UBillboardComponent Billboard;
	default Billboard.Sprite = Asset("/Game/Editor/EditorBillboards/Godray.Godray");
	default Billboard.bIsEditorOnly = true;
#if EDITOR
	default Billboard.bUseInEditorScaling = true;
#endif

	UPROPERTY(BlueprintReadOnly, Category = "Illumination")
	TArray<FTownIlluminationDynamicMesh> TownProps;

	UPROPERTY(BlueprintReadOnly, Category = "Illumination")
	TArray<FTownIlluminationDynamicLight> TownLights;

	UPROPERTY(BlueprintReadOnly, Category = "Illumination")
	TArray<FTownIlluminationDynamicMesh> TownGrindSplines;

	UPROPERTY(BlueprintReadOnly, Category = "Illumination")
	TArray<AFrozenSnowFolk> TownFrozenFolk;

	UPROPERTY(BlueprintReadOnly, Category = "Illumination")
	TArray<AExplodingIce> TownBreakables;

	UPROPERTY(BlueprintReadOnly, Category = "Illumination")
	TArray<ADeathVolume> TownDeathVolumes;

	UPROPERTY(BlueprintReadOnly, Category = "Illumination")
	TArray<AHazeNiagaraActor> TownNiagaraActors;

	UPROPERTY(BlueprintReadOnly, Category = "Illumination")
	ESnowFolkActivationLevel ActivationLevel;

	UPROPERTY(Category = "Illumination", Meta = (ClampMin = "0.0", ClampMax = "1.0", UIMin = "0.0", UIMax = "1.0"))
	float InitialValue = 0.f;

	UPROPERTY(Category = "Illumination")
	float InterpSpeed = 5.f;

	UFUNCTION(CallInEditor, Category = "Illumination")
	void FindInLevel()
	{
		GetProps(TownProps);
		GetLights(TownLights);
		GetGrindSplines(TownGrindSplines);
		GetFrozenFolk(TownFrozenFolk);
		GetBreakables(TownBreakables);
		GetDeathVolumes(TownDeathVolumes);
		GetNiagaraActors(TownNiagaraActors);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ProcessProps(TownProps);
		ProcessLights(TownLights);
		ProcessGrindSplines(TownGrindSplines);

		DisableDeathVolumes();
		DisableNiagaraEffects();
	}

	UFUNCTION()
	void ComeAliveFinalize()
	{
		SetAllIntensity(1.f);
		DisableFrozenSnowfolk();
		DisableBreakables();
		EnableDeathVolumes();
		EnableNiagaraEffects();

		// Wake up snowfolk for the appropriate level through the managers
		if (ActivationLevel != ESnowFolkActivationLevel::None)
		{
			ActivateSnowFolkWithActivationLevel(n"Town", ActivationLevel);
			ActivateReactionSnowFolkWithActivationLevel(ActivationLevel, true, ActorLocation, 0.6f);
		}

		TownProps.Empty();
		TownLights.Empty();
		TownFrozenFolk.Empty();
		TownGrindSplines.Empty();
		TownBreakables.Empty();
		TownDeathVolumes.Empty();
		TownNiagaraActors.Empty();

		DisableActor(this);
	}

	UFUNCTION()
	void SetAllIntensity(float Value)
	{
		for (auto Prop : TownProps)
			Prop.SetIntensity(Value);
		for (auto Spline : TownGrindSplines)
			Spline.SetIntensity(Value);
		for (auto DynamicLight : TownLights)
			DynamicLight.SetIntensity(Value);
	}

	UFUNCTION()
	void DisableFrozenSnowfolk()
	{
		for (int i = 0; i < TownFrozenFolk.Num(); ++i)
		{
			if (TownFrozenFolk[i] != nullptr && !TownFrozenFolk[i].IsActorDisabled(this))
				TownFrozenFolk[i].DisableActor(this);
		}
	}

	UFUNCTION()
	void DisableBreakables()
	{
		for (int i = 0; i < TownBreakables.Num(); ++i)
		{
			if (TownBreakables[i] != nullptr && !TownBreakables[i].IsActorDisabled(this))
				TownBreakables[i].DisableActor(this);
		}
	}

	UFUNCTION()
	void DisableDeathVolumes()
	{
		for (int i = 0; i < TownDeathVolumes.Num(); ++i)
		{
			if (TownDeathVolumes[i] != nullptr && TownDeathVolumes[i].bEnabled)
				TownDeathVolumes[i].DisableDeathVolume();
		}
	}

	UFUNCTION()
	void DisableNiagaraEffects()
	{
		for (int i = 0; i < TownNiagaraActors.Num(); ++i)
		{
			if (TownNiagaraActors[i] != nullptr && !TownNiagaraActors[i].IsActorDisabled(this))
			{
				// Turns out the NiagaraComponent does an bAutoActivate check in tick to activate itself
				// so we can't just deactivate it
				TownNiagaraActors[i].DisableActor(this);
			}
		}
	}

	UFUNCTION()
	void EnableFrozenSnowfolk()
	{
		for (int i = 0; i < TownFrozenFolk.Num(); ++i)
		{
			if (TownFrozenFolk[i] != nullptr && TownFrozenFolk[i].IsActorDisabled(this))
				TownFrozenFolk[i].EnableActor(this);
		}
	}

	UFUNCTION()
	void EnableBreakables()
	{
		for (int i = 0; i < TownBreakables.Num(); ++i)
		{
			if (TownBreakables[i] != nullptr && TownBreakables[i].IsActorDisabled(this))
				TownBreakables[i].EnableActor(this);
		}
	}

	UFUNCTION()
	void EnableDeathVolumes()
	{
		for (int i = 0; i < TownDeathVolumes.Num(); ++i)
		{
			if (TownDeathVolumes[i] != nullptr && !TownDeathVolumes[i].bEnabled)
				TownDeathVolumes[i].EnableDeathVolume();
		}
	}

	UFUNCTION()
	void EnableNiagaraEffects()
	{
		for (int i = 0; i < TownNiagaraActors.Num(); ++i)
		{
			if (TownNiagaraActors[i] != nullptr && TownNiagaraActors[i].IsActorDisabled(this))
				TownNiagaraActors[i].EnableActor(this);
		}
	}

	private void GetProps(TArray<FTownIlluminationDynamicMesh>& PropArray)
	{
		PropArray.Empty();

		TArray<AHazeProp> Props;
		GetAllActorsOfClass(Props);

		for (int i = 0; i < Props.Num(); ++i)
		{
			AHazeProp Prop = Props[i];

			if (Prop.Level != Level)
				continue;

			FTownIlluminationDynamicMesh DynamicMesh;
			DynamicMesh.Actor = Prop;
			PropArray.Add(DynamicMesh);
		}
	}

	private void GetLights(TArray<FTownIlluminationDynamicLight>& LightArray)
	{
		LightArray.Empty();

		TArray<ALight> Lights;
		GetAllActorsOfClass(Lights);

		for (int i = 0; i < Lights.Num(); ++i)
		{
			ALight Light = Lights[i];

			if (Light.Level != Level)
				continue;

			FTownIlluminationDynamicLight DynamicLight;
			DynamicLight.Actor = Light;
			LightArray.Add(DynamicLight);
		}
	}

	private void GetGrindSplines(TArray<FTownIlluminationDynamicMesh>& GrindSplineArray)
	{
		GrindSplineArray.Empty();

		TArray<AGrindspline> GrindSplines;
		GetAllActorsOfClass(GrindSplines);

		for (int i = 0; i < GrindSplines.Num(); ++i)
		{
			AGrindspline Spline = GrindSplines[i];

			if (Spline.Level != Level)
				continue;

			FTownIlluminationDynamicMesh DynamicMesh;
			DynamicMesh.Actor = Spline;
			GrindSplineArray.Add(DynamicMesh);
		}
	}

	private void GetFrozenFolk(TArray<AFrozenSnowFolk>& FrozenFolkArray)
	{
		FrozenFolkArray.Empty();
		GetAllActorsOfClass(FrozenFolkArray);

		for (int i = FrozenFolkArray.Num() - 1; i >= 0; --i)
		{
			if (FrozenFolkArray[i].Level != Level)
				FrozenFolkArray.RemoveAt(i);
		}
	}

	private void GetBreakables(TArray<AExplodingIce>& BreakableArray)
	{
		BreakableArray.Empty();
		GetAllActorsOfClass(BreakableArray);

		for (int i = BreakableArray.Num() - 1; i >= 0; --i)
		{
			if (BreakableArray[i].Level != Level)
				BreakableArray.RemoveAt(i);
		}
	}

	private void GetDeathVolumes(TArray<ADeathVolume>& DeathVolumeArray)
	{
		DeathVolumeArray.Empty();
		GetAllActorsOfClass(DeathVolumeArray);

		for (int i = DeathVolumeArray.Num() - 1; i >= 0; --i)
		{
			if (DeathVolumeArray[i].Level != Level)
				DeathVolumeArray.RemoveAt(i);
		}
	}

	private void GetNiagaraActors(TArray<AHazeNiagaraActor>& NiagaraArray)
	{
		NiagaraArray.Empty();
		GetAllActorsOfClass(NiagaraArray);

		for (int i = NiagaraArray.Num() - 1; i >= 0; --i)
		{
			if (NiagaraArray[i].Level != Level)
				NiagaraArray.RemoveAt(i);
		}
	}

	private void ProcessProps(TArray<FTownIlluminationDynamicMesh>& PropArray)
	{
		for (int i = PropArray.Num() - 1; i >= 0; --i)
		{
			FTownIlluminationDynamicMesh& Prop = PropArray[i];

			if (Prop.Actor == nullptr)
			{
				PropArray.RemoveAt(i);
				continue;
			}

			// Get and store mesh, used to access material properties
			Prop.Mesh = UStaticMeshComponent::Get(Prop.Actor);

			if (Prop.Mesh == nullptr)
			{
				PropArray.RemoveAt(i);
				continue;
			}

			// Create dynamic material from original material
			UMaterialInterface Source = Prop.Mesh.Materials[0];
			UMaterialInstanceDynamic Dynamic = Prop.Mesh.CreateDynamicMaterialInstance(0, Source);

			// Try to find the correct parameter name for this prop
			FName ParameterName = (Dynamic.GetVectorParameterValue(PropParameterName) != FLinearColor::Black) ? 
				PropParameterName : SplineParameterName;

			// Store initial color and scale with our initial value
			Prop.ParameterName = ParameterName;
			Prop.InitialColor = Dynamic.GetVectorParameterValue(ParameterName);
			Prop.SetIntensity(InitialValue);
		}
	}

	private void ProcessLights(TArray<FTownIlluminationDynamicLight>& LightArray)
	{
		for (int i = LightArray.Num() - 1; i >= 0; --i)
		{
			FTownIlluminationDynamicLight& DynamicLight = LightArray[i];

			if (DynamicLight.Actor == nullptr || DynamicLight.Actor.LightComponent == nullptr)
			{
				LightArray.RemoveAt(i);
				continue;
			}

			// Store initial intensity and scale with our initial value
			DynamicLight.Light = DynamicLight.Actor.LightComponent;
			DynamicLight.InitialIntensity = DynamicLight.Light.Intensity;
			DynamicLight.SetIntensity(InitialValue);
		}
	}

	private void ProcessGrindSplines(TArray<FTownIlluminationDynamicMesh>& GrindSplineArray)
	{
		for (int i = GrindSplineArray.Num() - 1; i >= 0; --i)
		{
			FTownIlluminationDynamicMesh& Spline = GrindSplineArray[i];

			if (Spline.Actor == nullptr)
			{
				GrindSplineArray.RemoveAt(i);
				continue;
			}

			// Get and store (any) mesh, used to access material properties
			// all meshes share dynamic material, so we only need to reference one
			Spline.Mesh = UStaticMeshComponent::Get(Spline.Actor);

			if (Spline.Mesh == nullptr)
			{
				GrindSplineArray.RemoveAt(i);
				continue;
			}
			
			// Create dynamic material from first instance if any
			UMaterialInstanceDynamic Dynamic = Spline.Mesh.CreateDynamicMaterialInstance(0);

			// Apply the dynamic material to the rest of the components
			TArray<UStaticMeshComponent> Meshes;
			Spline.Mesh.Owner.GetComponentsByClass(Meshes);
			for (auto Mesh : Meshes)
				Mesh.SetMaterial(0, Dynamic);

			// Store material and original tint, then apply initial tint
			Spline.ParameterName = SplineParameterName;
			Spline.InitialColor = Dynamic.GetVectorParameterValue(Spline.ParameterName);
			Spline.SetIntensity(InitialValue);
		}
	}

	bool bDevHasComeAlive = false;
	UFUNCTION(DevFunction)
	private void DevToggleComeAlive()
	{
		if (!bDevHasComeAlive)
		{
			SetAllIntensity(1.f);
			DisableFrozenSnowfolk();
			DisableBreakables();
			EnableDeathVolumes();
			EnableNiagaraEffects();

			// Wake up snowfolk for the appropriate level
			if (ActivationLevel != ESnowFolkActivationLevel::None)
			{
				ActivateSnowFolkWithActivationLevel(n"Town", ActivationLevel);
				ActivateReactionSnowFolkWithActivationLevel(ActivationLevel, true, ActorLocation, 0.6f);
			}
		}
		else
		{
			SetAllIntensity(0.f);
			EnableFrozenSnowfolk();
			EnableBreakables();
			DisableDeathVolumes();
			DisableNiagaraEffects();
		}

		bDevHasComeAlive = !bDevHasComeAlive;
	}
}