import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.ControllableUFO;
import Vino.Camera.Capabilities.CameraTags;
import Peanuts.Audio.AudioStatics;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureControllingUFO;
import Vino.Tutorial.TutorialStatics;
import Peanuts.SpeedEffect.SpeedEffectStatics;

UCLASS(Abstract)
class UControlUFOCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::Movement);

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 50;

	UPROPERTY()
	ULocomotionFeatureControllingUFO Feature;

	UPROPERTY()
	FText RotateText;

	AHazePlayerCharacter Player;
	UHazeAkComponent UfoHazeAkComp;	
	AControllableUFO UfoActor;
	UHazeActiveCameraUserComponent CamUserComp;

	bool bBoosting = false;
	float LastRotationDelta = 0.f;
	FVector LastVeloVector;

	float CameraLerpDistance = 0.f;

	UPROPERTY()
	UHazeCameraSettingsDataAsset CamSettings;

	bool bHasRotated = false;
	bool bRotateTutorialShown = false;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		CamUserComp = UHazeActiveCameraUserComponent::Get(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"ControllingUFO"))
        	return EHazeNetworkActivation::ActivateFromControl;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (UfoActor == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (UfoActor.IsActorDisabled())
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
		OutParams.AddObject(n"UFO", GetAttributeObject(n"ControllableUFO"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UfoActor = Cast<AControllableUFO>(ActivationParams.GetObject(n"UFO"));
		if (UfoActor.IsActorDisabled())
			UfoActor.EnableActor(nullptr);

		UfoHazeAkComp = UHazeAkComponent::Get(UfoActor);		

		Player.ApplyFieldOfView(80.f, FHazeCameraBlendSettings(0.f), this);

		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(n"Gravity", this);
		SetMutuallyExclusive(CapabilityTags::Movement, true);
		Owner.TriggerMovementTransition(this);
		Player.AttachToComponent(UfoActor.UfoMesh, n"Base");

		Player.BlockCapabilities(CameraTags::Control, this);
		Player.ActivateCamera(UfoActor.UfoCam, 1.f, this);

		Player.AddLocomotionFeature(Feature);

		if(UfoActor.StartInsideUfoLoopingEvent != nullptr)
		{
			UfoHazeAkComp.HazePostEvent(UfoActor.StartInsideUfoLoopingEvent);
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.UnblockCapabilities(n"Gravity", this);
		SetMutuallyExclusive(CapabilityTags::Movement, false);
		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		Player.DeactivateCamera(UfoActor.UfoCam);
		Player.ClearFieldOfViewByInstigator(this);
		Player.ClearIdealDistanceByInstigator(this);
		Player.UnblockCapabilities(CameraTags::Control, this);

		RemoveTutorialPromptByInstigator(Player, this);
		
		if (!UfoActor.IsActorDisabled())
			UfoActor.DisableActor(nullptr);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector2D RotationInput = GetAttributeVector2D(AttributeVectorNames::RightStickRaw);
		float RotInput = RotationInput.X;

		FVector MovementInput;
		if (HasControl())
		{
			MovementInput = GetAttributeVector(AttributeVectorNames::LeftStickRaw);
			UfoActor.PlayerInputSyncComp.SetValue(MovementInput);

			if (!bHasRotated)
			{
				if (RotInput == 0.f)
				{
					if (!bHasRotated && !bRotateTutorialShown && ActiveDuration >= 6.f)
					{
						ShowRotateTutorial();
					}
				}
				else
				{
					if (!bHasRotated)
					{
						bHasRotated = true;
						RemoveTutorialPromptByInstigator(Player, this);
					}
				}
			}
		}
		else
		{
			MovementInput = UfoActor.PlayerInputSyncComp.Value;
		}

		float SpeedIntensityMultiplier = FMath::GetMappedRangeValueClamped(FVector2D(2500.f, 3000.f), FVector2D(0.f, 1.f), UfoActor.MoveComp.HorizontalVelocity);
		SpeedEffect::RequestSpeedEffect(Player, FSpeedEffectRequest(SpeedIntensityMultiplier, this));
		float FoV = FMath::Lerp(80.f, 90.f, SpeedIntensityMultiplier);
		Player.ApplyFieldOfView(FoV, FHazeCameraBlendSettings(), this);

		float NormalizedFOV = HazeAudio::NormalizeRTPC01(Player.GetPlayerViewFOV(), 80.f, 90.f);
		UfoHazeAkComp.SetRTPCValue(HazeAudio::RTPC::PilotingUFOCameraZoom, NormalizedFOV, 0.f);

		UfoActor.UpdatePlayerMovementInput(MovementInput, RotInput);

		float CurrVelocity = (UfoActor.GetActorLocation() - LastVeloVector).Size();
		float LerpedVelo = FMath::Lerp(0.f, CurrVelocity, Math::GetPercentageBetween(0, 750.f, CurrVelocity));
		float NormalizedVelo = HazeAudio::NormalizeRTPC01(CurrVelocity, 0.f, 64.f);
		UfoHazeAkComp.SetRTPCValue(HazeAudio::RTPC::MoonBaboonUFOVelocityDelta, FMath::Clamp(NormalizedVelo, 0.f, 1.f), 0.f);

		LastVeloVector = UfoActor.GetActorLocation();

		float RotationDelta = UfoActor.GetActorRotation().Yaw - LastRotationDelta;
		float AbsRotationDelta = FMath::Abs(RotationDelta);
		float NormalizedRotationDelta = FMath::Clamp(HazeAudio::NormalizeRTPC01(AbsRotationDelta, 0.f, 10.f), 0.f, 1.f);

		UfoHazeAkComp.SetRTPCValue(HazeAudio::RTPC::MoonBaboonUFORotationDelta, NormalizedRotationDelta, 0.f);		
		LastRotationDelta = UfoActor.GetActorRotation().Yaw;

		FHazeRequestLocomotionData Data;
		Data.AnimationTag = n"ControllableUFO";
		Player.RequestLocomotion(Data);
	}

	void ShowRotateTutorial()
	{
		bRotateTutorialShown = true;

		FTutorialPrompt Prompt;
		Prompt.Action = AttributeVectorNames::RightStickRaw;
		Prompt.DisplayType = ETutorialPromptDisplay::RightStick_LeftRight;
		Prompt.MaximumDuration = 5.f;
		Prompt.Text = RotateText;
		ShowTutorialPrompt(Player, Prompt, this);
	}
}