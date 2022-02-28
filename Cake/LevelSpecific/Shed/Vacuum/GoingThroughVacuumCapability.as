import Cake.LevelSpecific.Shed.Vacuum.VacuumHoseActor;
import Peanuts.Outlines.Outlines;
import Vino.Movement.MovementSystemTags;
import Vino.Audio.Music.MusicManagerActor;
import Cake.LevelSpecific.Shed.VOBanks.VacuumVOBank;
import Vino.Movement.Components.MovementComponent;
import Vino.Audio.Movement.PlayerMovementAudioComponent;
import Peanuts.Audio.HazeAudioManager.AudioManagerStatics;

UCLASS(Abstract)
class UGoingThroughVacuumCapability : UHazeCapability
{
    default CapabilityTags.Add(n"GameplayAction");
    default CapabilityTags.Add(n"Vacuum");
    default CapabilityTags.Add(n"LevelSpecific");

    default TickGroup = ECapabilityTickGroups::ActionMovement;
    default TickGroupOrder = 10;

	AHazePlayerCharacter Player;
	UPlayerHazeAkComponent HazeAkComp;
	UHazeAkComponent MusicManagerHazeAkComp; 
    AVacuumHoseActor Hose;
	UHazeCrumbComponent CrumbComp;
	UHazeMovementComponent MoveComp;

    UPROPERTY()
    UHazeCameraSpringArmSettingsDataAsset CameraSettings;

    UPROPERTY()
    UForceFeedbackEffect EnterHoseForceFeedBack;

    UPROPERTY()
    UAnimSequence CodyInsideAnimation;

    UPROPERTY()
    UAnimSequence MayInsideAnimation;

	UPROPERTY()
	UVacuumVOBank VOBank;

	UPROPERTY()
	UAkAuxBus InsideHoseVOReverb;

    float DistanceAlongHose;
	float AlphaAlongHose;
	float SpeedThroughHose;
	float CurrentTilt;

	FVector CurrentAngularVelocity;
	FVector PreviousAngularVelocity;
	float AngularVelocity;

    EVacuumMountLocation LaunchLocation;

	float TimeUntilLaunch;
	float LaunchPrepareTime = 1.f;

	FTimerHandle ExitPrepareHandle;

	bool bCollisionBlockedInternally = true;

	FTimerHandle BarkHandle;

	FVector PreviousRemoteLocation;
	
	UHazeAudioManager AudioManager;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		HazeAkComp = UPlayerHazeAkComponent::Get(Player);		
		CrumbComp = UHazeCrumbComponent::GetOrCreate(Player);
		MoveComp = UHazeMovementComponent::GetOrCreate(Player);
		AudioManager = GetAudioManager();
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{
		if (!bCollisionBlockedInternally && IsActive())
			Player.UnblockCapabilities(CapabilityTags::Collision, Hose);

		bCollisionBlockedInternally = true;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"GoingThroughVacuum"))
            return EHazeNetworkActivation::ActivateUsingCrumb;
        else
            return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (!IsActioning(n"GoingThroughVacuum"))
		    return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        else
		    return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		DistanceAlongHose = GetAttributeValue(n"StartDistance");
		OutParams.AddNumber(n"StartDist", DistanceAlongHose);
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		DistanceAlongHose = ActivationParams.GetNumber(n"StartDist");

        Hose = Cast<AVacuumHoseActor>(GetAttributeObject(n"Hose"));

        FHazeCameraBlendSettings BlendSettings;
        BlendSettings.BlendTime = 0.5f;

        if (Hose.bLockMinDistance)
		{
			FHazeCameraSpringArmSettings Settings;
			Settings.bUseMinDistance = true;
			Settings.MinDistance = Hose.IdealDistance;
			Player.ApplyCameraSpringArmSettings(Settings, FHazeCameraBlendSettings(1.f), this, EHazeCameraPriority::Maximum);
		}
            
        Player.ApplyIdealDistance(Hose.IdealDistance, BlendSettings, this, EHazeCameraPriority::Maximum);

        Player.PlayForceFeedback(EnterHoseForceFeedBack, false, false, n"Medium");

        FHazePointOfInterest PoISettings = Hose.PointOfInterestSettings;

        if (Hose.PointOfInterestSettings.FocusTarget.Actor == nullptr)
            PoISettings.FocusTarget.Actor = Player;
		else
			PoISettings.FocusTarget.Component = PoISettings.FocusTarget.Actor.RootComponent;

        Player.ApplyPointOfInterest(PoISettings);

        Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(n"Death", this);

		if (Hose.bOverrideLaunch)
		{
			bCollisionBlockedInternally = false;
			Player.BlockCapabilities(CapabilityTags::Collision, Hose);
		}
		else
		{
			bCollisionBlockedInternally = true;
			Player.BlockCapabilities(CapabilityTags::Collision, this);
		}

		Player.TriggerMovementTransition(this);

        UAnimSequence InsideAnimation = Player.IsCody() ? CodyInsideAnimation : MayInsideAnimation;

		Player.PlaySlotAnimation(Animation = InsideAnimation, BlendTime = 0.1f, bLoop = true);

		RemoveMeshOutlineFromMesh(Player.Mesh);

		CurrentAngularVelocity = Hose.MainSplineComponent.GetDirectionAtDistanceAlongSpline(DistanceAlongHose, ESplineCoordinateSpace::World);
		PreviousAngularVelocity = CurrentAngularVelocity;

		TimeUntilLaunch = (Hose.MainSplineComponent.SplineLength/FMath::Abs(Hose.CurrentSpeedThroughHose));
		ExitPrepareHandle = System::SetTimer(this, n"TriggerExitPrepareSound", TimeUntilLaunch - LaunchPrepareTime, false);

		HazeAkComp.HazePostEvent(Hose.OnEnterEvent);

		if(GetMusicManagerAkComp(MusicManagerHazeAkComp))
			MusicManagerHazeAkComp.HazePostEvent(Hose.OnEnterMusicEvent);

		if (Player.IsMay())
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_VO_IsInVacuumHose_May", 1.f);
		else
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_VO_IsInVacuumHose_Cody", 1.f);

		Player.PlayCameraShake(Hose.GoingThroughHoseCameraShake);

		BarkHandle = System::SetTimer(this, n"PlayBark", 0.5f, true);

		CrumbComp.IncludeCustomParamsInActorReplication(FVector::ZeroVector, FRotator::ZeroRotator, this);

		PreviousRemoteLocation = Player.ActorLocation;
	}

	UFUNCTION()
	void PlayBark()
	{
		if (Player.IsMay())
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumInsideHoseEffortMay");
		else
			VOBank.PlayFoghornVOBankEvent(n"FoghornDBShedVacuumInsideHoseEffortCody");
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
        Player.ClearPointOfInterestByInstigator();
        Player.ClearCameraSettingsByInstigator(this);
        Player.ClearIdealDistanceByInstigator(this);

        Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(n"Death", this);

		Hose.PlayBlowOutAnimation(LaunchLocation);

		if (Hose.bOverrideLaunch)
		{
			Hose.OnLaunchedFromHose.Broadcast(Player, Hose, LaunchLocation);
		}
		else
		{
			Player.SetCapabilityAttributeObject(n"Hose", Hose);
			Player.SetCapabilityAttributeNumber(n"MountLocation", LaunchLocation);
			Player.SetCapabilityActionState(n"LaunchedFromVacuum", EHazeActionState::Active);
		}

		if (bCollisionBlockedInternally)
			Player.UnblockCapabilities(CapabilityTags::Collision, this);

		Player.StopAllInstancesOfCameraShake(Hose.GoingThroughHoseCameraShake, false);

        CreateMeshOutlineBasedOnPlayer(Player.Mesh, Player);

		System::ClearAndInvalidateTimerHandle(ExitPrepareHandle);

		HazeAkComp.HazePostEvent(Hose.OnExitEvent);

		if(GetMusicManagerAkComp(MusicManagerHazeAkComp))
			MusicManagerHazeAkComp.HazePostEvent(Hose.OnExitMusicEvent);

		if (Player.IsMay())
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_VO_IsInVacuumHose_May", 0.f);
		else
			UHazeAkComponent::HazeSetGlobalRTPCValue("Rtpc_VO_IsInVacuumHose_Cody", 0.f);

		Player.StopAllSlotAnimations();

		Player.MeshOffsetComponent.ResetRotationWithTime(0.75f);

		System::ClearAndInvalidateTimerHandle(BarkHandle);

		CrumbComp.RemoveCustomParamsFromActorReplication(this);

		// Force player traversal audio state to falling on ejection
		UPlayerMovementAudioComponent AudioMoveComp = UPlayerMovementAudioComponent::Get(Player);
		if(AudioMoveComp != nullptr)
		{
			AudioMoveComp.SetTraversalTypeSwitch(HazeAudio::EPlayerMovementState::Falling);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void TriggerExitPrepareSound()
	{
		HazeAkComp.HazePostEvent(Hose.BeforeExitEvent);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (HasControl())
		{
			if (DistanceAlongHose > Hose.GetMainSplineLength() && Hose.FrontVacuumMode == EVacuumMode::Suck && Player.HasControl())
			{
				LaunchPlayerFromHose(EVacuumMountLocation::Back);
				return;
			}

			else if (DistanceAlongHose < 0 && Hose.FrontVacuumMode == EVacuumMode::Blow && Player.HasControl())
			{
				LaunchPlayerFromHose(EVacuumMountLocation::Front);
				return;
			}
		}

        if (HasControl())
		{
            MovePlayerInHose(DeltaTime);

            FVector HoseDirection = Hose.MainSplineComponent.GetDirectionAtDistanceAlongSpline(DistanceAlongHose, ESplineCoordinateSpace::World);
			if(Hose.FrontVacuumMode == EVacuumMode::Blow)
				HoseDirection = -HoseDirection;

			FRotator MeshRotation = Math::MakeRotFromX(HoseDirection);
			FRotator PlayerRotation = HoseDirection.ToOrientationRotator();
			PlayerRotation.Pitch = 0.f;
			PlayerRotation.Roll = 0.f;
					
			Player.MeshOffsetComponent.OffsetRotationWithSpeed(MeshRotation);
			Player.SetActorRotation(FMath::RInterpTo(Player.GetActorRotation(), PlayerRotation, DeltaTime, 30.f));

			CrumbComp.SetCustomCrumbVector(FVector(DistanceAlongHose, 0.f, 0.f));
			CrumbComp.LeaveMovementCrumb();

			Player.SetFrameForceFeedback(0.1f, 0.1f);
		}
		else
		{
			PreviousRemoteLocation = Player.ActorLocation;

			FHazeActorReplicationFinalized CrumbParams;
			CrumbComp.ConsumeCrumbTrailMovement(DeltaTime, CrumbParams);

			FHazeFrameMovement MoveData = MoveComp.MakeFrameMovement(n"InsideHose");

			if (CrumbParams.CustomCrumbVector.X != 0.f)
				DistanceAlongHose = CrumbParams.CustomCrumbVector.X;

			FVector Delta = Hose.MainSplineComponent.GetLocationAtDistanceAlongSpline(DistanceAlongHose, ESplineCoordinateSpace::World) - PreviousRemoteLocation;

			FVector HoseDirection = Hose.MainSplineComponent.GetDirectionAtDistanceAlongSpline(DistanceAlongHose, ESplineCoordinateSpace::World);
			if(Hose.FrontVacuumMode == EVacuumMode::Blow)
				HoseDirection = -HoseDirection;

			FRotator MeshRotation = Math::MakeRotFromX(HoseDirection);
			FRotator PlayerRotation = HoseDirection.ToOrientationRotator();
			PlayerRotation.Pitch = 0.f;
			PlayerRotation.Roll = 0.f;
					
			Player.MeshOffsetComponent.OffsetRotationWithSpeed(MeshRotation);

			// Set variables used by audio
			SetVariablesBasedOnDistanceAlongHose();

			MoveComp.SetTargetFacingDirection(HoseDirection);
			MoveData.ApplyTargetRotationDelta();
			MoveData.ApplyDelta(Delta);
			MoveComp.Move(MoveData);
		}
		
		HazeAkComp.SetRTPCValue("Rtpc_Vehicles_VacuumHose_Velocity", SpeedThroughHose, 0.f);
		HazeAkComp.SetRTPCValue("Rtpc_Vehicles_VacuumHose_AngularVelocity", AngularVelocity, 0.f);
		HazeAkComp.SetRTPCValue("Rtpc_Vehicles_VacuumHose_Tilt", CurrentTilt, 0.f);
		HazeAkComp.SetRTPCValue("Rtpc_Vehicles_VacuumHose_InsideHoseDistance", AlphaAlongHose, 0.f);
	}

	void MovePlayerInHose(float Delta)
	{
		DistanceAlongHose = DistanceAlongHose + Hose.CurrentSpeedThroughHose * Delta;
		Player.SetActorLocation(FMath::VInterpTo(Player.ActorLocation, Hose.MainSplineComponent.GetLocationAtDistanceAlongSpline(DistanceAlongHose, ESplineCoordinateSpace::World), Delta, 15.f));

		SetVariablesBasedOnDistanceAlongHose();
	}

	void SetVariablesBasedOnDistanceAlongHose()
	{
		AlphaAlongHose = FMath::GetMappedRangeValueClamped(FVector2D(0.f, Hose.MainSplineComponent.SplineLength), FVector2D(0.f, 1.f), DistanceAlongHose);

		bool bGoingForwards = Hose.CurrentSpeedThroughHose > 0.f;

		if (!bGoingForwards)
			AlphaAlongHose = 1.f - AlphaAlongHose;

		SpeedThroughHose = FMath::Abs(Hose.CurrentSpeedThroughHose);

		CurrentTilt = Hose.MainSplineComponent.GetDirectionAtDistanceAlongSpline(DistanceAlongHose, ESplineCoordinateSpace::World).Z;
		if (!bGoingForwards)
			CurrentTilt *= -1.f;

		CurrentAngularVelocity = Hose.MainSplineComponent.GetDirectionAtDistanceAlongSpline(DistanceAlongHose, ESplineCoordinateSpace::World);
		FVector Cross = CurrentAngularVelocity.CrossProduct(PreviousAngularVelocity);
		AngularVelocity = FMath::GetMappedRangeValueClamped(FVector2D(0.f, 0.25f), FVector2D(0.f, 1.f), Cross.Size());
		PreviousAngularVelocity = CurrentAngularVelocity;

		// Print("Alpha: " + AlphaAlongHose);
		// Print("Speed: " + SpeedThroughHose);
		// Print("Tilt: " + CurrentTilt);
		// Print("AngularVelocity: " + AngularVelocity);
	}

    UFUNCTION(NetFunction)
    void LaunchPlayerFromHose(EVacuumMountLocation ExhaustLocation)
    {
        LaunchLocation = ExhaustLocation;
        Player.SetCapabilityActionState(n"GoingThroughVacuum", EHazeActionState::Inactive);
    }

	bool GetMusicManagerAkComp(UHazeAkComponent& MusicAkComp)
	{
		AudioManager.GetMusicHazeAkComponent(MusicAkComp);
		return MusicAkComp != nullptr;
	}
}