enum EGateLampColor
{  
    Yellow,
	Red,
	Green,
	Purple
};

UCLASS(Abstract, HideCategories = "Cooking Replication Input Actor Capability LOD")
class ALargePillowGate : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftGateRoot;
	default LeftGateRoot.RelativeLocation = FVector(-2000.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightGateRoot;
	default RightGateRoot.RelativeLocation = FVector(2000.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = LeftGateRoot)
	UStaticMeshComponent LeftGateMesh;
	default LeftGateMesh.RelativeLocation = FVector(1500.f, 0.f, 510.f);

	UPROPERTY(DefaultComponent, Attach = RightGateRoot)
	UStaticMeshComponent RightGateMesh;
	default RightGateMesh.RelativeLocation = FVector(-500.f, 0.f, 510.f);
	
	UPROPERTY(DefaultComponent, Attach = LeftGateMesh)
	UStaticMeshComponent LeftLampYellow;
	default LeftLampYellow.RelativeLocation = FVector(480.f, -400.f, 4000.f);
	default LeftLampYellow.RelativeRotation = FRotator(-180.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = LeftGateMesh)
	UStaticMeshComponent LeftLampRed;
	default LeftLampRed.RelativeLocation = FVector(480.f, -400.f, 3000.f);
	default LeftLampRed.RelativeRotation = FRotator(-180.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = LeftGateMesh)
	UStaticMeshComponent LeftLampGreen;
	default LeftLampGreen.RelativeLocation = FVector(480.f, -400.f, 2000.f);
	default LeftLampGreen.RelativeRotation = FRotator(-180.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = LeftGateMesh)
	UStaticMeshComponent LeftLampPurple;
	default LeftLampPurple.RelativeLocation = FVector(480.f, -400.f, 1000.f);
	default LeftLampPurple.RelativeRotation = FRotator(-180.f, 0.f, 0.f);

	UPROPERTY(DefaultComponent, Attach = RightGateMesh)
	UStaticMeshComponent RightLampYellow;
	default RightLampYellow.RelativeLocation = FVector(-1480.f, -400.f, 4000.f);

	UPROPERTY(DefaultComponent, Attach = RightGateMesh)
	UStaticMeshComponent RightLampRed;
	default RightLampRed.RelativeLocation = FVector(-1480.f, -400.f, 3000.f);

	UPROPERTY(DefaultComponent, Attach = RightGateMesh)
	UStaticMeshComponent RightLampGreen;
	default RightLampGreen.RelativeLocation = FVector(-1480.f, -400.f, 2000.f);

	UPROPERTY(DefaultComponent, Attach = RightGateMesh)
	UStaticMeshComponent RightLampPurple;
	default RightLampPurple.RelativeLocation = FVector(-1480.f, -400.f, 1000.f);

	UPROPERTY()
	FLinearColor Yellow;

	UPROPERTY()
	FLinearColor Red;

	UPROPERTY()
	FLinearColor Green;
	
	UPROPERTY()
	FLinearColor Purple;

	UPROPERTY()
	FLinearColor Black;

	UPROPERTY()
	FLinearColor BrightYellow;

	UPROPERTY()
	FLinearColor BrightRed;

	UPROPERTY()
	FLinearColor BrightGreen;

	UPROPERTY()
	FLinearColor BrightPurple;

	UPROPERTY()
	FHazeTimeLike OpenGateTimeline;
	default OpenGateTimeline.Duration = 3.f;

	UPROPERTY()
	FHazeTimeLike LightLampTimeline;
	default LightLampTimeline.Duration = 1.f;

	UPROPERTY()
	EGateLampColor GateLampColor;
	
	UStaticMeshComponent LeftStaticMeshToLerp;
	UStaticMeshComponent RightStaticMeshToLerp;
	FLinearColor ColorToLerp;

	FRotator StartingLeftRot;
	FRotator TargetLeftRot;
	FRotator StartingRightRot;
	FRotator TargetRightRot;

	int LightCounter;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		OpenGateTimeline.BindUpdate(this, n"OpenGateTimelineUpdate");
		LightLampTimeline.BindUpdate(this, n"LightLampTimelineUpdate");

		StartingLeftRot = LeftGateRoot.RelativeRotation;
		TargetLeftRot = FRotator(StartingLeftRot + FRotator(0.f, -60.f, 0.f));

		StartingRightRot = RightGateRoot.RelativeRotation;
		TargetRightRot = FRotator(StartingRightRot + FRotator(0.f, 60.f, 0.f));
		
		SetLampColors();		
	}

	UFUNCTION()
	void LightUpLamp(UStaticMeshComponent LeftLampMeshComp, UStaticMeshComponent RightLampMeshComp, FLinearColor Color)
	{
		LeftStaticMeshToLerp = LeftLampMeshComp;
		RightStaticMeshToLerp = RightLampMeshComp;
		ColorToLerp = Color;
		LightLampTimeline.PlayFromStart();
	}

	UFUNCTION()
	void PressurePlateTriggered(EGateLampColor PressedGateLampColor)
	{
		switch(PressedGateLampColor)
		{
			case EGateLampColor::Yellow:
				LightUpLamp(LeftLampYellow, RightLampYellow, BrightYellow);
			break;

			case EGateLampColor::Red:
				LightUpLamp(LeftLampRed, RightLampRed, BrightRed);
			break;

			case EGateLampColor::Green:
				LightUpLamp(LeftLampGreen, RightLampGreen, BrightGreen);
			break;

			case EGateLampColor::Purple:
				LightUpLamp(LeftLampPurple, RightLampPurple, BrightPurple);
			break;
		}

		LightCounter++;

		if (LightCounter == 4)
		{
			System::SetTimer(this, n"OpenGateTimer", 2.f, false);
		}
	}

	UFUNCTION()
	void OpenGateTimer()
	{
		OpenGateTimeline.PlayFromStart();
	}

	UFUNCTION()
	void OpenGateTimelineUpdate(float CurrentValue)
	{
		RightGateRoot.SetRelativeRotation(QuatLerp(StartingRightRot, TargetRightRot, CurrentValue));
		LeftGateRoot.SetRelativeRotation(QuatLerp(StartingLeftRot, TargetLeftRot, CurrentValue));
	}

	UFUNCTION()
	void LightLampTimelineUpdate(float CurrentValue)
	{
		FLinearColor NewColor = FLinearColor(FMath::Lerp(Black.R, ColorToLerp.R, CurrentValue), 
											FMath::Lerp(Black.G, ColorToLerp.G, CurrentValue), 
											FMath::Lerp(Black.B, ColorToLerp.B, CurrentValue), 
											FMath::Lerp(Black.A, ColorToLerp.A, CurrentValue));

		LeftStaticMeshToLerp.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", NewColor);
		RightStaticMeshToLerp.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", NewColor);
	}

	void SetLampColors()
	{
		LeftLampYellow.SetColorParameterValueOnMaterialIndex(0, n"AlbedoColor", Yellow);
		LeftLampYellow.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", Black);
		RightLampYellow.SetColorParameterValueOnMaterialIndex(0, n"AlbedoColor", Yellow);
		RightLampYellow.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", Black);

		LeftLampRed.SetColorParameterValueOnMaterialIndex(0, n"AlbedoColor", Red);
		LeftLampRed.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", Black);
		RightLampRed.SetColorParameterValueOnMaterialIndex(0, n"AlbedoColor", Red);
		RightLampRed.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", Black);

		LeftLampGreen.SetColorParameterValueOnMaterialIndex(0, n"AlbedoColor", Green);
		LeftLampGreen.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", Black);
		RightLampGreen.SetColorParameterValueOnMaterialIndex(0, n"AlbedoColor", Green);
		RightLampGreen.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", Black);

		LeftLampPurple.SetColorParameterValueOnMaterialIndex(0, n"AlbedoColor", Purple);
		LeftLampPurple.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", Black);
		RightLampPurple.SetColorParameterValueOnMaterialIndex(0, n"AlbedoColor", Purple);
		RightLampPurple.SetColorParameterValueOnMaterialIndex(0, n"EmissiveColor", Black);
	}

	FRotator QuatLerp(FRotator A, FRotator B, float Alpha)
    {
		FQuat AQuat(A);
		FQuat BQuat(B);
		FQuat Result = FQuat::Slerp(AQuat, BQuat, Alpha);
		Result.Normalize();
		return Result.Rotator();
    }
}