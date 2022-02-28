import Cake.LevelSpecific.PlayRoom.SpaceStation.TractorBeamTerminal;
import Vino.Tutorial.TutorialStatics;

class UControlTractorBeamCapability : UHazeCapability
{
    default CapabilityTags.Add(n"Gravity");
    default CapabilityTags.Add(CapabilityTags::LevelSpecific);
	
	default TickGroup = ECapabilityTickGroups::BeforeMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
    ATractorBeamTerminal TractorBeamTerminal;

	FVector CurrentInput;

	ULocomotionFeatureArcadeScreenLever Feature;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (IsActioning(n"ControllingTractorBeam"))
            return EHazeNetworkActivation::ActivateFromControl;
        else
            return EHazeNetworkActivation::DontActivate;
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
        if (WasActionStarted(ActionNames::Cancel))
		    return EHazeNetworkDeactivation::DeactivateFromControl;
        else
		    return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		CurrentInput = FVector::ZeroVector;
        TractorBeamTerminal = Cast<ATractorBeamTerminal>(GetAttributeObject(n"TractorBeamTerminal"));
        Player.SetCapabilityActionState(n"ControllingTractorBeam", EHazeActionState::Inactive);
        Player.BlockCapabilities(CapabilityTags::Movement, this);
        Player.BlockCapabilities(CapabilityTags::TotemMovement, this);
		Player.TriggerMovementTransition(this);

		FTutorialPrompt Prompt;
		Prompt.Action = AttributeVectorNames::MovementRaw;
		Prompt.DisplayType = ETutorialPromptDisplay::LeftStick_LeftRightUpDown;
		Prompt.MaximumDuration = 4.f;
		ShowTutorialPrompt(Player, Prompt, this);

		ShowCancelPrompt(Player, this);

		Feature = Player.IsMay() ? TractorBeamTerminal.MayFeature : TractorBeamTerminal.CodyFeature;
		Player.AddLocomotionFeature(Feature);

		TractorBeamTerminal.Joystick.SetAnimBoolParam(n"HasInteractingPlayer", true);

		FName PlayerAttachSocket = Player.IsMay() ? n"Attach_May" : n"Attach_Cody";
		Player.AttachToComponent(TractorBeamTerminal.Joystick, PlayerAttachSocket, EAttachmentRule::SnapToTarget);

		TractorBeamTerminal.SyncInputComp.OverrideControlSide(Player);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		TractorBeamTerminal.DeactivateTractorBeam(Player);
        Player.UnblockCapabilities(CapabilityTags::Movement, this);
        Player.UnblockCapabilities(CapabilityTags::TotemMovement, this);

		RemoveTutorialPromptByInstigator(Player, this);
		RemoveCancelPromptByInstigator(Player, this);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		Player.RemoveLocomotionFeature(Feature);

		TractorBeamTerminal.Joystick.SetAnimBoolParam(n"HasInteractingPlayer", false);

		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (Player.HasControl())
		{
        	FVector Input = GetAttributeVector(AttributeVectorNames::LeftStickRaw);
			FVector RightStickInput = FVector::ZeroVector;
			if (Player.IsUsingGamepad())
			{
				RightStickInput = GetAttributeVector(AttributeVectorNames::RightStickRaw);
			}

			Input += RightStickInput;
			Input.X = FMath::Clamp(Input.X, -1.f, 1.f);
			Input.Y = FMath::Clamp(Input.Y, -1.f, 1.f);
				
			CurrentInput = FMath::VInterpTo(CurrentInput, Input, DeltaTime, 5.f);
        	TractorBeamTerminal.RotateTower(FVector2D(CurrentInput.X, CurrentInput.Y));

			TractorBeamTerminal.SyncInputComp.SetValue(Input);

			if (Input.Size() != 0.f)
				Player.SetFrameForceFeedback(FMath::Abs(Input.Y) * 0.1f, FMath::Abs(Input.X) * 0.1f);
		}

		Player.SetAnimFloatParam(n"JoystickInputX", TractorBeamTerminal.SyncInputComp.Value.X);
		Player.SetAnimFloatParam(n"JoystickInputY", -TractorBeamTerminal.SyncInputComp.Value.Y);
		TractorBeamTerminal.Joystick.SetAnimFloatParam(n"JoystickInputX", TractorBeamTerminal.SyncInputComp.Value.X);
		TractorBeamTerminal.Joystick.SetAnimFloatParam(n"JoystickInputY", -TractorBeamTerminal.SyncInputComp.Value.Y);

		FHazeRequestLocomotionData LocomotionData;
		LocomotionData.AnimationTag = Feature.Tag;

		Player.RequestLocomotion(LocomotionData);
	}
}