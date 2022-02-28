import Cake.LevelSpecific.PlayRoom.SpaceStation.SurveillanceSatelliteDish;
import Effects.PostProcess.PostProcessing;
import Vino.Tutorial.TutorialStatics;
import Peanuts.Fades.FadeStatics;
import Peanuts.Foghorn.FoghornStatics;

class USurveillanceSatelliteDishPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"LevelSpecific");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ASurveillanceSatelliteDish SatelliteDish;
	UPostProcessingComponent PostProcessComp;
	ASurveillanceSatelliteDishFocusPoint ActiveFocusPoint;
	USurveillanceSatelliteDishSoundWidget Widget;

	ULocomotionFeatureArcadeScreenLever Feature;

	FVector InterpSpeed = 0.f;

	FVector2D InputValues;
	FTimerHandle InputValueTimerHandle;

	float CurrentListenDuration = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"Surveillance"))
        	return EHazeNetworkActivation::ActivateFromControl;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (WasActionStarted(ActionNames::Cancel) && GetActiveDuration() > 1.f)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		Player.SetCapabilityActionState(n"Surveillance", EHazeActionState::Inactive);
		SatelliteDish = Cast<ASurveillanceSatelliteDish>(GetAttributeObject(n"SatelliteDish"));
		SatelliteDish.SetControlSide(Player);

		FadeOutPlayer(Player, 0.5f, 0.5f, 0.5f);
		System::SetTimer(this, n"ActivateCamera", 0.6f, false);
		
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.TriggerMovementTransition(this);

		Feature = Player.IsMay() ? SatelliteDish.MayFeature : SatelliteDish.CodyFeature;
		Player.AddLocomotionFeature(Feature);

		SatelliteDish.Joystick.SetAnimBoolParam(n"HasInteractingPlayer", true);

		FName PlayerAttachSocket = Player.IsMay() ? n"Attach_May" : n"Attach_Cody";
		Player.AttachToComponent(SatelliteDish.Joystick, PlayerAttachSocket, EAttachmentRule::SnapToTarget);

		InterpSpeed = 0.f;

		SatelliteDish.HazeAkComp.HazePostEvent(SatelliteDish.PlaySurveillanceSatelliteDishAudioEvent);
		SatelliteDish.HazeAkComp.HazePostEvent(SatelliteDish.PlaySurveillanceSatelliteDishMovementAudioEvent);

		if (HasControl())
			InputValueTimerHandle = System::SetTimer(this, n"UpdateInputValue", 0.1f, true);
	}

	UFUNCTION()
	void ActivateCamera()
	{
		Player.ActivateCamera(SatelliteDish.CamComp, FHazeCameraBlendSettings(0.f), this);

		ShowCancelPrompt(Player, this);

		Widget = Cast<USurveillanceSatelliteDishSoundWidget>(Player.AddWidget(SatelliteDish.WidgetClass, EHazeWidgetLayer::Crosshair));

		PostProcessComp = UPostProcessingComponent::Get(Player);
		if (PostProcessComp != nullptr)
			PostProcessComp.VHS = 1.f;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Movement, this);

		FadeOutPlayer(Player, 0.5f, 0.5f, 0.5f);
		System::SetTimer(this, n"DeactivateCamera", 0.6f, false);

		RemoveCancelPromptByInstigator(Player, this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		Player.RemoveLocomotionFeature(Feature);

		SatelliteDish.Joystick.SetAnimBoolParam(n"HasInteractingPlayer", false);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		if (HasControl())
			System::ClearAndInvalidateTimerHandle(InputValueTimerHandle);

		StopFocusingPoint();
		
		SatelliteDish.HazeAkComp.HazePostEvent(SatelliteDish.StopSurveillanceSatelliteDishAudioEvent);
		SatelliteDish.HazeAkComp.HazePostEvent(SatelliteDish.StopSurveillanceSatelliteDishMovementAudioEvent);
	}

	UFUNCTION()
	void DeactivateCamera()
	{
		if (PostProcessComp != nullptr)
			PostProcessComp.VHS = 0.f;

		if (SatelliteDish == nullptr)
			return;

		Player.RemoveWidget(Widget);

		Player.DeactivateCamera(SatelliteDish.CamComp, 0.f);
		Player.SnapCameraBehindPlayer();

		SatelliteDish.InteractionCancelled(Player);
	}

	UFUNCTION()
	void UpdateInputValue()
	{
		NetUpdateInputValue(InputValues);
	}

	UFUNCTION(NetFunction)
	void NetUpdateInputValue(FVector2D Input)
	{
		InputValues = Input;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (HasControl())
		{
			InputValues = GetAttributeVector2D(AttributeVectorNames::MovementRaw);

			InterpSpeed = FMath::VInterpTo(InterpSpeed, FVector(InputValues.X, InputValues.Y, 0.f), DeltaTime, 2.f);

			SatelliteDish.StandRoot.AddLocalRotation(FRotator(0.f, InterpSpeed.Y * 45.f * DeltaTime, 0.f));

			float Pitch = SatelliteDish.DishRoot.RelativeRotation.Roll + InterpSpeed.X * 45.f * DeltaTime;
			Pitch = FMath::Clamp(Pitch, -10.f, 80.f);
			SatelliteDish.DishRoot.SetRelativeRotation(FRotator(0.f, 0.f, Pitch));

			SatelliteDish.SyncPitchComp.SetValue(SatelliteDish.DishRoot.RelativeRotation.Roll);
			SatelliteDish.SyncYawComp.SetValue(SatelliteDish.StandRoot.RelativeRotation);
		}
		else
		{
			SatelliteDish.StandRoot.SetRelativeRotation(SatelliteDish.SyncYawComp.Value);
			SatelliteDish.DishRoot.SetRelativeRotation(FRotator(0.f, 0.f, SatelliteDish.SyncPitchComp.Value));
		}

		Player.SetAnimFloatParam(n"JoystickInputX", InputValues.Y);
		Player.SetAnimFloatParam(n"JoystickInputY", -InputValues.X);
		SatelliteDish.Joystick.SetAnimFloatParam(n"JoystickInputX", InputValues.Y);
		SatelliteDish.Joystick.SetAnimFloatParam(n"JoystickInputY", -InputValues.X);
		
		SatelliteDish.HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interactions_SurveillanceSatelliteDish_Tilt", InputValues.X);
		SatelliteDish.HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interactions_SurveillanceSatelliteDish_Rotation", InputValues.Y);
		SatelliteDish.HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interactions_SurveillanceSatelliteDish_TiltMoveMax", SatelliteDish.DishRoot.RelativeRotation.Roll);
		
		FHazeRequestLocomotionData LocomotionData;
		LocomotionData.AnimationTag = Feature.Tag;

		Player.RequestLocomotion(LocomotionData);

		float HighestDot = 0.f;

		ASurveillanceSatelliteDishFocusPoint CurrentFocusPoint = nullptr;
		for (ASurveillanceSatelliteDishFocusPoint FocusPoint : SatelliteDish.FocusPoints)
		{
			if (!FocusPoint.bFullyListened)
			{
				FVector DirToFocusPoint = FocusPoint.ActorLocation - SatelliteDish.ActorLocation;
				DirToFocusPoint.Normalize();
				float Dot = DirToFocusPoint.DotProduct(SatelliteDish.CamComp.ForwardVector);
				if (Dot > HighestDot)
				{
					HighestDot = Dot;
					if (HighestDot >= 0.94f)
					{
						CurrentFocusPoint = FocusPoint;
					}
				}
			}
		}

		if (CurrentFocusPoint == nullptr)
			StopFocusingPoint();
		else
			StartFocusingPoint(CurrentFocusPoint);

		if (HasControl())
		{
			if (CurrentFocusPoint == nullptr)
				CurrentListenDuration = 0.f;
			else
			{
				CurrentListenDuration += DeltaTime;
				if (CurrentListenDuration >= ActiveFocusPoint.StartEvent.HazeMaximumDuration)
					SatelliteDish.NetSetFocusPointFullyListened(ActiveFocusPoint);
			}
		}

		float SoundAlpha = SatelliteDish.SoundAlphaCurve.GetFloatValue(HighestDot);
		if (Widget != nullptr)
		{
			float WidgetAlpha = FMath::FInterpTo(Widget.SoundAlpha, SoundAlpha, DeltaTime, 5.f);
			Widget.SoundAlpha = WidgetAlpha;
		}

		SatelliteDish.HazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Playroom_Interactions_SurveillanceSatelliteDish_SoundAlpha", SoundAlpha);
	}

	void StartFocusingPoint(ASurveillanceSatelliteDishFocusPoint Point)
	{
		if (ActiveFocusPoint == Point)
			return;

		ActiveFocusPoint = Point;
		ResumeFoghornActor(SatelliteDish);
		PlayFoghornBark(ActiveFocusPoint.BarkAsset, SatelliteDish);
	}

	void StopFocusingPoint()
	{
		if (ActiveFocusPoint != nullptr)
		{
			CurrentListenDuration = 0.f;
			PauseFoghornActor(SatelliteDish);
			ActiveFocusPoint = nullptr;
		}
	}
}