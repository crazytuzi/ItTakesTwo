import Cake.LevelSpecific.SnowGlobe.Magnetic.SnowCannon.SnowCannonActor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.BaseMagneticComponent;
import Cake.LevelSpecific.SnowGlobe.Magnetic.MagneticTags;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagneticPlayerComponent;
import Vino.Movement.MovementSettings;

class USnowCannonPlayerAimCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MagnetCapability");
	default CapabilityTags.Add(n"SnowCannon");
	default CapabilityDebugCategory = CapabilityTags::LevelSpecific;
	default TickGroup = ECapabilityTickGroups::GamePlay;
	default TickGroupOrder = 1;

	AHazePlayerCharacter Player;
	UMagneticPlayerComponent PlayerMagnetComp;

	ASnowCannonActor SnowCannon;

	UPROPERTY()
	UForceFeedbackEffect CockRumble;

	UPROPERTY()
	UForceFeedbackEffect CooldownRumble;

	UPROPERTY()
	UHazeCameraSpringArmSettingsDataAsset CamSettings;

	UMagnetSnowCanonComponent ActivatedMagnet;

	float MaxZToAdd = 700.0f;

	FVector OriginalCameraOffset = FVector(0,0 , 700.0f);

	float IdealCameraDistance = 2000.0f;
	float MinCameraDistance = 1000.0f;

	float MaxAim = 0.2f;
	float MinAim = -0.5f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);
	}

	bool IsMagneticPathBlocked(bool IsOpposite) const
	{
		FHitResult Hit;
		TArray<AActor> ActorsToIgnore;
		ActorsToIgnore.Add(Game::GetCody());
		ActorsToIgnore.Add(Game::GetMay());

		System::LineTraceSingle(ActivatedMagnet.WorldLocation, PlayerMagnetComp.WorldLocation, ETraceTypeQuery::Visibility, false, ActorsToIgnore, EDrawDebugTrace::None, Hit, IsOpposite, FLinearColor::Green);

		return Hit.bBlockingHit;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if(!HasControl())
			return EHazeNetworkActivation::DontActivate;
		
		UMagnetSnowCanonComponent CurrentTargetedMagnet = Cast<UMagnetSnowCanonComponent>(PlayerMagnetComp.GetTargetedMagnet());
		if(CurrentTargetedMagnet == nullptr)
			return EHazeNetworkActivation::DontActivate;

		if(!CurrentTargetedMagnet.IsInfluencedBy(Player))
			return EHazeNetworkActivation::DontActivate;

		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if(!HasControl())
			return EHazeNetworkDeactivation::DontDeactivate;

		if(!PlayerMagnetComp.MagnetLockonIsActivatedBy(this))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(!IsActioning(ActionNames::PrimaryLevelAbility))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(ActivatedMagnet.IsMagneticPathBlocked(Player, PlayerMagnetComp))
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;

		if(SnowCannonDistance > ActivatedMagnet.GetDistance(EHazeActivationPointDistanceType::Selectable) + 1.0f)
			return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	float GetSnowCannonDistance() const property
	{
		float Distance = PlayerMagnetComp.WorldLocation.Distance(ActivatedMagnet.WorldLocation);
		return Distance;
	}


	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& ActivationParams)
	{
		UMagnetSnowCanonComponent TargetMagnet = Cast<UMagnetSnowCanonComponent>(PlayerMagnetComp.GetTargetedMagnet());
		ActivationParams.AddObject(n"CurrentMagnet", TargetMagnet);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Active);

		ActivatedMagnet = Cast<UMagnetSnowCanonComponent>(ActivationParams.GetObject(n"CurrentMagnet"));
		PlayerMagnetComp.ActivateMagnetLockon(ActivatedMagnet, this);

		SnowCannon = Cast<ASnowCannonActor>(ActivatedMagnet.Owner);

		if(PlayerMagnetComp == nullptr)
			PlayerMagnetComp = UMagneticPlayerComponent::Get(Player);

		if (PlayerMagnetComp.HasEqualPolarity(ActivatedMagnet))
		{
			//SnowCannon.bPushing = true;
			SnowCannon.ActivateSnowCannon(Player);
			Player.PlayForceFeedback(CockRumble, false, true, n"SnowCannonCharge");
			SnowCannon.SetCapabilityActionState(n"PushingSnowCannon", EHazeActionState::Active);
			return;
		}

		// Old nico speed 266.f
		UMovementSettings::SetMoveSpeed(Player, 500.f, this);
        
		FHazeCameraBlendSettings CamBlend;
		CamBlend.BlendTime = 2.f;
		Player.ApplyCameraSettings(CamSettings, CamBlend, this, EHazeCameraPriority::Medium);
		SnowCannon.ActivateSnowCannon(Player);

		FHazePointOfInterest PoISettings;
		PoISettings.Blend.BlendTime = 2.f;
		PoISettings.Duration = -1.0f;
		PoISettings.FocusTarget.Component = SnowCannon.CrosshairMesh;
		Player.ApplyPointOfInterest(PoISettings, this);

		SnowCannon.SetCapabilityActionState(n"PullingSnowCannon", EHazeActionState::Active);

		// Bind cannon delegates
		SnowCannon.OnThumperCocked.AddUFunction(this, n"OnCannonCocked");
		SnowCannon.OnCooldownCompleted.AddUFunction(this, n"OnCannonCooldownComplete");
	}
 
	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.ConsumeButtonInputsRelatedTo(ActionNames::PrimaryLevelAbility);

		Player.SetCapabilityActionState(FMagneticTags::IsUsingMagnet, EHazeActionState::Inactive);
		PlayerMagnetComp.DeactivateMagnetLockon(this);

		if (!PlayerMagnetComp.HasOppositePolarity(ActivatedMagnet))
		{
			SnowCannon.SetCapabilityActionState(n"PushingSnowCannon", EHazeActionState::Inactive);
			Player.ClearCameraSettingsByInstigator(this);
			SnowCannon = nullptr;
			return;
		}

		// Unbind delegates
		SnowCannon.OnThumperCocked.Unbind(this, n"OnCannonCocked");
		SnowCannon.OnCooldownCompleted.Unbind(this, n"OnCannonCooldownComplete");

		SnowCannon.SetCapabilityActionState(n"PullingSnowCannon", EHazeActionState::Inactive);
		SnowCannon.DeactivateSnowCannon();
		SnowCannon = nullptr;

		Player.ClearCameraSettingsByInstigator(this);
		Player.ClearPointOfInterestByInstigator(this);
		Player.ClearSettingsByInstigator(this);

		ActivatedMagnet = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (PlayerMagnetComp.HasEqualPolarity(ActivatedMagnet))
			return;

		float ChargeAlpha = Math::Saturate(ActiveDuration / SnowCannon.ThumperChargeAccelerationDuration);
		Player.SetFrameForceFeedback(0.011f * ChargeAlpha, 0.03f * ChargeAlpha);

		float Dot = FVector::UpVector.DotProduct(SnowCannon.ShootLocation.GetForwardVector());

		FVector PivotOffset = OriginalCameraOffset;
		if(Dot > MinAim && Dot < MaxAim)
		{
			float Percentage = (Dot - MinAim) / (MaxAim - MinAim);
			Percentage = 1 - Percentage;
			float AddPivot = MaxZToAdd * Percentage;
			PivotOffset.Z += AddPivot;
		}

		// FVector Distance = (Player.ActorLocation - SnowCannon.Head.WorldLocation) * 0.5f;
		// Distance += SnowCannon.Head.WorldLocation;
		// FVector PivotOffset = Player.ActorTransform.InverseTransformPosition(Distance);

		FHazeCameraSpringArmSettings Settings;
		Settings.bUseIdealDistance = true;
		Settings.IdealDistance = IdealCameraDistance;
		Settings.MinDistance = MinCameraDistance;
		Settings.bUsePivotOffset = true;
		Settings.PivotOffset = PivotOffset;

		Player.ApplyCameraSpringArmSettings(Settings, FHazeCameraBlendSettings(2.f), this, EHazeCameraPriority::Medium);
	}

	UFUNCTION(NotBlueprintCallable)
	void OnCannonCocked()
	{
		Player.PlayForceFeedback(CockRumble, false, true, n"SnowCannonAimCock");
	}

	UFUNCTION(NotBlueprintCallable)
	void OnCannonCooldownComplete()
	{
		Player.PlayForceFeedback(CooldownRumble, false, true, n"SnowCannonAimCooldown", 0.4f);
	}
}