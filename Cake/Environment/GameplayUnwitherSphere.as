import Cake.LevelSpecific.SnowGlobe.Mountain.TriggerableFX;
import Rice.Props.PropBaseActor;
import Cake.Environment.GreenhouseBossGrowingThorns;
import Cake.LevelSpecific.Garden.Greenhouse.RootCluster.UnwitherBulbSpike;

class UDataAssetGameplayUnwitherSoundEvents : UDataAsset
{
	UPROPERTY()
	UAkAudioEvent AmbientSoundEvent;

	UPROPERTY()
	UAkAudioEvent WitherSoundEvent;

	UPROPERTY()
	UAkAudioEvent UnwitherSoundEvent;
}

struct FActorArray
{
	UPROPERTY()
	UMaterialInterface Mat;

	UPROPERTY()
	int MatIndex;

	UPROPERTY()
	UMaterialInstanceDynamic DynamicMat;

	UPROPERTY()
	TArray<AActor> Data;

	UPROPERTY()
	TArray<ECollisionEnabled> CollisionProfile;
}

class AGameplayUnwitherBase : AHazeActor // BP_GameplayUnwither, because renaming things in AS is scary.
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent)
    UBillboardComponent Billboard;
	default Billboard.Sprite = Asset("/Game/Editor/EditorBillboards/Godray.Godray");
	default Billboard.bIsEditorOnly = true;
#if EDITOR
	default Billboard.bUseInEditorScaling = true;
#endif

    UPROPERTY(DefaultComponent)
    USphereComponent Sphere;
	default Sphere.CollisionProfileName = n"NoCollision";
	default Sphere.SphereRadius = 1;
	
	UPROPERTY()
	TArray<AActor> HandPickedActors;

	UPROPERTY()
	bool StartWithered = false;
	
	// By default collision disables when the object is withered. By checking this bool the opposite happens, withered = collision enabled, unwithered = collision disabled
	UPROPERTY()
	bool FlipCollision = false;

	UPROPERTY()
	float Radius = 2000;
	
	UPROPERTY()
	float BlendTargetValue = 0;
	
	UPROPERTY()
	float MaxBlendSpeed = 1.0f;

	UPROPERTY()
	float BlendSpeed = 8.0f;
	
    UPROPERTY()
	UDataAssetGameplayUnwitherSoundEvents SoundEvent;

	UPROPERTY(Category="DO NOT TOUCH")
	UHazeAkComponent AmbientWitherNoises;

	UPROPERTY(Category="DO NOT TOUCH")
	TArray<AGreenhouseBossGrowingThorns> GrabbedWitherableThorns; // If we need to, this can be made in to an interface with Wither/Unwither functions.

	UPROPERTY(Category="DO NOT TOUCH")
	TArray<AUnwitherBulbSpike> GrabbedWitherableSpikes; // These use delays to start unwithering at different times

	UPROPERTY(Category="DO NOT TOUCH")
	TArray<UMaterial> EnvWitherBaseMaterials;
	
	UPROPERTY(Category="DO NOT TOUCH")
	float BlendTarget = 0;

	UPROPERTY(Category="DO NOT TOUCH")
	float BlendValue = 0;

	UPROPERTY(Category="DO NOT TOUCH")
	TArray<FActorArray> TargetWitherableActors;

	TArray<AActor> GetTargetWitherableActorDatas()
	{
		TArray<AActor> Actors = TArray<AActor>();
		for (int i = 0; i < TargetWitherableActors.Num(); i++)
		{
			for (int j = 0; j < TargetWitherableActors[i].Data.Num(); j++)
			{
				Actors.Add(TargetWitherableActors[i].Data[j]);
			}
		}
		return Actors;
	}
	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		float LocalRadius = Radius;
		Sphere.SetWorldScale3D(FVector(LocalRadius, LocalRadius, LocalRadius));
    }

	TArray<UStaticMeshComponent> MakeArray(UStaticMeshComponent input)
	{
		TArray<UStaticMeshComponent> result = TArray<UStaticMeshComponent>();
		result.Add(input);
		return result;
	}

	TArray<UStaticMeshComponent> GetMeshCompFromActor(AActor PickedActor)
	{
		if(PickedActor == nullptr)
			return MakeArray(nullptr);

		AStaticMeshActor StaticMeshActor = Cast<AStaticMeshActor>(PickedActor);
		if(StaticMeshActor != nullptr)
			return MakeArray(StaticMeshActor.StaticMeshComponent);

		APropBaseActor SplineActor = Cast<APropBaseActor>(PickedActor);
		if(SplineActor != nullptr)
		{
			UStaticMeshComponent ReplacementMesh = SplineActor.BPSplineMeshGetReplacementMesh();
			if(ReplacementMesh != nullptr)
				return MakeArray(ReplacementMesh);
			
			TArray<USplineMeshComponent> SplineMeshes = SplineActor.BPSplineMeshGetMeshComponents();
			TArray<UStaticMeshComponent> CastedSplineMeshes = TArray<UStaticMeshComponent>();
			for (int i = 0; i < SplineMeshes.Num(); i++)
			{
				CastedSplineMeshes.Add(SplineMeshes[i]);
			}
			if(CastedSplineMeshes.Num() > 0)
				return CastedSplineMeshes;
		}

		return MakeArray(nullptr);
	}
	
	void RemoveMeshFromOtherUnwitherSpheres(AActor MeshActor)
	{
		TArray<AActor> UnwitherActors = TArray<AActor>();
		Gameplay::GetAllActorsOfClass(AGameplayUnwitherBase::StaticClass(), UnwitherActors);
		for (auto WitherActor : UnwitherActors)
		{
			if(WitherActor != this)
			{
				AGameplayUnwitherBase thing = Cast<AGameplayUnwitherBase>(WitherActor);
				for (int i = 0; i < thing.TargetWitherableActors.Num(); i++)
				{
					for (int j = 0; j < thing.TargetWitherableActors[i].Data.Num(); j++)
					{
						if(thing.TargetWitherableActors[i].Data[j] == MeshActor)
						{
							thing.TargetWitherableActors[i].Data[j] = nullptr;
						}
					}
				}
			}
		}
	}

	void CopyActors(TArray<AActor> Actors, bool Clear = true)
	{
		if(Clear)
		{
			GrabbedWitherableThorns.Empty();
			TargetWitherableActors.Empty();
		}
		
		for (auto MeshActor : Actors)
		{
			if(MeshActor == nullptr)
				continue;

			// Filter on level
			if(MeshActor.Level != this.Level)
				continue;

			AGreenhouseBossGrowingThorns Thorns = Cast<AGreenhouseBossGrowingThorns>(MeshActor);
			if(Thorns != nullptr)
				GrabbedWitherableThorns.Add(Thorns);

			AUnwitherBulbSpike Spikes = Cast<AUnwitherBulbSpike>(MeshActor);
			if(Spikes != nullptr)
				GrabbedWitherableSpikes.Add(Spikes);

			TArray<UStaticMeshComponent> MeshComps = GetMeshCompFromActor(MeshActor);
			for (int k = 0; k < MeshComps.Num(); k++)
			{
				UStaticMeshComponent MeshComp = MeshComps[k];

				// Filter on valid mesh
				if(MeshComp == nullptr)
					continue;
				
				RemoveMeshFromOtherUnwitherSpheres(MeshActor);

				for (int i = 0; i < MeshComp.Materials.Num(); i++)
				{
					UMaterialInterface Mat = MeshComp.Materials[i];
					
					if(Mat == nullptr)
						continue;
					
					// Filter on correct material.
					bool BaseMatFound = false;
					for (int j = 0; j < EnvWitherBaseMaterials.Num(); j++)
					{
						auto EnvWitherBaseMaterial = EnvWitherBaseMaterials[j];
						if(Mat.BaseMaterial == EnvWitherBaseMaterial)
						{
							BaseMatFound = true;
							continue;
						}
					}
					if(!BaseMatFound)
						continue;
					
					// See if this material already exists
					bool found = false;
					int MaterialArrayIndex = 0;
					for (auto WitherableActor : TargetWitherableActors)
					{
						if(WitherableActor.Mat == Mat)
						{
							found = true;
							break;
						}
						MaterialArrayIndex++;
					}
					
					if(!found)
					{
						FActorArray a = FActorArray();
						a.Data = TArray<AActor>();
						a.Mat = Mat;
						a.MatIndex = i;
						
						TargetWitherableActors.Add(a);
					}
					TargetWitherableActors[MaterialArrayIndex].Data.Add(MeshActor);
					TargetWitherableActors[MaterialArrayIndex].CollisionProfile.Add(MeshComp.GetCollisionEnabled());
				}
			}
		}
	}

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(SoundEvent != nullptr)
		{
			AmbientWitherNoises = UHazeAkComponent::Create(this);
			AmbientWitherNoises.HazePostEvent(SoundEvent.AmbientSoundEvent);
			AmbientWitherNoises.bUseAutoDisable = false; // Make it so DisableActor does not also disable sound.
		}

		auto WitherableActors = GetTargetWitherableActorDatas();
		TArray<FAkSoundPosition> Positions;
		
		for (int i = 0; i < WitherableActors.Num(); i++)
		{
			if (WitherableActors[i] == nullptr)
			{
				continue;
			}

			// Check through all placed audio components and ensure we are not too close to any of them.
			int MaxSoundDistance = 1000;
			bool IsTooClose = false;
			for (int j = 0; j < Positions.Num(); j++)
			{
				if(Positions[j].Position.Distance(WitherableActors[i].GetActorLocation()) < MaxSoundDistance)
				{
					IsTooClose = true;
					break;
				}
			}
			
			if(IsTooClose)
			{
				continue;
			}
			Positions.Add(FAkSoundPosition(WitherableActors[i].GetActorLocation()));
		}

		if(AmbientWitherNoises != nullptr)
			AmbientWitherNoises.HazeSetMultiplePositions(Positions);
		
		for (auto MeshMaterial : TargetWitherableActors)
		{
			// Create material from first valid mesh
			for (auto Meshes : MeshMaterial.Data)
			{
				TArray<UStaticMeshComponent> MeshComps = GetMeshCompFromActor(Meshes);
				for (int k = 0; k < MeshComps.Num(); k++)
				{
					UStaticMeshComponent MeshComp = MeshComps[k];

					if(MeshComp == nullptr)
						continue;

					MeshMaterial.DynamicMat = MeshComp.CreateDynamicMaterialInstance(MeshMaterial.MatIndex);
				}
			}
			
			if(MeshMaterial.DynamicMat == nullptr)
				continue;

			for (auto Meshes : MeshMaterial.Data)
			{
				TArray<UStaticMeshComponent> MeshComps = GetMeshCompFromActor(Meshes);
				for (int k = 0; k < MeshComps.Num(); k++)
				{
					UStaticMeshComponent MeshComp = MeshComps[k];

					if(MeshComp != nullptr)
					{
						MeshComp.SetMaterial(MeshMaterial.MatIndex, MeshMaterial.DynamicMat);
					}
				}

				// Set all spline mesh instances to have the same material as the first one.
				APropBaseActor SplineMeshActor = Cast<APropBaseActor>(Meshes);
				TArray<USplineMeshComponent> TargetSplineMeshes = TArray<USplineMeshComponent>();
				if(SplineMeshActor != nullptr)
					TargetSplineMeshes = SplineMeshActor.BPSplineMeshGetMeshComponents();

				for (int i = 0; i < TargetSplineMeshes.Num(); i++)
				{
					TargetSplineMeshes[i].SetMaterial(0, TargetSplineMeshes[0].GetMaterial(0));
				}

				if(MeshMaterial.DynamicMat != nullptr)
				{
					MeshMaterial.DynamicMat.SetScalarParameterValue(n"HazeToggle_UsePainting", 0.0f);
					MeshMaterial.DynamicMat.SetScalarParameterValue(n"BlendValue", 1.0f);
					MeshMaterial.DynamicMat.SetScalarParameterValue(n"MaxBlendSpeed", MaxBlendSpeed);
				}
			}
		}

		// If the user touched any of these parameters they have decided to manually overwrite the starting state and we don't want to overwrite it again.
		bool BlendParamtersAreDefault = BlendTarget == 0 && BlendValue == 0;
		if(BlendParamtersAreDefault)
		{
			if(StartWithered)
				WitherInstant();
			else
				UnWitherInstant();
		}
	}

#if EDITOR
	UFUNCTION(CallInEditor)
    void SelectReferencedActors()
    {
		EditorLevel::SetActorSelectionState(this, false);

		for (int i = 0; i < TargetWitherableActors.Num(); i++)
		{
			for (int j = 0; j < TargetWitherableActors[i].Data.Num(); j++)
			{
            	EditorLevel::SetActorSelectionState(TargetWitherableActors[i].Data[j], true);	
			}
		}
	}
#endif

	bool bActorEnabled = true;
	void WitherActorEnable()
	{
		if(!bActorEnabled) // Enable only if already disabled.
			EnableActor(this);
		//SetActorTickEnabled(true);
		bActorEnabled = true;
	}
	void WitherActorDisable()
	{
		if(bActorEnabled) // Disable only if already enabled
			DisableActor(this);
		//SetActorTickEnabled(false);
		bActorEnabled = false;
	}

	UFUNCTION(CallInEditor, Category="Withering")
    void WitherToTargetInEditor()
    {
		WitherActorEnable();
		BlendTarget = BlendTargetValue;
		if(BlendTarget == 0.0f)
			DisableWitherableCollision();
		else if (BlendTarget == 1.0f)
			ResetWitherableCollision();
	}

	UFUNCTION()
    void WitherToTarget(float Target)
    {
		WitherActorEnable();
		BlendTargetValue = Target;
		BlendTarget = Target;
		if(BlendTarget == 0.0f)
			DisableWitherableCollision();
		else if (BlendTarget == 1.0f)
			ResetWitherableCollision();
	}

	UFUNCTION(CallInEditor, Category="Withering")
    void Wither()
    {
		WitherActorEnable();
		BlendTarget = 0.0f;
		DisableWitherableCollision();
		
		auto WitherableActors = GetTargetWitherableActorDatas();
		if(SoundEvent != nullptr)
		{
			if (AmbientWitherNoises != nullptr)
				AmbientWitherNoises.HazePostEvent(SoundEvent.WitherSoundEvent);
		}
		for (int i = 0; i < GrabbedWitherableThorns.Num(); i++)
		{
			GrabbedWitherableThorns[i].Wither();
		}
		for (int i = 0; i < GrabbedWitherableSpikes.Num(); i++)
		{
			GrabbedWitherableSpikes[i].Wither();
		}
	}

	UFUNCTION(CallInEditor, Category="Withering")
    void UnWither()
    {
		WitherActorEnable();
		BlendTarget = 1.0f;
		ResetWitherableCollision();
		
		for(ATriggerableFX a : GetAllTriggerableEffects(this))
		{
			a.TriggerFX();
		}
		
		auto WitherableActors = GetTargetWitherableActorDatas();

		if(AmbientWitherNoises != nullptr && SoundEvent != nullptr && SoundEvent.UnwitherSoundEvent != nullptr)
			AmbientWitherNoises.HazePostEvent(SoundEvent.UnwitherSoundEvent);
			
		for (int i = 0; i < GrabbedWitherableThorns.Num(); i++)
		{
			GrabbedWitherableThorns[i].UnWither();
		}
		for (int i = 0; i < GrabbedWitherableSpikes.Num(); i++)
		{
			GrabbedWitherableSpikes[i].UnWither();
		}
	}
	
	UFUNCTION(CallInEditor, Category="Withering")
    void WitherInstant()
    {
		WitherActorEnable();
		BlendTarget = 0.0f;
		BlendValue = 0.0f;
		DisableWitherableCollision();
		for (int i = 0; i < GrabbedWitherableThorns.Num(); i++)
		{
			GrabbedWitherableThorns[i].WitherInstant();
		}
		for (int i = 0; i < GrabbedWitherableSpikes.Num(); i++)
		{
			GrabbedWitherableSpikes[i].WitherInstant();
		}
	}

	UFUNCTION(CallInEditor, Category="Withering")
    void UnWitherInstant()
    {
		WitherActorEnable();
		BlendTarget = 1.0f;
		BlendValue = 1.0f;
		ResetWitherableCollision();
		for (int i = 0; i < GrabbedWitherableThorns.Num(); i++)
		{
			GrabbedWitherableThorns[i].UnWitherInstant();
		}
		for (int i = 0; i < GrabbedWitherableSpikes.Num(); i++)
		{
			GrabbedWitherableSpikes[i].UnWitherInstant();
		}
	}
	
	void Internal_ResetWitherableCollision()
	{
		// for each material
		for (auto MeshData : TargetWitherableActors) 
		{
			for(int i = 0; i < MeshData.Data.Num(); i++) // for each actor with material
			{
				TArray<UStaticMeshComponent> MeshComps = GetMeshCompFromActor(MeshData.Data[i]);
				for (int k = 0; k < MeshComps.Num(); k++) // for each mesh comp with material
				{
					UStaticMeshComponent MeshComp = MeshComps[k];

					if(MeshComp == nullptr)
						continue;

					MeshComp.SetCollisionEnabled(MeshData.CollisionProfile[i]);
				}
			}
		}
	}

	void Internal_DisableWitherableCollision()
	{
		// for each material
		for (auto MeshData : TargetWitherableActors)
		{
			// for each actor with material
			for (auto Actor : MeshData.Data) 
			{
				TArray<UStaticMeshComponent> MeshComps = GetMeshCompFromActor(Actor);
				for (int k = 0; k < MeshComps.Num(); k++) // for each mesh comp with material
				{
					UStaticMeshComponent MeshComp = MeshComps[k];

					if(MeshComp == nullptr)
						continue;
					
					MeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
				}
			}
		}
	}

	void ResetWitherableCollision()
	{
		if(FlipCollision)
			Internal_DisableWitherableCollision();
		else
			Internal_ResetWitherableCollision();
	}

	void DisableWitherableCollision()
	{
		if(FlipCollision)
			Internal_ResetWitherableCollision();
		else
			Internal_DisableWitherableCollision();
	}

    float MoveTowards(float Current, float Target, float StepSize)
    {
        return Current + FMath::Clamp(Target - Current, -StepSize, StepSize);
    }

	void SetParameterOnAllMaterials(FName name, float Value)
	{
		for (auto MeshData : TargetWitherableActors)
		{
			if(MeshData.DynamicMat == nullptr)
				continue;
			MeshData.DynamicMat.SetScalarParameterValue(name, Value);
		}
		if(IndexZeroBlendValue == 0.0f)
		{
			if(TargetWitherableActors.Num() > 0)
			{
				if (TargetWitherableActors[0].DynamicMat != nullptr)
				{
					TargetWitherableActors[0].DynamicMat.SetScalarParameterValue(n"BlendValue", 1);
				}
			}
		}
	}

    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		BlendValue = MoveTowards(BlendValue, BlendTarget, DeltaTime * BlendSpeed);
		SetParameterOnAllMaterials(n"BlendValue", BlendValue);
		if(BlendValue == BlendTarget)
		{
			WitherActorDisable();
		}
	}

	float IndexZeroBlendValue = -1;

	TArray<AActor> GetWitherableActorsInSphere()
	{
		TArray<AActor> FoundActors;
		Gameplay::GetAllActorsOfClass(AStaticMeshActor::StaticClass(), FoundActors);

		TArray<AActor> FilteredActors;

		for (auto MeshActor : FoundActors)
		{
			FVector MeshActorLocation = MeshActor.GetActorLocation();
			FVector ThisActorLocation = this.GetActorLocation();
			float Dist = MeshActorLocation.Distance(ThisActorLocation);
			if(Dist < Radius)
			{
				FilteredActors.Add(MeshActor);
			}
		}
		
		return FilteredActors;
	}
}


class AGameplayUnwither : AGameplayUnwitherBase // BP_GameplayUnwither, because renaming things in AS is scary.
{
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
	}

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		Super::ConstructionScript();

		#if EDITOR
			if(!Editor::IsCooking() && Level.IsVisible())
			{
				// Copy
				auto FilteredActors = GetWitherableActorsInSphere();
				CopyActors(FilteredActors, true);
				CopyActors(HandPickedActors, false);
			}
		#endif
    }
}

class AGameplayUnwitherSphereActor : AGameplayUnwitherBase // BP_GameplayUnwitherAdvanced, requires manual clicking to use.
{
	UFUNCTION(BlueprintEvent, BlueprintCallable, CallInEditor, Category="Copying")
	void CopyHandPickedActorsToTargetActors()
	{
		CopyActors(HandPickedActors);
	}

	UFUNCTION(BlueprintEvent, BlueprintCallable, CallInEditor, Category="Copying")
	void GrabWitherableActorsInSphere()
	{
		CopyActors(GetWitherableActorsInSphere());
	}

	// Snaps to just the tentacle
	UFUNCTION(CallInEditor, Category="Withering Extra")
	void SetFlowerRootStage1()
	{
		BlendValue = 0.0f;
		BlendTarget = 0.0f;
		ResetWitherableCollision();
		SetParameterOnAllMaterials(n"FlipWitherBlendDirection", 0.0f);
		SetParameterOnAllMaterials(n"WitherCompletely", 1.0f);
		IndexZeroBlendValue = 0.0f;
	}
	
	// Snaps to just the tentacle
	UFUNCTION(CallInEditor, Category="Withering Extra")
	void SetFlowerRootStage2()
	{
		BlendValue = 1.0f;
		BlendTarget = 1.0f;
		ResetWitherableCollision();
		SetParameterOnAllMaterials(n"FlipWitherBlendDirection", 0.0f);
		SetParameterOnAllMaterials(n"WitherCompletely", 1.0f);
		IndexZeroBlendValue = 0.0f;
	}
	// Blends in flowers without destroying the tentacle (0 - 1)
	UFUNCTION(CallInEditor, Category="Withering Extra")
	void ManuallySetBlendFlowerRootStage1To2(float Value)
	{
		BlendValue = Value;
		BlendTarget = Value;
		ResetWitherableCollision();
		SetParameterOnAllMaterials(n"FlipWitherBlendDirection", 0.0f);
		SetParameterOnAllMaterials(n"WitherCompletely", 1.0f);
		IndexZeroBlendValue = 1.0f;
	}
	// Blends in flowers without destroying the tentacle (0 - 1)
	UFUNCTION(CallInEditor, Category="Withering Extra")
	void BlendFlowerRootStage1To2()
	{
		BlendValue = 0.0f;
		BlendTarget = 1.0f;
		ResetWitherableCollision();
		SetParameterOnAllMaterials(n"FlipWitherBlendDirection", 0.0f);
		SetParameterOnAllMaterials(n"WitherCompletely", 1.0f);
		IndexZeroBlendValue = 0.0f;
	}
	// Blend away the whole thing (0 - 1)
	UFUNCTION(CallInEditor, Category="Withering Extra")
	void BlendFlowerRootStage2to3()
	{
		BlendValue = 1.0f;
		BlendTarget = 0.0f;
		ResetWitherableCollision();
		SetParameterOnAllMaterials(n"FlipWitherBlendDirection", 1.0f);
		SetParameterOnAllMaterials(n"WitherCompletely", 1.0f);
		IndexZeroBlendValue = 1.0f;
	}
	// Blend the whole thing (1 - 0)
	UFUNCTION(CallInEditor, Category="Withering Extra")
	void BlendFlowerRootStage3to2()
	{
		BlendValue = 0.0f;
		BlendTarget = 1.0f;
		ResetWitherableCollision();
		SetParameterOnAllMaterials(n"FlipWitherBlendDirection", 1.0f);
		SetParameterOnAllMaterials(n"WitherCompletely", 1.0f);
		IndexZeroBlendValue = 1.0f;
	}
	// Snaps away the whole thing
	UFUNCTION(CallInEditor, Category="Withering Extra")
	void SetFlowerRootStage3()
	{
		BlendValue = 0.0f;
		BlendTarget = 0.0f;
		ResetWitherableCollision();
		SetParameterOnAllMaterials(n"FlipWitherBlendDirection", 1.0f);
		SetParameterOnAllMaterials(n"WitherCompletely", 1.0f);
		IndexZeroBlendValue = 1.0f;
	}
}