import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SynthDoorStatics;

class USynthDoorComponent : UStaticMeshComponent
{
	UPROPERTY()
	ESynthDoorMeterType SynthDoorMeterType;

	ESynthDoorComponentIntensity SynthDoorComponentIntensity;

	int PulseIntensity = 0;
	float InterpSpeed = 4.f;

	FVector TargetScale = FVector(1.f, 1.f, 1.f);

	FVector CurrentColor;
	FVector NewColor;

	FVector Green = FVector(0.f, 5.f, 0.f);
	FVector Yellow = FVector(5.f, 5.f, 0.f);
	FVector Red = FVector(5.f, 0.f, 0.f);

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{

	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		SetRelativeScale3D(FMath::VInterpTo(RelativeScale3D, TargetScale, DeltaTime, InterpSpeed));
		
		FVector NewInterpedColor = FMath::VInterpTo(CurrentColor, NewColor, DeltaTime, InterpSpeed);
		SetVectorParameterValueOnMaterialIndex(0, n"EmissiveColor", FMath::VInterpTo(CurrentColor, NewColor, DeltaTime, InterpSpeed));

		CurrentColor = NewInterpedColor;
	}
	
	UFUNCTION()
	void PulseSynthMeter(bool bShouldPulse)
	{
		if (!bShouldPulse)
			return;

		FVector NewPulseScale = RelativeScale3D;
		NewPulseScale.Z += FMath::RandRange(0.5f, 4.f);
		SetRelativeScale3D(NewPulseScale);
	}

	UFUNCTION()
	void UpdateIntensity(ESynthDoorComponentIntensity NewIntensity)
	{
		SynthDoorComponentIntensity = NewIntensity;
		
		switch (NewIntensity)
		{
			case ESynthDoorComponentIntensity::Low:
			TargetScale.Z = 1.f;
			NewColor = Yellow;
			break;

			case ESynthDoorComponentIntensity::Medium:
			TargetScale.Z = 7.5f;
			NewColor = Green;
			break;

			case ESynthDoorComponentIntensity::High:
			TargetScale.Z = 15.f;
			NewColor = Red;
			break;
		}
	}
}