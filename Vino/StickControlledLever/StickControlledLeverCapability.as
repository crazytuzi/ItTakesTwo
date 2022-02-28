import Vino.StickControlledLever.StickControlledLever;
import Vino.Movement.Capabilities.Standard.CharacterMovementCapability;
import Vino.Tutorial.TutorialStatics;

class UStickControlledLeverCapability : UCharacterMovementCapability
{
	default CapabilityTags.Add(n"Movement");
	default CapabilityTags.Add(n"MovementInput");
	default CapabilityTags.Add(n"Input");
	default CapabilityTags.Add(n"GameplayAction");

	default CapabilityDebugCategory = n"LevelSpecific";
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;

	bool bStop = false;

	AHazePlayerCharacter Player;
	AStickControlledLever Lever;
	UInteractionComponent InteractComp;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		Super::Setup(SetupParams);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
        if (GetAttributeObject(n"StickControlledLever") != nullptr)
			return EHazeNetworkActivation::ActivateUsingCrumb;
		else
			return EHazeNetworkActivation::DontActivate;
    }

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (bStop)
		    return EHazeNetworkDeactivation::DeactivateUsingCrumb;
        else
            return EHazeNetworkDeactivation::DontDeactivate;
	}

	UFUNCTION(BlueprintOverride)
	void ControlPreActivation(FCapabilityActivationSyncParams& Params)
	{
		Params.AddObject(n"Lever", GetAttributeObject(n"StickControlledLever"));
		Params.AddObject(n"InteractComp", GetAttributeObject(n"LeverInteractionComp"));
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		bStop = false;
		Lever = Cast<AStickControlledLever>(ActivationParams.GetObject(n"Lever"));
		InteractComp = Cast<UInteractionComponent>(ActivationParams.GetObject(n"InteractComp"));

		Player.BlockCapabilities(n"Movement", this);
		Player.BlockCapabilities(n"GameplayAction", this);
		Player.BlockCapabilities(n"Collision", this);
		ShowCancelPrompt(Player, this);

		Player.AttachToComponent(InteractComp, AttachmentRule = EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		Lever.LeverDeActivated();
		Lever = nullptr;

		Player.UnblockCapabilities(n"GameplayAction", this);
		Player.UnblockCapabilities(n"Movement", this);
		Player.UnblockCapabilities(n"Collision", this);
		RemoveCancelPromptByInstigator(Player, this);

		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);

		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{	
		if (HasControl())
		{
			if (Lever.bUseRawStickControls)
			{
				FVector LeftStickRaw = GetAttributeVector(AttributeVectorNames::LeftStickRaw);
				Lever.SetPlayerInput(LeftStickRaw.X);
			}
			else
			{
				FVector LeftStickVector = GetAttributeVector(AttributeVectorNames::MovementDirection);
				float RelativeMovement = LeftStickVector.DotProduct(-Lever.ActorForwardVector);
				Lever.SetPlayerInput(RelativeMovement);
			}
		}
		
		if (IsActioning(ActionNames::Cancel))
			bStop = true;

		if (IsActioning(n"ForceStopLever"))
			bStop = true;

		Player.SetAnimFloatParam(n"LeverDirection", Lever.GetLeverVelocity());
		Player.SetAnimFloatParam(n"LeverPosition", Lever.GetLeverPosition());

		if (MoveComp.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComp.MakeFrameMovement(n"StickControlledLeverCapability");
			MoveCharacter(FrameMove, Lever.AnimationFeatureTag);
		}
	}
}