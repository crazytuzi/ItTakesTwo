import Cake.Environment.HazeSphere;
import Cake.Environment.UnwitherSphere;

enum EWitherLightType
{
	PointLight,
	StationarySpotlight,
	StationarySpotlightNoShadows,
}

class AWitherLight : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY()
	AUnWitherSphereBase UnwitherSphere;

	UPROPERTY()
	EWitherLightType LightType;

	UPROPERTY(meta = (MakeEditWidget))
	TArray<FTransform> LightTransforms;
	
	UPROPERTY()
	float Intensity = 1.0f;
	
	UPROPERTY()
	bool DebugPrints = false;

	UPROPERTY()
	float AttenuationRadius = 1000.0f;

	UPROPERTY()
	FLinearColor LightColor = FLinearColor(1,1,1,1);

	UPROPERTY()
	float FadeTime = 1.0f;

	UPROPERTY()
	TArray<AHazeSphere> HazeSpheres;

	UPROPERTY(Category="zzInternal")
	TArray<float> HazeSphereStartOpacities;

	UPROPERTY(Category="zzInternal")
	TArray<UPointLightComponent> SpawnedLights;

	UPROPERTY(Category="zzInternal")
	float CurrentFadeValue = 0.0f;

    UFUNCTION(CallInEditor)
    void RemoveHazespheresFromOthers()
    {
		TArray<AActor> FoundWitherLights;
		Gameplay::GetAllActorsOfClass(AWitherLight::StaticClass(), FoundWitherLights);

		for (int i = FoundWitherLights.Num() - 1; i >= 0; i--)
		{
			if(FoundWitherLights[i] == this)
				continue;

			AWitherLight FoundWitherLight = Cast<AWitherLight>(FoundWitherLights[i]);
			for (int j = FoundWitherLight.HazeSpheres.Num() - 1; j >= 0; j--)
			{
				for (int k = HazeSpheres.Num() - 1; k >= 0; k--)
				{
					if(HazeSpheres[k] == nullptr)
						continue;
					if(FoundWitherLight.HazeSpheres[j] == nullptr)
						continue;
					if(HazeSpheres[k] != FoundWitherLight.HazeSpheres[j])
						continue;
						
					FoundWitherLight.HazeSpheres.RemoveAt(j);
					
				}
			}
		}
	}

    UFUNCTION(BlueprintOverride)
    void ConstructionScript()
    {
		SpawnedLights.Empty();
		HazeSphereStartOpacities.Empty();

		for (int i = 0; i < LightTransforms.Num(); i++)
		{
			UPointLightComponent NewLight = nullptr;
			switch(LightType)
			{
				case EWitherLightType::PointLight:
				{
					NewLight = UPointLightComponent::Create(this);
					NewLight.Mobility = EComponentMobility::Movable;
					NewLight.SetInverseSquaredFalloff(false);
					NewLight.CastShadows = false;
					break;
				}
				case EWitherLightType::StationarySpotlight:
				{
					NewLight = USpotLightComponent::Create(this);
					NewLight.Mobility = EComponentMobility::Stationary;
					NewLight.SetInverseSquaredFalloff(false);
					break;
				}
				case EWitherLightType::StationarySpotlightNoShadows:
				{
					NewLight = USpotLightComponent::Create(this);
					NewLight.Mobility = EComponentMobility::Stationary;
					NewLight.CastShadows = false;
					break;
				}
			}
			
			NewLight.AttenuationRadius = AttenuationRadius;
			NewLight.SetIndirectLightingIntensity(0.0f);
			NewLight.SetRelativeTransform(LightTransforms[i]);
			SpawnedLights.Add(NewLight);
		}

		for (int i = 0; i < SpawnedLights.Num(); i++)
		{
			SpawnedLights[i].SetLightColor(LightColor);
			SpawnedLights[i].SetIntensity(Intensity);
		}

		for (int i = 0; i < HazeSpheres.Num(); i++)
		{
			if(HazeSpheres[i] == nullptr)
				HazeSphereStartOpacities.Add(0.0f);
			else
				HazeSphereStartOpacities.Add(HazeSpheres[i].HazeSphereComponent.Opacity);
		}
    }
    
    UFUNCTION(BlueprintOverride)
	void BeginPlay()
    {
		for (int i = 0; i < SpawnedLights.Num(); i++)
		{
			SpawnedLights[i].SetLightColor(FLinearColor::Black);
			SpawnedLights[i].SetIntensity(0.0f);
		}
    }

    float MoveTowards(float Current, float Target, float StepSize)
    {
        return Current + FMath::Clamp(Target - Current, -StepSize, StepSize);
    }


    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
    {
		if(UnwitherSphere == nullptr)
			return;
		bool Inside = GetActorLocation().Distance(UnwitherSphere.AngelscriptCurrentLocation) < UnwitherSphere.AngelscriptCurrentRadius;
		CurrentFadeValue = MoveTowards(CurrentFadeValue, Inside ? 1.0f : 0.0f, DeltaTime / FadeTime);

		for (int i = 0; i < SpawnedLights.Num(); i++)
		{
			SpawnedLights[i].SetLightColor(LightColor * CurrentFadeValue);
			SpawnedLights[i].SetIntensity(Intensity * CurrentFadeValue);
		}
		
		for (int i = 0; i < HazeSpheres.Num(); i++)
		{
			if(HazeSpheres[i] != nullptr)
				HazeSpheres[i].HazeSphereComponent.SetOpacityValue(HazeSphereStartOpacities[i] * CurrentFadeValue);
		}
    }
}