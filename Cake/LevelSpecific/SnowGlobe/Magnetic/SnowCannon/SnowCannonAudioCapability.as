import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.SnowCannonActor;

class USnowCannonAudioCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetCapability");
	default CapabilityTags.Add(n"SnowCannon");
	default CapabilityTags.Add(n"SnowCannonAudio");

	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;

	default TickGroup = ECapabilityTickGroups::AfterGamePlay;
	default TickGroupOrder = 130;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	UHazeAkComponent HazeAkComponent;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent OnStartInteract;
		
	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent OnStopInteract;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent ChargeStarted;
		
	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent ChargeFull;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent ShotFired;
		
	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent ReloadStarted;

	UPROPERTY(Category = "AudioEvents")
	UAkAudioEvent ReloadFinished;

	ASnowCannonActor SnowCannonOwner;
	AHazePlayerCharacter ControllingPlayer;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		SnowCannonOwner = Cast<ASnowCannonActor>(Owner);
		HazeAkComponent = UHazeAkComponent::GetOrCreate(Owner);

		// Bind delegates
		SnowCannonOwner.OnActivated.AddUFunction(this, n"OnSnowCannonActivated");
		SnowCannonOwner.OnDeactivated.AddUFunction(this, n"OnSnowCannonDeactivated");
		SnowCannonOwner.OnShoot.AddUFunction(this, n"OnShoot");
		SnowCannonOwner.OnThumperCockStarted.AddUFunction(this, n"OnChargeStarted");
		SnowCannonOwner.OnThumperCocked.AddUFunction(this, n"OnCharged");
		SnowCannonOwner.OnReloadStarted.AddUFunction(this, n"OnReloadStarted");
		SnowCannonOwner.OnReloadCompleted.AddUFunction(this, n"OnReloadCompleted");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!SnowCannonOwner.bActivated)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateLocal;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ControllingPlayer = SnowCannonOwner.ControllingPlayer;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		// Update thumper charge progress
		if(!SnowCannonOwner.bThumperCocked)
		{
			float ChargeProgress = 0.f;
			ConsumeAttribute(n"ThumperCockProgress", ChargeProgress);

			// TODO: Update ak comp with cooldownProgress var!
		}

		// Get delta rotation values
		float DeltaPitch = 0.f, DeltaYaw = 0.f;
		ConsumeAttribute(n"DeltaPitch", DeltaPitch);
		ConsumeAttribute(n"DeltaYaw", DeltaYaw);

		// TODO: Update ak comp with deltaPitch/yaw
		float NormPitch = HazeAudio::NormalizeRTPC01(FMath::Abs(DeltaPitch), 0.1f, 0.4f);

		float NormYaw = HazeAudio::NormalizeRTPC01(FMath::Abs(DeltaYaw), 0.1f, 0.5f);

		HazeAkComponent.SetRTPCValue("Rtpc_Weapons_Cannons_MagnetCannon_Pitch", NormPitch, 0.f);

		// Print("Pitch" + NormPitch);

		HazeAkComponent.SetRTPCValue("Rtpc_Weapons_Cannons_MagnetCannon_Yaw", NormYaw, 0.f);

		// Print("Yaw" + NormYaw);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!SnowCannonOwner.bActivated)
			return EHazeNetworkDeactivation::DeactivateLocal;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSnowCannonActivated()
	{
		HazeAkComponent.HazePostEvent(OnStartInteract);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnSnowCannonDeactivated()
	{
		HazeAkComponent.HazePostEvent(OnStopInteract);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnShoot()
	{
		HazeAkComponent.HazePostEvent(ShotFired);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnChargeStarted()
	{
		HazeAkComponent.HazePostEvent(ChargeStarted);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnCharged()
	{
		HazeAkComponent.HazePostEvent(ChargeFull);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnReloadStarted()
	{
		HazeAkComponent.HazePostEvent(ReloadStarted);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnReloadCompleted()
	{
		HazeAkComponent.HazePostEvent(ReloadFinished);
	}
}