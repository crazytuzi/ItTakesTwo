import Cake.LevelSpecific.SnowGlobe.Magnetic.PlayerMagnetActor;

class UPlayerMagnetEmissiveCapability : UHazeCapability
{
	default CapabilityTags.Add(FMagneticTags::MagneticCapabilityTag);
	default CapabilityTags.Add(FMagneticTags::MagnetEmissiveCapability);

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	UPROPERTY()
	FLinearColor MayEmissive = FLinearColor(0.f, 0.f, 1.f);

	UPROPERTY()
	FLinearColor CodyEmissive = FLinearColor(1.f, 0.f, 0.f);

	APlayerMagnetActor MagnetOwner;

	const FName EmissiveParameter = n"Emissive Tint";
	float EmissionLerpDuration;

	FLinearColor EmissionLerpStart;
	FLinearColor EmissionLerpTarget;
	FLinearColor CurrentEmissionValue;

	float ElapsedLerpTime;
	bool bIsLerpingEmissive;

	bool bMagnetActivated;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		MagnetOwner = Cast<APlayerMagnetActor>(Owner);
		MagnetOwner.OnMagnetActivated.AddUFunction(this, n"OnMagnetActivated");
		MagnetOwner.OnMagnetDeactivated.AddUFunction(this, n"OnMagnetDeactivated");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!bMagnetActivated)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		// Begin emissive lerp
		EmissionLerpStart = FLinearColor::Black;
		EmissionLerpTarget = MagnetOwner.OwningPlayer.IsMay() ? MayEmissive : CodyEmissive;

		ElapsedLerpTime = 0.f;
		EmissionLerpDuration = 0.2f;

		bIsLerpingEmissive = true;
	}

	UFUNCTION(BlueprintOverride)
	void PreTick(float DeltaTime)
	{
		if(!bIsLerpingEmissive)
			return;

		ElapsedLerpTime += DeltaTime;
		float EmissionLerpAlpha = Math::Saturate(ElapsedLerpTime / EmissionLerpDuration);
		if(EmissionLerpAlpha >= 1.f)
		{
			bIsLerpingEmissive = false;
			EmissionLerpAlpha = 1.f;
		}

		CurrentEmissionValue = FMath::Lerp(EmissionLerpStart, EmissionLerpTarget, EmissionLerpAlpha);
		MagnetOwner.MagnetMesh.SetColorParameterValueOnMaterialIndex(0, EmissiveParameter, CurrentEmissionValue);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!bMagnetActivated)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		// Initialize emissive lerp blend out
		EmissionLerpTarget = FLinearColor::Black;
		EmissionLerpStart = CurrentEmissionValue;

		ElapsedLerpTime = 0.f;
		EmissionLerpDuration = 0.1f;

		bIsLerpingEmissive = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnMagnetActivated(UMagneticComponent ActivatedMagnet, bool bEqualPolarities)
	{
		bMagnetActivated = true;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnMagnetDeactivated(UMagneticComponent DeactivatedMagnet, bool bEqualPolarities)
	{
		bMagnetActivated = false;
	}
}