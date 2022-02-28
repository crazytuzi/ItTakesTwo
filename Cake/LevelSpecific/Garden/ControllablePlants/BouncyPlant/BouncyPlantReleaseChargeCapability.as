import Cake.LevelSpecific.Garden.ControllablePlants.BouncyPlant.BouncyPlant;

class UBouncyPlantReleaseChargeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	default CapabilityTags.Add(n"BouncyPlantRelease");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 8;
	
	ABouncyPlant BouncyPlant;

	UCameraShakeBase CameraShakeHandle;

	float ReleaseAlpha = 0.0f;
	float ReleaseSpeed = 2.0f;
	bool bResetDone = false;

	float StartZScale = 0.0f;

	UFUNCTION(BlueprintOverride)
	void Setup(const FCapabilitySetupParams& SetupParams)
	{
		BouncyPlant = Cast<ABouncyPlant>(Owner);
		//CrumbComp = UHazeCrumbComponent::Get(Owner);
		
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!BouncyPlant.bIsCharging)
			return EHazeNetworkActivation::DontActivate;

		if(BouncyPlant.FireRate > 0)
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateFromControl;
		
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		float ChargedVelocity = FMath::Lerp(BouncyPlant.DefaultVerticalVelocity, BouncyPlant.HighVerticalVelocity, BouncyPlant.ChargeAlpha);
		ActivationParams.AddValue(n"ChargedVelocity", ChargedVelocity);

		ActivationParams.AddValue(n"ZScale",  BouncyPlant.PlantMesh.RelativeScale3D.Z);

		if(BouncyPlant.TimeLeftForSuperBounce > 0.0f)
			ActivationParams.AddActionState(n"SuperBounce");
	}	

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		float ChargedVelocity = ActivationParams.GetValue(n"ChargedVelocity");
		BouncyPlant.VerticalVelocity = ChargedVelocity;
		
		BouncyPlant.bBurstActivated = true;

		BouncyPlant.bIsCharging = false;
		BouncyPlant.ChargeAlpha = 0.0f;
		StartZScale = ActivationParams.GetValue(n"ZScale");

		if(ActivationParams.GetActionState(n"SuperBounce")) //Make it so it only happens after certain charge
		{

			if(!BouncyPlant.bTutorialCompleted)
			{
				BouncyPlant.bTutorialCompleted = true;
			}

			auto May = Game::GetMay();
			if(May.HasControl())
			{
				FVector Impulse = BouncyPlant.ActorUpVector * ChargedVelocity;
				auto MoveComp = UHazeMovementComponent::Get(May);
				MoveComp.SetVelocity(Impulse);
				MoveComp.AddImpulse(Impulse);
			}

			Niagara::SpawnSystemAtLocation(BouncyPlant.SuperBounceEffect, BouncyPlant.EffectSceneComp.WorldLocation, BouncyPlant.EffectSceneComp.WorldRotation);
			BouncyPlant.SetCapabilityActionState(n"AudioSuperBounce", EHazeActionState::ActiveForOneFrame);
		}

		if(BouncyPlant.HasControl())
			BouncyPlant.SyncChargeProgress.Value = 0.0f;

		Game::GetCody().PlayForceFeedback(BouncyPlant.ReleaseChargeForceFeedback, false, true, n"BouncyPlant");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		BouncyPlant.bBurstActivated = false;

		ReleaseAlpha = 0.0f;
		bResetDone = false;
		BouncyPlant.VerticalVelocity = BouncyPlant.DefaultVerticalVelocity;

		// if(BouncyPlant.HasControl())
		// 	BouncyPlant.SyncSize.Value = FVector::OneVector;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(bResetDone)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		ReleaseAlpha += DeltaTime * ReleaseSpeed;
		ReleaseAlpha = FMath::Clamp(ReleaseAlpha, 0.0f, 1.0f);

		float Alpha = BouncyPlant.ReleaseCurve.GetFloatValue(ReleaseAlpha);
		//float PlantZSize = FMath::Lerp(StartZScale, 1.0f, Alpha);
		//BouncyPlant.PlantMesh.SetRelativeScale3D(FVector(1.0f, 1.0f, PlantZSize));

		if(ReleaseAlpha >= 1.0f)
			bResetDone = true;
	}
}
