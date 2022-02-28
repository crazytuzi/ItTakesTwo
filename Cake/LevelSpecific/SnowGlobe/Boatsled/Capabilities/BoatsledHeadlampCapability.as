import Cake.LevelSpecific.SnowGlobe.Boatsled.BoatsledComponent;
class UBoatsledHeadlampCapability : UHazeCapability
{
	default CapabilityTags.Add(BoatsledTags::Boatsled);
	default CapabilityTags.Add(BoatsledTags::BoatsledHeadlampCapability);

	default CapabilityDebugCategory = BoatsledTags::Boatsled;

	ABoatsled Boatsled;

	UMaterialInstanceDynamic BoatsledHeadlampMaterial;

	FLinearColor EmissiveOrigin;
	FLinearColor EmissiveTarget;

	float LerpTime;

	float IntensityOrigin;
	float IntensityTarget;

	bool bSwitchOn;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		UBoatsledComponent BoatsledComponent = UBoatsledComponent::Get(Owner);
		Boatsled = BoatsledComponent.Boatsled;

		BoatsledHeadlampMaterial = Boatsled.DynamicHeadlampMaterialInstance;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(IsActioning(BoatsledTags::SwitchHeadlampOn))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		if(IsActioning(BoatsledTags::SwitchHeadlampOff))
			return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& SyncParams)
	{
		if(IsActioning(BoatsledTags::SwitchHeadlampOn))
			SyncParams.AddActionState(n"SwitchOn");
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		if(bSwitchOn = ActivationParams.GetActionState(n"SwitchOn"))
		{
			LerpTime = 0.8f;

			IntensityOrigin = 0.f;
			IntensityTarget = Boatsled.OriginalSpotLightIntensity;

			EmissiveOrigin = FLinearColor(0.f, 0.f, 0.f, 0.5f);
			EmissiveTarget = Boatsled.OriginalBoatsledMaterialEmissive;

			Boatsled.SpotLightLarge.SetVisibility(true);
		}
		else
		{
			LerpTime = 0.1f;

			IntensityOrigin = Boatsled.OriginalSpotLightIntensity;
			IntensityTarget = 0.f;

			EmissiveOrigin = Boatsled.OriginalBoatsledMaterialEmissive;
			EmissiveTarget = FLinearColor(0.f, 0.f, 0.f, 0.5f);
		}
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		float LerpAlpha = FMath::Pow((FMath::Min(ActiveDuration, LerpTime) / LerpTime), 3.f);

		float Intensity = FMath::Lerp(IntensityOrigin, IntensityTarget, LerpAlpha);
		Boatsled.SpotLightLarge.SetIntensity(Intensity);

		FLinearColor Emissive = FMath::Lerp(EmissiveOrigin, EmissiveTarget, LerpAlpha);
		BoatsledHeadlampMaterial.SetVectorParameterValue(n"Emissive Tint", Emissive);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(ActiveDuration >= LerpTime)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Boatsled.SpotLightLarge.SetIntensity(IntensityTarget);

		BoatsledHeadlampMaterial.SetVectorParameterValue(n"Emissive Tint", EmissiveTarget);

		if(!bSwitchOn)
			Boatsled.SpotLightLarge.SetVisibility(false);

		// Clear stuff
		LerpTime = 0.f;
		IntensityOrigin = 0.f;
		IntensityTarget = 0.f;
		bSwitchOn = false;
	}
}