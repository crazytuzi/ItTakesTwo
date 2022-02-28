import Cake.LevelSpecific.SnowGlobe.Magnetic.Scale.ScaleConnectedPlatformActor;

class UScaleConnectedPlatformCapability : UHazeCapability
{
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 1;

	AScaleConnectedPlatformActor Platform;

	float AddedFwd = 0.0f;
	bool bScaleIsActive = false;
	FVector OriginalLocation;
	bool bIsOut;

	bool bSupportFinished = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Platform = Cast<AScaleConnectedPlatformActor>(Owner);

		if(Platform.Pullcord != nullptr)
		{
			Platform.Pullcord.OnMagneticPullcordActivated.AddUFunction(this, n"PullcordActivated");
			Platform.Pullcord.OnMagneticPullcordDeactivated.AddUFunction(this, n"PullcordDeactivated");
		}

		OriginalLocation = Platform.Platform.RelativeLocation;	
		Platform.OnPlatformSupportFinished.AddUFunction(this, n"OnSupportFinished");
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!bScaleIsActive)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!bScaleIsActive && FMath::IsNearlyZero(AddedFwd, 0.1f))
			return EHazeNetworkDeactivation::DeactivateFromControl;	
	
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
	}
 
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		AddedFwd = 0.0f;
		Platform.Platform.SetRelativeLocation(OriginalLocation);
	}

	// UFUNCTION()
	// void MagneticScaleStateChanged(bool IsActive)
	// {
	// 	bScaleIsActive = IsActive;
	// }

	UFUNCTION()
	void OnSupportFinished()
	{
		bSupportFinished = true;
		if(!bScaleIsActive)
			Platform.Pullcord.OnMagneticPullcordReset.Broadcast();
	}

	UFUNCTION()
	void PullcordActivated(AHazePlayerCharacter Player)
	{
		bSupportFinished = false;
		bScaleIsActive = true;

		if(Player != nullptr)
		{
			FHazePointOfInterest PoISettings;
			PoISettings.Blend.BlendTime = 2.0f;
			PoISettings.FocusTarget.Actor = Owner;
			PoISettings.FocusTarget.WorldOffset = FVector(0, 0, -1000.0f);
			PoISettings.Duration = PoISettings.Blend.BlendTime;
			Player.ApplyPointOfInterest(PoISettings, this);
		}
		
		Platform.OnPlatformStateChanged.Broadcast(true, true);
		Platform.OnPlatformSupportStart.Broadcast();
	}


	UFUNCTION()
	void PullcordDeactivated()
	{
		bScaleIsActive = false;
		Platform.OnPlatformStateChanged.Broadcast(true, false);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(bSupportFinished && bScaleIsActive && !bIsOut)
		{
			float TargetFwdLocation = Platform.HowFarToPushOut;
			if(AddedFwd != TargetFwdLocation)
			{
				float Speed = Platform.MovementSpeed;

				if(TargetFwdLocation < AddedFwd)
					Speed *= -1;

				float DeltaFwd = Speed * DeltaTime;

				if(AddedFwd + DeltaFwd > TargetFwdLocation)
				{
					DeltaFwd = TargetFwdLocation - AddedFwd;
					Platform.OnPlatformStateChanged.Broadcast(false, true);
					Platform.Pullcord.OnMagneticPullcordStartTimer.Broadcast();
					bIsOut = true;
				}

				FVector DeltaMovement = FVector(DeltaFwd, 0, 0);
				Platform.Platform.AddLocalOffset(DeltaMovement);
				AddedFwd += DeltaFwd;
			}
		}
		else if(!bScaleIsActive && bIsOut)
		{
			float TargetFwdLocation = OriginalLocation.X;
			if(AddedFwd >= 0.0f)
			{
				float Speed = Platform.MoveBackSpeed;

				if(TargetFwdLocation < AddedFwd)
					Speed *= -1;

				float DeltaFwd = Speed * DeltaTime;

				if(AddedFwd + DeltaFwd < 0.0f)
				{
					DeltaFwd = 0.0f - AddedFwd;
					Platform.OnPlatformStateChanged.Broadcast(false, false);
					bSupportFinished = false;
					Platform.OnPlatformSupportStart.Broadcast();
					bIsOut = false;
				}

				FVector DeltaMovement = FVector(DeltaFwd, 0, 0);
				Platform.Platform.AddLocalOffset(DeltaMovement);
				AddedFwd += DeltaFwd;
			}
		}
		// float TargetFwdLocation = Platform.Scale.TotalPercentage * Platform.HowFarToPushOut;
		// if(AddedFwd != TargetFwdLocation)
		// {
		// 	float Speed = Platform.MovementSpeed;

		// 	if(TargetFwdLocation < AddedFwd)
		// 		Speed *= -1;

		// 	float DeltaFwd = Speed * DeltaTime;

		// 	if(AddedFwd + DeltaFwd > TargetFwdLocation || AddedFwd + DeltaFwd < TargetFwdLocation)
		// 		DeltaFwd = TargetFwdLocation - AddedFwd;

		// 	FVector DeltaMovement = FVector(DeltaFwd, 0, 0);
		// 	Platform.Platform.AddLocalOffset(DeltaMovement);
		// 	AddedFwd += DeltaFwd;
		// }

	}
}