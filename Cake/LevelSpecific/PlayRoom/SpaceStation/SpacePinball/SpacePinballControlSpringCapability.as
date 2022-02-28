import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePinball.SpacePinballSpring;
import Vino.Tutorial.TutorialStatics;
import Vino.Tutorial.TutorialPrompt;
import Cake.LevelSpecific.PlayRoom.SpaceStation.SpacePinball.SpacePinballToggleableWall;

class USpacePinballControlSpringCapability : UHazeCapability
{
	default CapabilityTags.Add(n"Example");

	default CapabilityDebugCategory = n"Example";
	
	default TickGroup = ECapabilityTickGroups::Input;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	ASpacePinballSpring TargetSpring;

	bool bBallReleased = false;

	float ToggleWallsCooldown = 0.5f;
	float TimeSinceWallToggle = 0.f;

	float LastSpringLocation = 0.f;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		if (IsActioning(n"ControlPinballSpring"))
        	return EHazeNetworkActivation::ActivateUsingCrumb;

		return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (TargetSpring == nullptr)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		if (!TargetSpring.bControlled)
			return EHazeNetworkDeactivation::DeactivateFromControl;

		return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& OutParams)
	{
        OutParams.AddObject(n"PinballSpring", GetAttributeObject(n"PinballSpring"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		TargetSpring = Cast<ASpacePinballSpring>(ActivationParams.GetObject(n"PinballSpring"));

		LastSpringLocation = TargetSpring.MainAttachPoint.RelativeLocation.Y;
		bBallReleased = false;
		TimeSinceWallToggle = ToggleWallsCooldown;
		Player.TriggerMovementTransition(this);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::InteractionTrigger);

		Player.BlockCapabilities(CapabilityTags::Movement, this);
		Player.BlockCapabilities(CapabilityTags::Interaction, this);
		Player.BlockCapabilities(n"FindOtherPlayer", this);

		Player.ApplyCameraSettings(TargetSpring.CamSettings, FHazeCameraBlendSettings(2.f), this);

		Player.AttachToComponent(TargetSpring.InteractionComp, AttachmentRule = EAttachmentRule::KeepWorld);

		FTutorialPrompt ToggleWallsTutorial;
		ToggleWallsTutorial.Action = ActionNames::SecondaryLevelAbility;
		ToggleWallsTutorial.Text = TargetSpring.ToggleWallsTutorialText;
		ShowTutorialPrompt(Player, ToggleWallsTutorial, Player);

		FTutorialPrompt ReleaseTutorial;
		ReleaseTutorial.Action = ActionNames::PrimaryLevelAbility;
		ReleaseTutorial.Text = TargetSpring.ReleaseTutorialText;
		ShowTutorialPrompt(Player, ReleaseTutorial, this);

		Player.AddLocomotionFeature(TargetSpring.Feature);

		FHazePointOfInterest PoISettings;
		PoISettings.FocusTarget.Component = TargetSpring.SpringRoot;
		PoISettings.FocusTarget.LocalOffset = FVector(3000.f, 0.f, -500.f);
		PoISettings.Duration = 1.f;
		PoISettings.Blend.BlendTime = 1.f;
		Player.ApplyPointOfInterest(PoISettings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Player.SetCapabilityActionState(n"ControlPinballSpring", EHazeActionState::Inactive);
		TargetSpring.InteractionCancelled();
		Player.RemoveLocomotionFeature(TargetSpring.Feature);
		Player.PlayEventAnimation(Animation = TargetSpring.ExitAnimation);
		TargetSpring = nullptr;

		Player.UnblockCapabilities(CapabilityTags::Movement, this);
		Player.UnblockCapabilities(CapabilityTags::Interaction, this);
		Player.UnblockCapabilities(n"FindOtherPlayer", this);

		Player.ClearCameraSettingsByInstigator(this);

		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		RemoveTutorialPromptByInstigator(Player, this);
		RemoveTutorialPromptByInstigator(Player, Player);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (!bBallReleased)
		{
			FVector2D Input = GetAttributeVector2D(AttributeVectorNames::MovementRaw);
			TargetSpring.UpdateInput(Input.Y);
			Player.SetAnimFloatParam(n"PinballSidewaysMovement", Input.Y);
		}
		if (!HasControl())
		{
			if (FMath::IsNearlyEqual(LastSpringLocation, TargetSpring.SyncFloatComp.Value, 0.1f))
				Player.SetAnimFloatParam(n"PinballSidewaysMovement", 0.f);
			else if (LastSpringLocation > TargetSpring.SyncFloatComp.Value)
				Player.SetAnimFloatParam(n"PinballSidewaysMovement", -1.f);
			else if (LastSpringLocation < TargetSpring.SyncFloatComp.Value)
				Player.SetAnimFloatParam(n"PinballSidewaysMovement", 1.f);

			LastSpringLocation = TargetSpring.SyncFloatComp.Value;
		}

		if (WasActionStarted(ActionNames::PrimaryLevelAbility) && !bBallReleased && TimeSinceWallToggle >= ToggleWallsCooldown)
		{
			NetPlayReleaseAnimation();
		}

		TimeSinceWallToggle += DeltaTime;

		if (WasActionStarted(ActionNames::SecondaryLevelAbility) && TimeSinceWallToggle >= ToggleWallsCooldown)
		{
			NetToggleWall();
		}

		FHazeRequestLocomotionData Data;
		Data.AnimationTag = n"Pinball";
		Player.RequestLocomotion(Data);
	}

	UFUNCTION(NetFunction)
	void NetToggleWall()
	{
		TimeSinceWallToggle = 0.f;
		Player.PlayForceFeedback(TargetSpring.ToggleWallsRumble, false, true, n"ToggleWalls");
		TArray<ASpacePinballToggleableWall> Walls;
		GetAllActorsOfClass(Walls);

		for (ASpacePinballToggleableWall CurWall : Walls)
		{
			CurWall.MoveWall();
		}

		Player.SetAnimBoolParam(n"HitLeft", true);
	}

	UFUNCTION(NetFunction)
	void NetPlayReleaseAnimation()
	{
		bBallReleased = true;
		TimeSinceWallToggle = 0.f;
		Player.PlayForceFeedback(TargetSpring.ReleaseRumble, false, true, n"Release");
		RemoveTutorialPromptByInstigator(Player, this);
		Player.SetAnimFloatParam(n"PinballSidewaysMovement", 0.f);
		Player.SetAnimBoolParam(n"HitRight", true);
		System::SetTimer(this, n"ReleaseBall", 0.2f, false);
		TargetSpring.VOBank.PlayFoghornVOBankEvent(n"FoghornDBPlayRoomSpaceStationPinballLaunchMay");
	}

	UFUNCTION(NotBlueprintCallable)
	void ReleaseBall()
	{
		TargetSpring.ReleaseBall();
	}
}