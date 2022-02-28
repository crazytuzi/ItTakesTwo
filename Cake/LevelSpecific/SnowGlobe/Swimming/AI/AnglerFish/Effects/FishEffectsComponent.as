import Cake.Environment.Godray;
import Cake.Environment.HazeSphere;
import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Settings.FishComposableSettings;

event void FFishSwitchEffectsMode(EFishEffectsMode Mode);

class UFishEffectsComponent : UActorComponent
{
	EFishEffectsMode CurrentMode = EFishEffectsMode::None;

	UPROPERTY(NotVisible)
	UStaticMeshComponent Lantern;

	UPROPERTY(NotVisible)
	USpotLightComponent Spotlight;

	UPROPERTY(NotVisible)
	UStaticMeshComponent Godray;

	UPROPERTY(NotVisible)
	UStaticMeshComponent LightCone;

	UPROPERTY(NotVisible)
	UHazeCameraComponent MawCamera;

	UPROPERTY(NotVisible)
	UHazeSphereComponent LanternHazeSphere;

	UPROPERTY(NotVisible)
	UPointLightComponent LanternPointLight;

	UPROPERTY(Category = "AnglerFish")
	FFishSwitchEffectsMode OnSwitchMode;

	FHazeAcceleratedFloat ColorRed;
	FHazeAcceleratedFloat ColorGreen;
	FHazeAcceleratedFloat ColorBlue;
	FHazeAcceleratedFloat ColorAlpha;

	FHazeAcceleratedFloat LightConeColorFactor;
	FHazeAcceleratedFloat MeshColorFactor;
	FHazeAcceleratedFloat SphereColorFactor;
	FHazeAcceleratedFloat PointLightColorFactor;
	FHazeAcceleratedFloat SpotLightColorFactor;
	FHazeAcceleratedFloat GodrayColorFactor;

	AHazeCharacter CharOwner = nullptr;
	UFishComposableSettings Settings;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		CharOwner = Cast<AHazeCharacter>(Owner);
		Settings = UFishComposableSettings::GetSettings(Cast<AHazeActor>(Owner));

		ColorRed.SnapTo(Settings.IdleColor.R);
		ColorGreen.SnapTo(Settings.IdleColor.G);
		ColorBlue.SnapTo(Settings.IdleColor.B);
		ColorAlpha.SnapTo(Settings.IdleColor.A);
	}

	void UpdateEffect(float DeltaSeconds)
	{
		float Duration = Settings.ToIdleBlendDuration;
		if (CurrentMode == EFishEffectsMode::Attack)
			Duration = Settings.ToAttackBlendDuration;
		else if (CurrentMode == EFishEffectsMode::Searching)
			Duration = Settings.ToSearchingBlendDuration;

		FLinearColor TargetColor = Settings.IdleColor;
		if (CurrentMode == EFishEffectsMode::Attack)
			TargetColor = Settings.AttackColor;
		else if (CurrentMode == EFishEffectsMode::Searching)
			TargetColor = Settings.SearchingColor;

		FLinearColor Color;
		Color.R = ColorRed.AccelerateTo(TargetColor.R, Duration, DeltaSeconds);	
		Color.G = ColorGreen.AccelerateTo(TargetColor.G, Duration, DeltaSeconds);	
		Color.B = ColorBlue.AccelerateTo(TargetColor.B, Duration, DeltaSeconds);	
		Color.A = ColorAlpha.AccelerateTo(TargetColor.A, Duration, DeltaSeconds);	

		float FactorDuration = Duration;
		if (CurrentMode != EFishEffectsMode::Idle)
			FactorDuration * 1.f;

		GodrayColorFactor.AccelerateTo(Settings.GodrayColorFactor.GetFactor(CurrentMode), FactorDuration, DeltaSeconds);
		Godray.SetVectorParameterValueOnMaterialIndex(0, n"Color", ColorToVector(Color * GodrayColorFactor.Value));

		SpotLightColorFactor.AccelerateTo(Settings.SpotLightColorFactor.GetFactor(CurrentMode), FactorDuration, DeltaSeconds);
		Spotlight.SetLightColor(Color * SpotLightColorFactor.Value);
		
		PointLightColorFactor.AccelerateTo(Settings.PointLightColorFactor.GetFactor(CurrentMode), FactorDuration, DeltaSeconds);
		LanternPointLight.SetLightColor(Color);
		LanternPointLight.SetIntensity(Settings.PointLightIntensity * PointLightColorFactor.Value);

		SphereColorFactor.AccelerateTo(Settings.HazeSphereColorFactor.GetFactor(CurrentMode), FactorDuration, DeltaSeconds);
		LanternHazeSphere.SetColor(Settings.HazeSphereOpacity, Settings.HazeSphereSoftness, Color * SphereColorFactor.Value);

		MeshColorFactor.AccelerateTo(Settings.MeshEmissiveColorFactor.GetFactor(CurrentMode), FactorDuration, DeltaSeconds);
		CharOwner.Mesh.SetColorParameterValueOnMaterialIndex(3, n"Emissive Tint", Color * MeshColorFactor.Value);

		LightConeColorFactor.AccelerateTo(Settings.LightConeColorFactor.GetFactor(CurrentMode), FactorDuration, DeltaSeconds);
		LightCone.SetVectorParameterValueOnMaterialIndex(0, n"Color", ColorToVector(Color * LightConeColorFactor.Value));
	}

	UFUNCTION()
	void SetEffectsMode(EFishEffectsMode Mode)
	{
		if (CurrentMode == Mode)
		 	return;
		CurrentMode = Mode;
		OnSwitchMode.Broadcast(Mode);
	}

	FVector ColorToVector(const FLinearColor& Color)
	{
		return FVector(Color.R, Color.G, Color.B) * Color.A;
	}
}