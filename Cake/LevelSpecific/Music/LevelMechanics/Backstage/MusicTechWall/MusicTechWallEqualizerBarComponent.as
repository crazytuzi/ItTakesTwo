class UMusicTechWallEqualizerBarComponent : UStaticMeshComponent
{
	default RelativeScale3D = FVector(1.28f, 1.f, 16.f);
	default RemoveTag(ComponentTags::LedgeGrabbable);
	default RemoveTag(ComponentTags::WallSlideable);
	default PrimaryComponentTick.bStartWithTickEnabled = false;
	
	float BarEQPlacement = 0.f;
	float CurrentLeftEQPlacement = 0.5f;
	float CurrentRightEQPlacement = 0.5f;
	int CurrentNumberOfBars;

	bool bControlledWithLeftStick = false;

	float StartScaleZ = 0.f;
	float TargetScaleZ = 15.f;

	float StartZ = 0.f;
	float TargetZ = 1500.f;
	
	float InterpSpeed = 0.f;

	UPROPERTY()
	FLinearColor BlueEmissive;
	default BlueEmissive = FLinearColor(0.0f, 0.0f, 10.0f, 1.f);
	
	UPROPERTY()
	FLinearColor Blue;
	default Blue = FLinearColor(0.0f, 0.0f, 1.0f, 1.f);

	UPROPERTY()
	FLinearColor RedEmissive;
	default RedEmissive = FLinearColor(10.0f, 0.0f, 0.0f, 1.f);

	UPROPERTY()
	FLinearColor Red;
	default Red = FLinearColor(1.0f, 0.0f, 0.0f, 1.f);
	


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InterpSpeed = FMath::RandRange(1.f, 2.f);
	}
	
	UFUNCTION()
	void UpdateEqComp(float DeltaTime)
	{				
		float ScaleZ;
		float Z;

		if (bControlledWithLeftStick)
		{
			Z = FMath::FInterpTo(RelativeLocation.Z, FMath::Lerp(StartZ, TargetZ,
			GetLerpValue(CurrentLeftEQPlacement - BarEQPlacement)),
			DeltaTime, InterpSpeed);
		} else 
		{
			Z = FMath::FInterpTo(RelativeLocation.Z, FMath::Lerp(StartZ, TargetZ,
			GetLerpValue(CurrentRightEQPlacement - BarEQPlacement)),
			DeltaTime, InterpSpeed);
		}
		SetMaterialParams(Z);

		SetRelativeLocation(FVector(RelativeLocation.X, RelativeLocation.Y, Z));
	} 

	float GetLerpValue(float EQPlacementDifference)
	{
		return FMath::GetMappedRangeValueClamped(FVector2D(0.f, 0.15f), FVector2D(1.f, 0.f), FMath::Abs(EQPlacementDifference));
	}

	void SetMaterialParams(float NewZ)
	{
		float Alpha = FMath::GetMappedRangeValueClamped(FVector2D(StartZ, TargetZ), FVector2D(0.f, 1.f), NewZ);

		if (bControlledWithLeftStick)
			SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", (Blue * (1.f - Alpha) + BlueEmissive * Alpha));
		else
			SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", (Red * (1.f - Alpha) + RedEmissive * Alpha));
	}
}