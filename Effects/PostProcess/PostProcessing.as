import Peanuts.Outlines.Outlines;
import Cake.Environment.CameraParticleVolume;

UFUNCTION()
ACameraParticleVolume AddCameraParticleVolume(AHazePlayerCharacter Player, ACameraParticleVolume Volume)
{
	UPostProcessingComponent PostProcessingComponent = UPostProcessingComponent::Get(Player);
	PostProcessingComponent.CameraParticleVolumes.Add(Volume);
	return UpdateCameraParticleBasedOnVolumes(PostProcessingComponent);
}

UFUNCTION()
ACameraParticleVolume RemoveCameraParticleVolume(AHazePlayerCharacter Player, ACameraParticleVolume Volume)
{
	UPostProcessingComponent PostProcessingComponent = UPostProcessingComponent::Get(Player);
	PostProcessingComponent.CameraParticleVolumes.Remove(Volume);
	return UpdateCameraParticleBasedOnVolumes(PostProcessingComponent);
}

ACameraParticleVolume UpdateCameraParticleBasedOnVolumes(UPostProcessingComponent PostProcessingComponent)
{
	// Get volume with highest priority
	ACameraParticleVolume NewVolume = nullptr;
	UNiagaraSystem NewSystem = nullptr;
	int HighestPriority = MIN_int32;
	for(int i = 0; i < PostProcessingComponent.CameraParticleVolumes.Num(); i++)
	{
		int CurrentPriority = PostProcessingComponent.CameraParticleVolumes[i].Priority;
		if(CurrentPriority > HighestPriority)
		{
			HighestPriority = CurrentPriority;
			NewSystem = PostProcessingComponent.CameraParticleVolumes[i].EffectToChangeTo;
			NewVolume = PostProcessingComponent.CameraParticleVolumes[i];
		}
	}
	PostProcessingComponent.SetCameraParticleSystem(NewSystem);
	return NewVolume;
}

class UPostProcessingComponent : UActorComponent
{
	// Old parameters controlled by PlayerCharacter
	UPROPERTY(Category = "OutlinesEnabled")
	float OutlinesEnabled = 1;

	UPROPERTY(Category = "SpeedShimmer")
	float SpeedShimmer = 0;

	UPROPERTY(Category = "SpeedShimmer")
	UNiagaraSystem SpeedShimmerParticleEffect = Asset("/Game/Effects/PostProcess/SpeedShimmerSystem.SpeedShimmerSystem");

	UPROPERTY(Category = "SpeedShimmer")
	FVector SpeedShimmerDirection;

	UPROPERTY(Category = "SpeedShimmer")
	FLinearColor SpeedShimmerColor = FLinearColor(1.0f, 1.0f, 1.0f, 0.f);

	UPROPERTY(Category = "SpeedShimmer")
	UTexture2D SpeedShimmerTexture = Asset("/Game/Effects/Texture/Normal_Noise_Clouds_01.Normal_Noise_Clouds_01");

	UPROPERTY(Category = "Kaleidoscope")
	float KaleidoscopeStrength = 0;

	UPROPERTY(Category = "HurtPoint")
	float HurtPointStrength = 0;

	UPROPERTY(Category = "HurtPoint")
	float HurtBorderStrength = 0;

	// New parameters that need to be controlled directly
	UPROPERTY(Category = "Matrix")
	float MatrixStrength = 0;

	UPROPERTY(Category = "BlackAndWhite")
	float BlackAndWhite = 0;

	UPROPERTY(Category = "ClockworkBlackAndwhite")
	float ClockworkBlackAndwhite = 0;

	UPROPERTY(Category = "PlayerIndicator")
	float PlayerIndicatorAngle = 0;

	UPROPERTY(Category = "PlayerIndicator")
	float PlayerIndicatorActive = 0;

	UPROPERTY(Category = "PlayerIndicator")
	float PlayerIndicatorSize = 0.01f;

	UPROPERTY(Category = "PlayerIndicator")
	float PlayerIndicatorSharpness = 200.f;

	UPROPERTY(Category = "TVNoise")
	float Trippyness = 0.f;

	UPROPERTY(Category = "Cloud")
	float TrippynessClouds = 0.f;

	UPROPERTY(Category = "TVNoise")
	float VHS = 0.f;

	UPROPERTY(Category = "TVNoise")
	float TVNoise = 0.0f;

	UPROPERTY(Category = "PlayerIndicator")
	FLinearColor PlayerIndicatorColor = FLinearColor(0.33f, 0.65f, 0.25f, 0.f);

	FPostProcessSettings GlobalPostProcess;

	UOutlinesComponent OutlinesComponent;

	UPROPERTY(Category = "CameraParticle")
	UNiagaraSystem CameraParticleEffect;

	UPROPERTY(Category = "CameraParticle")
	UNiagaraComponent CameraParticleComponent;

	TArray<ACameraParticleVolume> CameraParticleVolumes;

	UPROPERTY()
	UMaterialInstanceDynamic UberShaderMaterialDynamic;

	TArray<UObject> DisableOutlineInstigators;

	UPROPERTY()
	UMaterialParameterCollection CharacterMaterialParameters = Asset("/Game/MasterMaterials/WorldParameters/CharacterMaterialParameters.CharacterMaterialParameters");

	private float PlayerFoliagePushSize = 150.f;
	AHazePlayerCharacter Player;
	

	// State 0 = off
	// State 1 = RGB, A
	// State 2 = R, G, B, A
	UFUNCTION()
	void SetDebugTexture(UTexture Texture, float State) 
	{
		UberShaderMaterialDynamic.SetScalarParameterValue(n"DebugTextureState", State);
		UberShaderMaterialDynamic.SetTextureParameterValue(n"DebugTexture", Texture);
	}

	UFUNCTION()
	void SetCameraParticleSystem(UNiagaraSystem CameraParticleEffect)
	{
		this.CameraParticleEffect = CameraParticleEffect;
		
		if(CameraParticleComponent != nullptr)
		{
			CameraParticleComponent.SetAutoDestroy(true);
			CameraParticleComponent.Deactivate();
		}

		if(CameraParticleEffect != nullptr)
		{
			CameraParticleComponent = Niagara::SpawnSystemAtLocation(CameraParticleEffect, FVector::ZeroVector, FRotator(0,0,0), bAutoDestroy=false);

			CameraParticleComponent.SetRenderedForPlayer(Cast<AHazePlayerCharacter>(Owner), true);
			CameraParticleComponent.SetRenderedForPlayer(Cast<AHazePlayerCharacter>(Owner).OtherPlayer, false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnResetComponent(EComponentResetType ResetType)
	{
		BlackAndWhite = 0.f;
		MatrixStrength = 0.f;
		ClockworkBlackAndwhite = 0.f;
		Trippyness = 0.f;
		TrippynessClouds = 0.f;
		VHS = 0.f;
		TVNoise = 0.f;
		KaleidoscopeStrength = 0.f;
		HurtPointStrength = 0.f;
		HurtBorderStrength = 0.f;

		SpeedShimmer = 0.f;
		SpeedShimmerDirection = FVector::ZeroVector;
		SpeedShimmerColor = FLinearColor(1.f, 1.f, 1.f, 0.f);

		OutlinesEnabled = 1.f;
		DisableOutlineInstigators.Empty();
		SetPlayerFoliagePushSize(150.f);
	}

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		// Post process settings to show Outlines
		if(OutlinesComponent.OutlineMaterialDynamic == nullptr)
			OutlinesComponent.Init();

		UberShaderMaterialDynamic = OutlinesComponent.OutlineMaterialDynamic;

		// Gets used directly by the render thread, so we can't remove it ever
		//   Technically a leak, but of an insignificant amount of memory
		UberShaderMaterialDynamic.AddToRoot();

		FWeightedBlendable Blendable;
		Blendable.Object = UberShaderMaterialDynamic;
		Blendable.Weight = 1.f;
		GlobalPostProcess.WeightedBlendables.Array.Add(Blendable);
		GlobalPostProcess.AmbientCubemapIntensity = 0;

		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		int ViewIndex = 0;
		if(Owner == Game::GetCody())
			ViewIndex = 0;
		else if(Owner == Game::GetMay())
			ViewIndex = 1;
		else
			ViewIndex = 2;
		
		if(CameraParticleComponent != nullptr)
		{
			CameraParticleComponent.SetWorldLocation(Player.GetPlayerViewLocation());
		}

		if(OutlinesComponent.OutlineMaterialDynamic == nullptr)
			OutlinesComponent.Init();
	
		UberShaderMaterialDynamic.SetScalarParameterValue(n"ViewportIndex", ViewIndex);
		
		UberShaderMaterialDynamic.SetScalarParameterValue(n"OutlinesEnabled", OutlinesEnabled);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"PFStickyness", PlayerIndicatorActive);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"PFAngle", PlayerIndicatorAngle);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"PFSize", PlayerIndicatorSize);
		UberShaderMaterialDynamic.SetVectorParameterValue(n"PFColor", PlayerIndicatorColor);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"PFSharpness", PlayerIndicatorSharpness);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"ClockworkBlackAndwhite", ClockworkBlackAndwhite);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"TVNoise", TVNoise);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"VHS", VHS);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"Trippyness", TrippynessClouds);

		FVector CameraSpaceSpeedShimmerDirection = FVector(0,0,0);
		
		if(Player != nullptr)
		{
			if(Player.CurrentlyUsedCamera != nullptr)
			{
				SpeedShimmerDirection = Player.ActorVelocity;
				
				SpeedShimmerDirection.Normalize();
				CameraSpaceSpeedShimmerDirection = Player.CurrentlyUsedCamera.GetWorldTransform().InverseTransformVector(SpeedShimmerDirection);	
			}
		}
		
		UberShaderMaterialDynamic.SetScalarParameterValue(n"SpeedShimmerStrength", SpeedShimmer);
		UberShaderMaterialDynamic.SetVectorParameterValue(n"SpeedShimmerDirection", FLinearColor(CameraSpaceSpeedShimmerDirection.X, CameraSpaceSpeedShimmerDirection.Y, CameraSpaceSpeedShimmerDirection.Z, 0));
		UberShaderMaterialDynamic.SetVectorParameterValue(n"SpeedShimmerMaskColor", SpeedShimmerColor);
		
		UberShaderMaterialDynamic.SetScalarParameterValue(n"KaleidoscopeStrength", KaleidoscopeStrength);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"PointStrength", HurtPointStrength);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"BorderStrength", HurtBorderStrength);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"MatrixStrength", MatrixStrength);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"BlackAndWhite", BlackAndWhite);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"TVNoise", TVNoise);
		
		
		float backwards = FMath::Sign(CameraSpaceSpeedShimmerDirection.X + 0.25f);
		SpeedShimmerTime += DeltaTime * backwards;
		SpeedShimmerLeftRightTarget = ((backwards * CameraSpaceSpeedShimmerDirection.Y * Player.GetActorScale3D().X) + 1.0) * 0.5;
		SpeedShimmerLeftRight = FMath::Lerp(SpeedShimmerLeftRight, SpeedShimmerLeftRightTarget, DeltaTime * 2.0);
		
		UberShaderMaterialDynamic.SetScalarParameterValue(n"SpeedShimmerPosX", SpeedShimmerLeftRight);
		UberShaderMaterialDynamic.SetScalarParameterValue(n"SpeedShimmerCustomTime", SpeedShimmerTime);
	}
	float SpeedShimmerLeftRight = 0;
	float SpeedShimmerLeftRightTarget = 0;
	float SpeedShimmerTime = 0;

	UFUNCTION()
	void EnableOutlineByInstigator(UObject Instigator)
	{
		DisableOutlineInstigators.Remove(Instigator);

		if (DisableOutlineInstigators.Num() == 0)
			OutlinesEnabled = 1;
	}

	UFUNCTION()
	void DisableOutlineByInstigator(UObject Instigator)
	{
		if (Instigator != nullptr)
		{
			DisableOutlineInstigators.AddUnique(Instigator);
			OutlinesEnabled = 0;
		}
	}

	UFUNCTION()
	void SetPlayerFoliagePushSize(float NewSize)
	{
		if (PlayerFoliagePushSize == NewSize)
			return;

		PlayerFoliagePushSize = NewSize;
		Material::SetScalarParameterValue(
			CharacterMaterialParameters,
			Player.IsCody() ? n"CodySize" : n"MaySize",
			PlayerFoliagePushSize);
	}
}

UFUNCTION()
void SetPostprocessBlackAndWhite(AHazePlayerCharacter Player, float BlackAndWhite)
{
	UPostProcessingComponent::Get(Player).BlackAndWhite = BlackAndWhite;
}