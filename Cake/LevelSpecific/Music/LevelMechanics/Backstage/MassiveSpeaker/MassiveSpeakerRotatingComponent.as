import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MassiveSpeaker.MassiveSpeakerVolumeControl;

class UMassiveSpeakerRotatingComponent : UActorComponent
{	
	UPROPERTY()
	AMassiveSpeakerVolumeControl VolumeControl;
	
	UPROPERTY()
	float RotationSpeed;

	UPROPERTY()
	float PointLightStrength;

	UPROPERTY()
	APointLight PointLight;

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (VolumeControl.ProgressPercentage > 0)
		{
			FRotator DeltaRot;
			DeltaRot.Roll = RotationSpeed * FMath::Pow(VolumeControl.ProgressPercentage, 2.f) * 0.03f;
			Owner.AddActorLocalRotation(DeltaRot);

			float Intensity = PointLightStrength * FMath::Pow(VolumeControl.ProgressPercentage, 2.f) * 0.03f;
			PointLight.PointLightComponent.SetIntensity(Intensity);
			//Print("" + Intensity);
		}
	}
}