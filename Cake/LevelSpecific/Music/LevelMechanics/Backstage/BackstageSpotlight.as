class ABackstageSpotlight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USpotLightComponent Spotlight;
	default Spotlight.Mobility = EComponentMobility::Stationary;
	default Spotlight.IntensityUnits = ELightUnits::Candelas;


	UPROPERTY()
	APointLight ConnectedPointLight;

	UPROPERTY()
	UCurveFloat LightCurve;

	UPROPERTY()
	AReflectionCapture ConnectedReflectionCapture;

	UPROPERTY()
	bool bStartActivated = false;

	bool bStartLerping = false;
	bool bStartTimer = false;
	bool bHasActivatedReflection = false;

	float TimerDuration = 0.f;
	float LightLerpAlpha = 0.f;
	float LightLerpDuration = 1.f;

	float StartingSpotLightIntensity = 0.f;
	float StartingPointLightIntensity = 0.f;

	float TargetSpotLightIntensity = 0.f;
	float TargetPointLightIntensity = 0.f;

	float ActivateReflectionTime = 0.f;

	bool bDebugToggle = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (!bStartActivated)
		{
			StartingSpotLightIntensity = 0.f;
			StartingPointLightIntensity = 0.f;
			TargetSpotLightIntensity = Spotlight.Intensity;
			Spotlight.SetIntensity(0.f);
			
			if (ConnectedPointLight != nullptr)
			{
				TargetPointLightIntensity = ConnectedPointLight.LightComponent.Intensity;
				ConnectedPointLight.LightComponent.SetIntensity(0.f);
			}

			if (ConnectedReflectionCapture == nullptr)
				return;
			ConnectedReflectionCapture.CaptureComponent.SetVisibility(false);
		
		} else 
		{
			StartingSpotLightIntensity = Spotlight.Intensity;
			TargetSpotLightIntensity = 0.f;
			
			if (ConnectedPointLight != nullptr)
			{
				StartingPointLightIntensity = ConnectedPointLight.LightComponent.Intensity;
				TargetPointLightIntensity = 0.f;
			}
			if (ConnectedReflectionCapture == nullptr)
				return;
			ConnectedReflectionCapture.CaptureComponent.SetVisibility(true);
		}
	}

	UFUNCTION()
	void DebugToggleLights()
	{
		if (!bDebugToggle)
		{
			bDebugToggle = true;
			Spotlight.SetIntensity(StartingSpotLightIntensity);
			
			if (ConnectedPointLight != nullptr)
			{
				ConnectedPointLight.LightComponent.SetIntensity(StartingPointLightIntensity);
			}
			
			if (ConnectedReflectionCapture != nullptr)
				ConnectedReflectionCapture.CaptureComponent.SetVisibility(true);
		} else
		{
			bDebugToggle = false;
			Spotlight.SetIntensity(TargetSpotLightIntensity);
			
			if (ConnectedPointLight != nullptr)
				ConnectedPointLight.LightComponent.SetIntensity(TargetPointLightIntensity);
			
			if (ConnectedReflectionCapture != nullptr)
				ConnectedReflectionCapture.CaptureComponent.SetVisibility(false);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bStartTimer)
		{
			TimerDuration -= DeltaTime;
			if (TimerDuration <= 0.f)
			{
				bStartLerping = true; 
				bStartTimer = false;
			}
		}
		
		if (!bStartLerping)
			return;

		LightLerpAlpha += DeltaTime / LightLerpDuration;

		if (LightLerpAlpha >= 1.f)
		{
			LightLerpAlpha = 1.f;
			bStartLerping = false;
		}

		Spotlight.SetIntensity(FMath::Lerp(StartingSpotLightIntensity, TargetSpotLightIntensity, LightCurve.GetFloatValue(LightLerpAlpha)));
		
		if (ConnectedPointLight != nullptr)
			ConnectedPointLight.LightComponent.SetIntensity(FMath::Lerp(StartingPointLightIntensity, TargetPointLightIntensity, LightCurve.GetFloatValue(LightLerpAlpha)));

		if (LightLerpAlpha >= ActivateReflectionTime && !bHasActivatedReflection && ConnectedReflectionCapture != nullptr)
		{
			bHasActivatedReflection = true;
			if (!bStartActivated)
				ConnectedReflectionCapture.CaptureComponent.SetVisibility(true);
			else
				ConnectedReflectionCapture.CaptureComponent.SetVisibility(false);
		}
	}
	
	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		Spotlight.SetIndirectLightingIntensity(0.f);
		
		if (ConnectedPointLight == nullptr)
			return;
		
		ConnectedPointLight.PointLightComponent.SetLightColor(Spotlight.LightColor);
		ConnectedPointLight.PointLightComponent.SetIndirectLightingIntensity(Spotlight.IndirectLightingIntensity);
		//ConnectedPointLight.LightComponent.CastDynamicShadows = false; Fixed the correct way by victor
	}

	UFUNCTION()
	void ActivateLights(float FadeInDuration, float Delay, float NewActivateReflectionTime)
	{
		LightLerpDuration = FadeInDuration;
		ActivateReflectionTime = NewActivateReflectionTime;
		
		if (Delay > 0.f)
		{
			TimerDuration = Delay;
			bStartTimer = true;
		} else 
		{
			bStartLerping = true;
		}
	}
}