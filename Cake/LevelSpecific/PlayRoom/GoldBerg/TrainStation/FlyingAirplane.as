import Vino.Movement.Swinging.SwingPointComponent;
import Peanuts.Spline.SplineComponent;
import Vino.Interactions.InteractionComponent;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Movement.Capabilities.JumpTo.CharacterJumpToCapability;
import Vino.Camera.Components.CameraSpringArmComponent;
import Peanuts.Audio.AudioStatics;

class AFlyingAirplane : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	UHazeSplineComponent Spline;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionCody;
	default InteractionCody.bUseLazyTriggerShapes = true;

	UPROPERTY(DefaultComponent)
	UInteractionComponent InteractionMay;
	default InteractionMay.bUseLazyTriggerShapes = true;

	UPROPERTY(DefaultComponent)
	UHazeCameraRootComponent CameraRoot;

	UPROPERTY(DefaultComponent, Attach = CameraRoot)
	UCameraSpringArmComponent CameraSpringarm;

	UPROPERTY(DefaultComponent, Attach = CameraSpringarm)
	UHazeCameraComponent Camera;
	default Camera.BlendOutBehaviour = EHazeCameraBlendoutBehaviour::FollowView;

	UPROPERTY()
	FHazeTimeLike Timelike;

	UPROPERTY(DefaultComponent)
	UHazeLazyPlayerOverlapComponent KillTriggerOnOverlap;

	UPROPERTY()
	bool bFlipDirection;

	UPROPERTY()
	AFlyingAirplane OtherPlane;

	UPROPERTY()
	float StartOffset;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayEngineLoopAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent RollAudioEvent;

	default KillTriggerOnOverlap.Shape.InitializeAsBox(FVector(32.f, 250.f, 50.f));
	default KillTriggerOnOverlap.ResponsiveDistanceThreshold = 1000.f;

	FVector LastFrameRightVector;
	float LastFrameRoll;

	float TimeSinceRolled = 0;

	AHazePlayerCharacter InteractingPlayer;

	FHazeAcceleratedFloat AdditionalRoll;
	bool bIsRolling = true;
	float MovementAdditionalRoll;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Initiate();

		FHazeActivationSettings ActivationSettingsCody;
		ActivationSettingsCody.NetworkMode = EHazeTriggerNetworkMode::AlwaysCody;
		InteractionCody.AddActivationSettings(ActivationSettingsCody);

		FHazeActivationSettings ActivationSettingsMay;
		ActivationSettingsMay.NetworkMode = EHazeTriggerNetworkMode::AlwaysMay;
		InteractionCody.AddActivationSettings(ActivationSettingsMay);

		InteractionCody.OnActivated.AddUFunction(this ,n"OnAirplaneActivated");
		InteractionMay.OnActivated.AddUFunction(this ,n"OnAirplaneActivated");

		InteractionCody.DisableForPlayer(Game::GetMay(), n"OnlyCody");
		InteractionMay.DisableForPlayer(Game::GetCody(), n"OnlyMay");

		KillTriggerOnOverlap.OnPlayerBeginOverlap.AddUFunction(this, n"OnKillTriggerOverlapped");

		HazeAkComp.HazePostEvent(PlayEngineLoopAudioEvent);
		HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interaction_Airplanes_PlayerPanning", 0.f);
	}

	UFUNCTION(NotBlueprintCallable)
	protected void OnKillTriggerOverlapped(AHazePlayerCharacter Player)
	{
		if(!Player.HasControl())
			return;

		if (Player.IsAnyCapabilityActive(n"FlyingAirplane"))
			return;

		if (Player.IsAnyCapabilityActive(UCharacterJumpToCapability::StaticClass()))
			return;

		Player.KillPlayer();
	}

	UFUNCTION()
    void OnAirplaneActivated(UInteractionComponent Component, AHazePlayerCharacter Player)
    {
		InteractingPlayer = Player;
		Player.SetCapabilityAttributeObject(n"Airplane", this);
		Component.Disable(n"IsInteractedWith");
	}

	UFUNCTION()
	void Initiate()
	{
		LastFrameRightVector = ActorRightVector;
		Timelike.BindUpdate(this, n"Update");
		
		Spline.DetachFromParent(true, false);
		AdditionalRoll.SnapTo(0, 0);

		Timelike.PlayFromStart();
		Timelike.SetNewTime(StartOffset);
	}
	
	UFUNCTION(BlueprintEvent)
	void OnPlayerLeftAirplane()
	{
		
	}

	UFUNCTION()
	void Update(float TimelineTime)
	{
		float Distance = Spline.SplineLength * TimelineTime;

		if (bFlipDirection)
		{
			Distance = Spline.SplineLength * (1- TimelineTime);
		}

		SetActorLocation(Spline.GetLocationAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World));
		
		FVector CurrentForwardvector = Spline.GetTangentAtDistanceAlongSpline(Distance, ESplineCoordinateSpace::World);

		float DistanceAlongSplineToCheck = Distance + 1000;
		
		if (bFlipDirection)
		{
			DistanceAlongSplineToCheck = Distance - 1000;
		}

		if (DistanceAlongSplineToCheck > Spline.SplineLength)
		{
			DistanceAlongSplineToCheck - Spline.SplineLength;
		}
		if (bFlipDirection && DistanceAlongSplineToCheck < 0)
		{
			DistanceAlongSplineToCheck = Spline.SplineLength - DistanceAlongSplineToCheck;
		}

		FVector AheadForwardVector = Spline.GetTangentAtDistanceAlongSpline(DistanceAlongSplineToCheck, ESplineCoordinateSpace::World);

		float Dot = AheadForwardVector.GetSafeNormal().DotProduct(LastFrameRightVector);

		if (bFlipDirection)
		CurrentForwardvector *= -1;

		FRotator Rotation = FRotator::MakeFromX(CurrentForwardvector);
		float DesiredRoll = Dot * 80.f + MovementAdditionalRoll * -200;

		if(bFlipDirection)
		{
			DesiredRoll *= - 1;
		}

		Rotation.Roll = FMath::Lerp(LastFrameRoll, DesiredRoll, ActorDeltaSeconds * 2.f);
		LastFrameRoll = Rotation.Roll;

		LastFrameRightVector = ActorRightVector;
		AdditionalRoll.SpringTo(0.f, 16.f, 0.6f, ActorDeltaSeconds);

		FRotator FinalRotation = Rotation + FRotator(0.f, 0.f, AdditionalRoll.Value);
		SetActorRotation(FinalRotation);

		TimeSinceRolled += ActorDeltaSeconds;
	}

	UFUNCTION()
	void PerformRoll()
	{
		if (TimeSinceRolled < 2)
		{
			return;
		}

		TimeSinceRolled = 0;

		if (AdditionalRoll.Value > -180.f)
			AdditionalRoll.Value -= 360;

		bool bCodyInteracting = InteractionCody.IsDisabled(n"IsInteractedWith", EHazePlayerCondition::Cody);
		bool bMayInteracting = InteractionMay.IsDisabled(n"IsInteractedWith", EHazePlayerCondition::May);
		float Panning = bCodyInteracting && bMayInteracting ? 0.f : (bCodyInteracting ? 1.f : -1.f);
		// if the InteractingPlayer isn't a nullptr we skip a loop in SetPlayerPanning,
		// which it can be when one leaves the interaction but one still remains.
		HazeAudio::SetPlayerPanning(HazeAkComp, InteractingPlayer, Panning);

		HazeAkComp.HazePostEvent(RollAudioEvent);
	}

	void EnableFlyingAirplaneInteraction(AHazePlayerCharacter Player)
	{
		if (Player.IsCody())
		{
			InteractionCody.Enable(n"IsInteractedWith");
		}
		else
		{
			InteractionMay.Enable(n"IsInteractedWith");
		}
		
		InteractingPlayer = nullptr;
	}
}


