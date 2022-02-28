import Cake.Environment.Godray;
class ABackstageEmissiveSpotlight : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent SpotlightMesh;

	UPROPERTY(DefaultComponent, Attach = SpotlightMesh)
	USceneComponent DestroyFxLoc;

	UPROPERTY()
	UCurveFloat LightCurve;

	UPROPERTY()
	bool bStartActivated = false;

	UPROPERTY()
	AGodray ConnectedGodray;

	bool bStartLerping = false;
	bool bStartTimer = false;

	float TimerDuration = 0.f;
	float LightLerpAlpha = 0.f;
	float LightLerpAlphaWithCurve = 0.f;
	float LightLerpDuration = 1.f;

	FLinearColor StartingColor01 = FLinearColor(0.f, 0.f, 0.f, 0.f);
	FLinearColor StartingColor02 = FLinearColor(0.f, 0.f, 0.f, 0.f);
	FLinearColor TargetColor01;
	FLinearColor TargetColor02;

	bool bDebugToggle = false;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		UMaterialInstance OriginalMat01 = Cast<UMaterialInstance>(SpotlightMesh.GetMaterial(0));
		UMaterialInstance OriginalMat02 = Cast<UMaterialInstance>(SpotlightMesh.GetMaterial(3));
		
		auto OriginalMatValues01 = OriginalMat01.VectorParameterValues;

		for (FVectorParameterValue Value : OriginalMatValues01)
		{
			if (Value.ParameterInfo.Name == n"Emissive Tint")
			{
				if (bStartActivated)
				{
					StartingColor01 = Value.ParameterValue;
					TargetColor01 = FLinearColor(0.f, 0.f, 0.f, 0.f);
				} else 
				{
					StartingColor01 = FLinearColor(0.f, 0.f, 0.f, 0.f);
					TargetColor01 = Value.ParameterValue;
				}
			}
		}

		auto OriginalMatValues02 = OriginalMat01.VectorParameterValues;

		for (FVectorParameterValue Value : OriginalMatValues02)
		{
			if (Value.ParameterInfo.Name == n"Emissive Tint")
			{
				if (bStartActivated)
				{
					StartingColor02 = Value.ParameterValue;
					TargetColor02 = FLinearColor(0.f, 0.f, 0.f, 0.f);
				} else 
				{
					StartingColor02 = FLinearColor(0.f, 0.f, 0.f, 0.f);
					TargetColor02 = Value.ParameterValue;
				}
			}
		}

		if (!bStartActivated)
		{
			SpotlightMesh.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", FLinearColor(0.f, 0.f, 0.f, 0.f));
			SpotlightMesh.SetColorParameterValueOnMaterialIndex(3, n"Emissive Tint", FLinearColor(0.f, 0.f, 0.f, 0.f));
		}
	}

	UFUNCTION()
	void DebugToggleLights()
	{
		if (!bDebugToggle)
		{
			bDebugToggle = true;
			SpotlightMesh.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", TargetColor01);
			SpotlightMesh.SetColorParameterValueOnMaterialIndex(3, n"Emissive Tint", TargetColor02);
			
		} else
		{
			bDebugToggle = false;
			SpotlightMesh.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", FLinearColor(0.f, 0.f, 0.f, 0.f));
			SpotlightMesh.SetColorParameterValueOnMaterialIndex(3, n"Emissive Tint", FLinearColor(0.f, 0.f, 0.f, 0.f));
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

		if (LightLerpAlpha > 1.f)
			return;

		LightLerpAlpha += DeltaTime / LightLerpDuration;
		LightLerpAlphaWithCurve = LightCurve.GetFloatValue(LightLerpAlpha);
		SpotlightMesh.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", (StartingColor01 * (1.f - LightLerpAlphaWithCurve) + TargetColor01 * LightLerpAlphaWithCurve));
		SpotlightMesh.SetColorParameterValueOnMaterialIndex(3, n"Emissive Tint", (StartingColor02 * (1.f - LightLerpAlphaWithCurve) + TargetColor02 * LightLerpAlphaWithCurve));
	}

	UFUNCTION()
	void ActivateSpotlights(float FadeInDuration, float Delay)
	{
		LightLerpDuration = FadeInDuration;
		
		if (Delay > 0.f)
		{
			TimerDuration = Delay;
			bStartTimer = true;
		} else 
		{
			bStartLerping = true;
		}
	}

	UFUNCTION()
	void DisableSpotlightAndPlayFX()
	{
		if (ConnectedGodray != nullptr)
			ConnectedGodray.DestroyActor();

		SpotlightMesh.SetColorParameterValueOnMaterialIndex(0, n"Emissive Tint", FLinearColor(0.f, 0.f, 0.f, 0.f));
		SpotlightMesh.SetColorParameterValueOnMaterialIndex(3, n"Emissive Tint", FLinearColor(0.f, 0.f, 0.f, 0.f));
	}
}