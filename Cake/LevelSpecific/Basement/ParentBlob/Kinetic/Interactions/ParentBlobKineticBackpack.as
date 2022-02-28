import Cake.LevelSpecific.Basement.ParentBlob.Kinetic.Interactions.ParentBlobKineticFloatingObject;
import Rice.Math.MathStatics;
import Cake.Environment.HazeSphere;

class AParentBlobKineticBackpack : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UParentBlobKineticInteractionComponent Interaction;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent ObjectRoot;

	UPROPERTY(DefaultComponent, Attach = ObjectRoot)
	UStaticMeshComponent ObjectMesh;

	UPROPERTY(DefaultComponent, Attach = ObjectRoot)
	UNiagaraComponent ChargeEffectComp;

	UPROPERTY(DefaultComponent, Attach = ChargeEffectComp)
	UNiagaraComponent ProjectileEffectComp;

	UPROPERTY(DefaultComponent, Attach = ProjectileEffectComp)
	UNiagaraComponent ImpactEffectComp;

	UPROPERTY(DefaultComponent, Attach = ObjectRoot)
	UNiagaraComponent GlowEffectComp;

	UPROPERTY(DefaultComponent, Attach = ObjectRoot)
	UPointLightComponent Light;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSphereComponent HazeSphereComp;
	
	UPROPERTY(DefaultComponent, Attach = ObjectMesh)
	UStaticMeshComponent MeshGlow;
	
	UPROPERTY()
	bool bGlowEnabled = false;

	UPROPERTY()
	UForceFeedbackEffect ForceFeedback;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CameraShake;

	UPROPERTY()
	AActor Target;

	UPROPERTY()
	AParentBlobKineticBackpack NextBackpack;

	UPROPERTY()
	UStaticMesh KineticMesh;

	UPROPERTY()
	float LightIntensity = 1.0f;

	UPROPERTY()
	UMaterialInterface GlowMaterial;
	UPROPERTY()
	FHazeTimeLike MoveBallTimeLike;
	default MoveBallTimeLike.Duration = 1.f;

	UPROPERTY()
	float ProjectileTravelTime = 0.25f;

	FVector BallStartLocation;

	float GlowValue = 1.0f;
	float GlowTarget = 1.0f;
	
	UPROPERTY()
	FParentBlobKineticInteractionCompletedSignature OnInteractionCompleted;

	UFUNCTION(CallInEditor)
	void EnableGlow()
	{
		bGlowEnabled = true;
		GlowValue = 1.f;
		GlowTarget = 1.0f;
		GlowEffectComp.Activate();
		ExecuteConstructionScript();
	}

	UFUNCTION(CallInEditor)
	void DisableGlow()
	{
		bGlowEnabled = false;
		GlowValue = 0.f;
		GlowTarget = 0.0f;
		GlowEffectComp.Deactivate();
		ExecuteConstructionScript();
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		if(GlowValue != GlowTarget)
		{
			MeshGlow.SetScalarParameterValueOnMaterials(n"Opacity", GlowValue);
			Light.SetIntensity(LightIntensity * GlowValue);
			HazeSphereComp.SetOpacityValue(GlowValue * 0.2f);
		}

		GlowValue = MoveTowards(GlowValue, GlowTarget, DeltaSeconds);
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		ObjectMesh.SetStaticMesh(KineticMesh);
		MeshGlow.SetStaticMesh(KineticMesh);

		for(int i = 0; i < MeshGlow.Materials.Num(); i++)
		{
			MeshGlow.SetMaterial(i, GlowMaterial);
		}
		
		Niagara::OverrideSystemUserVariableStaticMesh(GlowEffectComp, "StaticMeshSampler", KineticMesh);
		float Intensity = bGlowEnabled ? 1.f : 0.f;
		Light.SetIntensity(LightIntensity * Intensity);
		MeshGlow.SetScalarParameterValueOnMaterials(n"Opacity", Intensity);
		HazeSphereComp.SetOpacityValue(Intensity * 0.2f);
		HazeSphereComp.ConstructionScript_Hack();
		GlowEffectComp.SetAutoActivate(bGlowEnabled);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Interaction.OnCompleted.AddUFunction(this, n"Completed");
		
		MoveBallTimeLike.BindUpdate(this, n"UpdateMoveBall");
		MoveBallTimeLike.BindFinished(this, n"FinishMoveBall");

		MoveBallTimeLike.SetPlayRate(1.f/ProjectileTravelTime);
	}

	UFUNCTION()
	void Enable()
	{
		bGlowEnabled = true;
		GlowValue = 0.f;
		GlowTarget = 1.f;
		GlowEffectComp.Activate(true);
		Interaction.MakeAvailableAsTarget(true);
	}

	UFUNCTION()
	void Disable()
	{
		bGlowEnabled = false;
		GlowTarget = 0.f;
		GlowEffectComp.Deactivate();
		Interaction.MakeAvailableAsTarget(false);
	}

	UFUNCTION()
	void Completed(FParentBlobKineticInteractionCompletedDelegateData Data)
	{
		for (AHazePlayerCharacter Player : Game::GetPlayers())
		{
			Player.PlayForceFeedback(ForceFeedback, false, true, n"Backpack");
			Player.PlayCameraShake(CameraShake);
		}

		if (NextBackpack != nullptr)
			NextBackpack.Enable();

		ChargeEffectComp.Deactivate();
		ProjectileEffectComp.SetWorldLocation(ChargeEffectComp.WorldLocation);
		ProjectileEffectComp.Activate(true);
		BallStartLocation = ProjectileEffectComp.WorldLocation;
		MoveBallTimeLike.PlayFromStart();

		FParentBlobKineticInteractionCompletedDelegateData CompleteData;
		CompleteData.Interaction = Interaction;
		OnInteractionCompleted.Broadcast(CompleteData);

		Disable();
	}

	UFUNCTION(NotBlueprintCallable)
	void UpdateMoveBall(float CurValue)
	{
		if (Target == nullptr)
			return;
			
		FVector CurLoc = FMath::Lerp(BallStartLocation, Target.ActorLocation, CurValue);
		ProjectileEffectComp.SetWorldLocation(CurLoc);
	}

	UFUNCTION(NotBlueprintCallable)
	void FinishMoveBall()
	{
		ImpactEffectComp.Activate();
		ProjectileEffectComp.Deactivate();
	}
}