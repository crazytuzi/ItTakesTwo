import Peanuts.Audio.AudioSpline.AudioSpline;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureArcadeScreenLever;
import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.PlayRoom.SpaceStation.ChangeSize.CharacterChangeSizeStatics;

event void FOnTractorBeamActivated();
event void FOnTractorBeamDeactivated();

class ATractorBeamTerminal : AHazeActor
{
    UPROPERTY(RootComponent, DefaultComponent)
    USceneComponent Root;

    UPROPERTY(DefaultComponent, Attach = Root)
    UStaticMeshComponent TowerBase;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent TowerRoot;

    UPROPERTY(DefaultComponent, Attach = TowerRoot)
    UStaticMeshComponent Tower;

	UPROPERTY(DefaultComponent, Attach = TowerRoot)
	USceneComponent AntennaRoot;

    UPROPERTY(DefaultComponent, Attach = AntennaRoot)
    UStaticMeshComponent TowerAntenna;
    default TowerAntenna.RelativeLocation = FVector(0.f, 0.f, 570.f);

	UPROPERTY(DefaultComponent, Attach = AntennaRoot)
	UNiagaraComponent TractorBeamEffect;

    UPROPERTY(DefaultComponent, Attach = AntennaRoot)
    UCapsuleComponent TractorBeamCapsule;
    default TractorBeamCapsule.CapsuleHalfHeight = 3750.f;
    default TractorBeamCapsule.CapsuleRadius = 650.f;
    default TractorBeamCapsule.RelativeRotation = FRotator(0.f, 0.f, -90.f);
    default TractorBeamCapsule.RelativeLocation = FVector(0.f, -4120.f, 120.f);
	default TractorBeamCapsule.CollisionEnabled = ECollisionEnabled::NoCollision;

	UPROPERTY(DefaultComponent, Attach = AntennaRoot)
	USceneComponent CamRoot;

	UPROPERTY(DefaultComponent, Attach = CamRoot)
	UHazeCameraComponent CamComp;
    
    UPROPERTY(DefaultComponent, Attach = TowerRoot)
    UInteractionComponent InteractionPoint;

	UPROPERTY(DefaultComponent, Attach = TowerRoot)
	UHazeSkeletalMeshComponentBase Joystick;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncPitchComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent SyncYawComp;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncVectorComponent SyncInputComp;

	UPROPERTY(DefaultComponent)
	UHazeDisableComponent DisableComponent;
	default DisableComponent.bAutoDisable = true;
	default DisableComponent.bRenderWhileDisabled = true;
	default DisableComponent.AutoDisableRange = 10000.f;

    bool bTractorBeamActive = false;

    UPROPERTY()
    FOnTractorBeamActivated OnTractorBeamActivated;

    UPROPERTY()
    FOnTractorBeamDeactivated OnTractorBeamDeactivated;

    UPROPERTY()
    FVector2D PitchRange = FVector2D(0.f, 54.f);

	UPROPERTY()
	FVector2D YawRange = FVector2D(-90.f, 0.f);

	UPROPERTY(Category="Start Events")
	UAkAudioEvent TractorBeamActivatedEvent;

	UPROPERTY(Category="Start Events")
	UAkAudioEvent PlayerInsideTractorBeamEvent;

	UPROPERTY(Category ="Start Events")
	UAkAudioEvent TowerRotatingStartEvent;

	UPROPERTY(Category="Stop Events")
	UAkAudioEvent PlayerExitTractorBeamEvent;

	UPROPERTY(Category="Stop Events")
	UAkAudioEvent TractorBeamDeactivatedEvent;

	UPROPERTY(Category="Stop Events")
	UAkAudioEvent TowerRotatingStopEvent;

	UHazeAkComponent PlayerHazeAkComp;
	UHazeAkComponent TractorHazeAkComp;
	FVector Point;

    float CurrentTowerRotation;
    float CurrentAntennaPitch;
	float LastRotationDelta;
	bool bIsMoving = false;

	AHazePlayerCharacter ControllingPlayer;
	AHazePlayerCharacter PlayerInTractorBeam;

	UHazeListenerComponent MayListener;
	UHazeListenerComponent CodyListener;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> ControlCapability;
	
	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UHazeCapability> MovementCapability;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureArcadeScreenLever MayFeature;

	UPROPERTY(EditDefaultsOnly)
	ULocomotionFeatureArcadeScreenLever CodyFeature;

	UPROPERTY(EditDefaultsOnly)
	UForceFeedbackEffect CaughtAndReleasedForceFeedback;

	UPROPERTY(EditDefaultsOnly)
	TSubclassOf<UCameraShakeBase> CaughtAndReleasedCameraShake;

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
		TractorBeamEffect.Deactivate();
		InteractionPoint.OnActivated.AddUFunction(this, n"OnInteractionActivated");

        TractorBeamCapsule.OnComponentBeginOverlap.AddUFunction(this, n"EnterTractorBeamCapsule");
        TractorBeamCapsule.OnComponentEndOverlap.AddUFunction(this, n"ExitTractorBeamCapsule");

		Capability::AddPlayerCapabilityRequest(ControlCapability.Get());
		Capability::AddPlayerCapabilityRequest(MovementCapability.Get());

		if(TractorBeamActivatedEvent != nullptr)
		{					
			TractorHazeAkComp = UHazeAkComponent::GetOrCreate(this);	
			MayListener = Game::GetMay().ListenerComponent;
			CodyListener = Game::GetCody().ListenerComponent;
			TractorHazeAkComp.DetachFromComponent();
		}
		
		LastRotationDelta = Tower.GetWorldRotation().Yaw + TowerAntenna.GetWorldRotation().Roll;

		SyncYawComp.Value = TowerRoot.RelativeRotation.Yaw;
    }

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason Reason)
	{
		Capability::RemovePlayerCapabilityRequest(ControlCapability.Get());
		Capability::RemovePlayerCapabilityRequest(MovementCapability.Get());
	}

    UFUNCTION()
    void EnterTractorBeamCapsule(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex, bool bFromSweep, FHitResult& Hit)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

        if (Player != nullptr)
        {
			Player.SetCapabilityAttributeObject(n"TargetTractorBeam", this);
            Player.SetCapabilityActionState(n"TractorBeam", EHazeActionState::Active);

			PlayerHazeAkComp = UHazeAkComponent::GetOrCreate(Player);

			if(PlayerInsideTractorBeamEvent != nullptr)
			{
				PlayerHazeAkComp.HazePostEvent(PlayerInsideTractorBeamEvent);
			}
        }
    }

    UFUNCTION()
    void ExitTractorBeamCapsule(UPrimitiveComponent OverlappedComponent, AActor OtherActor, UPrimitiveComponent OtherComponent, int OtherBodyIndex)
    {
        AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);

        if (Player != nullptr)
        {
            Player.SetCapabilityActionState(n"TractorBeam", EHazeActionState::Inactive);

			PlayerHazeAkComp = UHazeAkComponent::GetOrCreate(Player);
			if(PlayerExitTractorBeamEvent != nullptr)
			{
				PlayerHazeAkComp.HazePostEvent(PlayerExitTractorBeamEvent);
			}

			PlayerHazeAkComp = nullptr;
        }
    }

    UFUNCTION()
    void OnInteractionActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		ControllingPlayer = Player;
		SetControlSide(ControllingPlayer);
		HazeAudio::SetPlayerPanning(TractorHazeAkComp, Cast<AHazeActor>(ControllingPlayer));

		if (Player.IsCody())
			ForceCodyMediumSize();

        Player.SetCapabilityAttributeObject(n"TractorBeamTerminal", this);
        Player.SetCapabilityActionState(n"ControllingTractorBeam", EHazeActionState::Active);
		InteractionPoint.Disable(n"Used");
		bTractorBeamActive = true;

		ActivateTractorBeam();
		Player.ActivateCamera(CamComp, FHazeCameraBlendSettings(), this);
		
		if(TractorBeamActivatedEvent != nullptr)
		{
			TractorHazeAkComp.HazePostEvent(TractorBeamActivatedEvent);
		}
    }

	void ActivateTractorBeam()
	{
		TractorBeamEffect.Activate();
		TractorBeamCapsule.SetCollisionEnabled(ECollisionEnabled::QueryOnly);
		OnTractorBeamActivated.Broadcast();
	}

    void DeactivateTractorBeam(AHazePlayerCharacter Player)
    {
		Player.DeactivateCamera(CamComp, 1.f);
		TractorBeamEffect.Deactivate();
		TractorBeamCapsule.SetCollisionEnabled(ECollisionEnabled::NoCollision);
        OnTractorBeamDeactivated.Broadcast();
		InteractionPoint.EnableAfterFullSyncPoint(n"Used");
		bTractorBeamActive = false;

		if(TractorBeamDeactivatedEvent != nullptr)
		{
			TractorHazeAkComp.HazePostEvent(TractorBeamDeactivatedEvent);		
		}
    }

	void RotateTower(FVector2D PlayerInput)
    {
		float TowerRotationRate = PlayerInput.X * 32.f * ActorDeltaSeconds;
		float CurYaw = SyncYawComp.Value + TowerRotationRate;
		CurYaw = FMath::Clamp(CurYaw, YawRange.X, YawRange.Y);
		SyncYawComp.Value = CurYaw;

        float AntennaRotationRate = PlayerInput.Y * 32.f * ActorDeltaSeconds;
		float CurPitch = SyncPitchComp.Value + AntennaRotationRate;
		CurPitch = FMath::Clamp(CurPitch, PitchRange.X, PitchRange.Y);
		SyncPitchComp.Value = CurPitch;
    }

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		float CurDistance = FMath::GetMappedRangeValueClamped(PitchRange, FVector2D(1550, 750.f), AntennaRoot.RelativeRotation.Roll);
		CamComp.SetRelativeLocation(FVector(0.f, CurDistance, 1000.f));
		// CamComp.SetRelativeLocation(FVector(0.f, 1600.f, 1020.f));
		CamComp.SetRelativeRotation(FRotator(-12.f, -90.f, 0.f));
		
		TowerRoot.SetRelativeRotation(FRotator(0.f, SyncYawComp.Value, 0.f));
		AntennaRoot.SetRelativeRotation(FRotator(0.f, 0.f, SyncPitchComp.Value));

		if(TractorBeamActivatedEvent != nullptr && bTractorBeamActive)
		{			
			FVector MayListenerLocation = MayListener.GetWorldLocation();
			FVector CodyListenerLocation = CodyListener.GetWorldLocation();

			FVector OutMayPos;
			FVector OutCodyPos;

			TractorBeamCapsule.GetClosestPointOnCollision(MayListenerLocation, OutMayPos);
			TractorBeamCapsule.GetClosestPointOnCollision(CodyListenerLocation, OutCodyPos);

			TArray<FTransform> EmitterPositions;
			EmitterPositions.Add(FTransform(OutMayPos));
			EmitterPositions.Add(FTransform(OutCodyPos));

			TractorHazeAkComp.HazeSetMultiplePositions(EmitterPositions);
			
        	CurrentTowerRotation = Tower.WorldRotation.Yaw * -1.f;
        	CurrentAntennaPitch = TowerAntenna.WorldRotation.Roll;
			float RotationDelta = (CurrentTowerRotation + CurrentAntennaPitch) - LastRotationDelta;
			LastRotationDelta = CurrentTowerRotation + CurrentAntennaPitch;

			float AbsRotationDelta = FMath::Abs(RotationDelta);			
			TractorHazeAkComp.SetRTPCValue(HazeAudio::RTPC::TractorBeamRotationMoving, AbsRotationDelta, 0.f);
			TractorHazeAkComp.SetRTPCValue(HazeAudio::RTPC::TractorBeamRotationAngle, CurrentAntennaPitch, 0.f);
			TractorHazeAkComp.SetRTPCValue(HazeAudio::RTPC::TractorBeamRotationYaw, CurrentTowerRotation, 0.f);	

			if(PlayerHazeAkComp != nullptr)
			{
				PlayerHazeAkComp.SetRTPCValue(HazeAudio::RTPC::TractorBeamRotationMoving, AbsRotationDelta, 0.f);		
			}
			
			// NOTE (GK): Can flicker on and off on remote in cooks.
			if(TowerRotatingStartEvent != nullptr)
			{
				if(!bIsMoving && AbsRotationDelta > 0.01f)
				{
					TractorHazeAkComp.HazePostEvent(TowerRotatingStartEvent);
					bIsMoving = true;
				}
			}

			if(TowerRotatingStopEvent != nullptr)
			{
				if(bIsMoving && FMath::IsNearlyZero(AbsRotationDelta))
				{
					TractorHazeAkComp.HazePostEvent(TowerRotatingStopEvent);
					bIsMoving = false;
				}
			}
		}
	}
}