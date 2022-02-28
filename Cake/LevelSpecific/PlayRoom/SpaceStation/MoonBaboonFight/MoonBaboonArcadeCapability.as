import Cake.LevelSpecific.PlayRoom.SpaceStation.MoonBaboonFight.MoonBaboonArcadeScreen;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureArcadeScreenLever;
import Vino.Tutorial.TutorialStatics;
import Peanuts.Audio.AudioStatics;

UCLASS(Abstract)
class UMoonBaboonArcadeCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::LevelSpecific);

	default CapabilityDebugCategory = n"Gameplay";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AMoonBaboonArcadeScreen ArcadeScreen;
	UHazeAkComponent HazeAkComp;

	UPROPERTY()
	ULocomotionFeatureArcadeScreenLever ArcadeFeature;

	UPROPERTY()
	FText ShootText;

	bool bLaserAvailable = true;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"ArcadeActive"))
        	return EHazeNetworkActivation::ActivateLocal;
        
        return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (!IsActioning(n"ArcadeActive"))
			return EHazeNetworkDeactivation::DeactivateFromControl;
		
		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		ArcadeScreen = Cast<AMoonBaboonArcadeScreen>(GetAttributeObject(n"ArcadeScreen"));
		ArcadeScreen.ActivateArcadeCamera(Player);
		ArcadeScreen.bActive = true;
		ArcadeScreen.PixelMoonBaboon.SetHiddenInGame(false, true);
		Player.BlockCapabilities(CapabilityTags::Collision, this);
		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.TeleportActor(ArcadeScreen.PlayerAttachmentPoint.WorldLocation, ArcadeScreen.PlayerAttachmentPoint.WorldRotation);
		FHazeCameraBlendSettings FoVBlend;
		FoVBlend.BlendTime = 0.f;
		Player.ApplyFieldOfView(70.f, FoVBlend, this, EHazeCameraPriority::Maximum);
		Player.TriggerMovementTransition(this);

		Player.AddLocomotionFeature(ArcadeFeature);

		ArcadeScreen.Joystick.SetAnimBoolParam(n"HasInteractingPlayer", true);

		HazeAkComp = UHazeAkComponent::Get(ArcadeScreen);

		if(ArcadeScreen.SearchingForTargetLoopingEvent != nullptr)
		{
			ArcadeScreen.SearchingForTargetLoopingEventInstance = ArcadeScreen.HazeAkComp.HazePostEvent(ArcadeScreen.SearchingForTargetLoopingEvent);
		}

		FTutorialPrompt ShootPrompt;
		ShootPrompt.Action = ActionNames::WeaponFire;
		ShootPrompt.Mode = ETutorialPromptMode::RemoveWhenPressed;
		ShootPrompt.Text = ShootText;
		ShowTutorialPrompt(Player, ShootPrompt, this);

		Player.AttachToComponent(ArcadeScreen.Joystick, n"Attach_Cody", EAttachmentRule::SnapToTarget);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		ArcadeScreen.DeactivateArcadeCamera(Player);
		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Collision, this);
		Player.ClearFieldOfViewByInstigator(this);
		Player.ClearLocomotionAssetByInstigator(this);
		RemoveTutorialPromptByInstigator(Player, this);
		Player.RemoveLocomotionFeature(ArcadeFeature);

		ArcadeScreen.Joystick.SetAnimBoolParam(n"HasInteractingPlayer", false);
	}

	UFUNCTION(BlueprintOverride)
	void OnRemoved()
	{

    }

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		FVector PlayerInput;
		if (HasControl())
		{
			PlayerInput = GetAttributeVector(AttributeVectorNames::LeftStickRaw) + GetAttributeVector(AttributeVectorNames::RightStickRaw);
			PlayerInput.X = FMath::Clamp(PlayerInput.X, -1.f, 1.f);
			PlayerInput.Y = FMath::Clamp(PlayerInput.Y, -1.f, 1.f);
			ArcadeScreen.JoystickSyncComp.SetValue(PlayerInput);
		}
		else
		{
			PlayerInput = ArcadeScreen.JoystickSyncComp.Value;
		}

		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::PilotingUFOJoystickLR, PlayerInput.X, 0.f);
		HazeAkComp.SetRTPCValue(HazeAudio::RTPC::PilotingUFOJoystickFB, PlayerInput.Y, 0.f);

		float CurrentMaxInput = (FMath::Max(FMath::Abs(PlayerInput.X), FMath::Abs(PlayerInput.Y)));				

		bool bIsLeverEventPlaying = ArcadeScreen.HazeAkComp.HazeIsEventActive(ArcadeScreen.LeverMovingEventInstance.EventID);

		if(ArcadeScreen.StartLeverMovingEvent != nullptr && !bIsLeverEventPlaying && CurrentMaxInput > 0.f)
		{
			ArcadeScreen.LeverMovingEventInstance = ArcadeScreen.HazeAkComp.HazePostEvent(ArcadeScreen.StartLeverMovingEvent);
		}
		else if(ArcadeScreen.StopLeverMovingEvent != nullptr && bIsLeverEventPlaying && CurrentMaxInput == 0.f)
		{
			ArcadeScreen.HazeAkComp.HazePostEvent(ArcadeScreen.StopLeverMovingEvent);
		}

		ArcadeScreen.UpdatePlayerInput(FVector2D(PlayerInput.X, PlayerInput.Y));

		Player.SetAnimFloatParam(n"JoystickInputX", PlayerInput.X);
		Player.SetAnimFloatParam(n"JoystickInputY", PlayerInput.Y);
		ArcadeScreen.Joystick.SetAnimFloatParam(n"JoystickInputX", PlayerInput.X);
		ArcadeScreen.Joystick.SetAnimFloatParam(n"JoystickInputY", PlayerInput.Y);

		FHazeRequestLocomotionData LocomotionData;
		LocomotionData.AnimationTag = ArcadeFeature.Tag;

		Player.RequestLocomotion(LocomotionData);

		if (WasActionStarted(ActionNames::WeaponFire) && bLaserAvailable)
		{
			bLaserAvailable = false;
			System::SetTimer(this, n"EnableLaser", 1.f, false);
			ArcadeScreen.FireLaser();
		}
	}

	UFUNCTION()
	void EnableLaser()
	{
		bLaserAvailable = true;
	}
}