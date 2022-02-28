import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SynthDoorStatics;

class EqVuMeter : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent MeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeshRoot)
	UStaticMeshComponent VuBaseMesh;

	UPROPERTY(DefaultComponent, Attach = VuBaseMesh)
	USceneComponent MeterMeshRoot;

	UPROPERTY(DefaultComponent, Attach = MeterMeshRoot)
	UStaticMeshComponent VuMeterMesh;

	float CurrentPitch = 0.f;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		CurrentPitch = FMath::FInterpTo(CurrentPitch, 0.f, DeltaSeconds, 1.f);
		MeterMeshRoot.SetRelativeRotation(FRotator(CurrentPitch, 0.f, 0.f));
	}

	UFUNCTION()
	void GiveVuMeterPulse(ESynthDoorComponentIntensity PulseIntensity)
	{
		switch (PulseIntensity)
		{			
			case ESynthDoorComponentIntensity::Low:
				CurrentPitch = FMath::RandRange(-25.f, -35.f);
				break;

			case ESynthDoorComponentIntensity::Medium:
				CurrentPitch = FMath::RandRange(-60.f, -70.f);
				break;

			case ESynthDoorComponentIntensity::High:
				CurrentPitch = FMath::RandRange(-100.f, -110.f);
				break;
		}
	}
}