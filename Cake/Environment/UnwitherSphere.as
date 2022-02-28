//import Cake.Environment.WitherLight;


class AUnWitherSphereBase : AHazeActor
{
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent Root;
	default Root.bVisualizeComponent = true;

    UPROPERTY(DefaultComponent)
    USphereComponent AngelscriptSphere;

	UPROPERTY()
	bool UseBPValues = true;

	UPROPERTY(Category="zzInternal")
	float AngelscriptAmbientWitherNoisesdius;


	UPROPERTY(Category="zzInternal")
	float AngelscriptTargetRadius;

	UPROPERTY(Category="zzInternal")
	FVector AngelscriptTargetLocation;
	

	UPROPERTY(Category="zzInternal")
	float AngelscriptCurrentRadius;

	UPROPERTY(Category="zzInternal")
	FVector AngelscriptCurrentLocation;
	

	UPROPERTY(Category="zzInternal")
	float AngelscriptStartRadius;

	UPROPERTY(Category="zzInternal")
	FVector AngelscriptStartLocation;


	UPROPERTY(Category="zzInternal")
	float AngelscriptLastPreviewRadius;

	UPROPERTY(Category="zzInternal")
	FVector AngelscriptLastPreviewLocation;
	
	UPROPERTY(Category="zzInternal")
	UMaterialParameterCollection WorldParameters;
	
	UPROPERTY(Category="zzInternal")
	UNiagaraParameterCollection NiagaraWorldParameters;

	bool Started = false;

    UFUNCTION(BlueprintEvent)
	bool GetBPUseActorPosition()
	{
		return false; // implemented in BP
	}

    UFUNCTION(BlueprintEvent)
	float GetBPRadius()
	{
		return 0; // implemented in BP
	}

    UFUNCTION(BlueprintEvent)
	FVector GetBPLocation()
	{
		return FVector(0,0,0); // implemented in BP
	}

    UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AngelscriptLastPreviewRadius = GetBPRadius();
		AngelscriptApplyPreviewVariablesToCurrentValues();
		AngelscriptSetCurrentData(AngelscriptCurrentLocation, AngelscriptCurrentRadius);
	}

    UFUNCTION()
	void AngelscriptApplyPreviewVariablesToCurrentValues()
	{
		AngelscriptCurrentRadius = GetBPRadius();
		AngelscriptStartRadius = AngelscriptCurrentRadius;
		
		AngelscriptCurrentLocation = GetActorTransform().TransformPosition(GetBPLocation());
		AngelscriptStartLocation =  AngelscriptCurrentLocation;
	}

    UFUNCTION()
	void AngelscriptSetCurrentData(FVector CurrentLocation, float CurrentRadius)
	{
		AngelscriptCurrentRadius = CurrentRadius;
		AngelscriptCurrentLocation = CurrentLocation;
		Material::SetVectorParameterValue(WorldParameters, n"UnwitherSphere", FLinearColor(CurrentLocation.X, CurrentLocation.Y, CurrentLocation.Z, CurrentRadius));
		// TODO: add niagara stuff? I think it GetScales deprecated but not sure.
	}

    UFUNCTION()
	void Enable()
	{
		SetActorTickEnabled(true);
	}

    UFUNCTION()
	void Disable()
	{
		SetActorTickEnabled(false);
	}


    UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if(UseBPValues)
		{
			if(!Started)
			{
				Started = true;
				BeginPlay();
			}
			
			if(GetBPLocation() != AngelscriptLastPreviewLocation || GetBPRadius() != AngelscriptLastPreviewRadius)
			{
				AngelscriptLastPreviewLocation = GetBPLocation();
				AngelscriptLastPreviewRadius = GetBPRadius();
				AngelscriptApplyPreviewVariablesToCurrentValues();
			}
		}

		if(GetBPUseActorPosition())
		{
			AngelscriptCurrentLocation = GetActorLocation();
		}

		AngelscriptSetCurrentData(AngelscriptCurrentLocation, AngelscriptCurrentRadius);
	}
}