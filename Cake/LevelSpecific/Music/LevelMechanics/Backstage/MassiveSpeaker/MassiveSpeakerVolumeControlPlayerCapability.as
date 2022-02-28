import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MassiveSpeaker.MassiveSpeakerVolumeControl;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MassiveSpeaker.MassiveSpeakerVolumeControlPlayerAnimationComp;
import Vino.Movement.Components.MovementComponent;
import Vino.Tutorial.TutorialStatics;

class UMassiveSpeakerVolumeControlPlayerCapability : UHazeCapability
{
	default CapabilityTags.Add(n"MassiveVolumeSpeaker");
	
	default TickGroup = ECapabilityTickGroups::ActionMovement;
	default TickGroupOrder = 100;

	AHazePlayerCharacter Player;
	AMassiveSpeakerVolumeControl VolumeController;
	UMassiveSpeakerVolumeControlPlayerAnimationComp AnimComp;

	UPROPERTY()
	UMassiveSpeakerVolumeControlFeature Feature;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		AnimComp = Cast<UMassiveSpeakerVolumeControlPlayerAnimationComp>(Player.GetOrCreateComponent(UMassiveSpeakerVolumeControlPlayerAnimationComp::StaticClass()));
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{
		AMassiveSpeakerVolumeControl InteractingWith;

		InteractingWith = Cast<AMassiveSpeakerVolumeControl>(GetAttributeObject(n"VolumeController"));

		if(InteractingWith != nullptr)
		{
			return EHazeNetworkActivation::ActivateFromControl;
		}
		else
		{
			return EHazeNetworkActivation::DontActivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkDeactivation ShouldDeactivate() const
	{
		if (IsActioning(ActionNames::Cancel) || IsActioning(n"ForceExit"))
		{
			return EHazeNetworkDeactivation::DeactivateFromControl;
		}
		else
		{
			return EHazeNetworkDeactivation::DontDeactivate;
		}
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FCapabilityActivationParams ActivationParams)
	{
		UObject VolumeControllerOBj;
		ConsumeAttribute(n"VolumeController", VolumeControllerOBj);
		VolumeController = Cast<AMassiveSpeakerVolumeControl>(VolumeControllerOBj);
		VolumeController.Interaction.Disable(n"IsInteractedWith");
		VolumeController.SetCapabilityActionState(n"IsInteracting", EHazeActionState::Active);
		VolumeController.Speaker.InteractionComponent.Disable(n"PushingVolumeControl");
		
		Player.AttachToComponent(VolumeController.Interaction, AttachmentRule = EAttachmentRule::SnapToTarget);
		Player.BlockCapabilities(n"GroundMovement", this);
		Player.BlockCapabilities(CapabilityTags::LevelSpecific, this);
		Player.BlockCapabilities(n"SprintMovement", this);

		
		Player.AddLocomotionFeature(Feature);

		ShowCancelPrompt(Player, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		VolumeController.SetCapabilityActionState(n"IsInteracting", EHazeActionState::Inactive);
		VolumeController.Interaction.Enable(n"IsInteractedWith");
		VolumeController.Speaker.InteractionComponent.Enable(n"PushingVolumeControl");
		VolumeController.OnEndedInteract.Broadcast();
		
		VolumeController.PushingPlayer = nullptr;
		VolumeController = nullptr;
		
		Owner.DetachRootComponentFromParent(true);
		Player.RemoveLocomotionFeature(Feature);
		Player.UnblockCapabilities(n"GroundMovement", this);
		Player.UnblockCapabilities(n"SprintMovement", this);
		Player.UnblockCapabilities(CapabilityTags::LevelSpecific, this);

		RemoveCancelPromptByInstigator(Player,this);
		ConsumeAction(n"ForceExit");
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (HasControl())
		{
			FVector MoveVector = GetAttributeVector(AttributeVectorNames::MovementDirection);
			VolumeController.SetCapabilityAttributeVector(n"MoveVector", MoveVector);
			float Dot = MoveVector.GetSafeNormal().DotProduct(VolumeController.ActorForwardVector);
			
			VolumeController.InputSync.Value = Dot;
			PlayAnimations(Dot);

			float ForceFeedbackValue = FMath::Lerp(0.f, 0.5f, VolumeController.ProgressPercentage);
			Player.SetFrameForceFeedback(ForceFeedbackValue, ForceFeedbackValue * 0.65f);
		}
		else
		{
			PlayAnimations(VolumeController.InputSync.Value);
		}
	}

	void PlayAnimations(float Value)
	{
		AnimComp.Input = Value;
		FHazeRequestLocomotionData LocomotionData;
		LocomotionData.AnimationTag = Feature.Tag;
		
		UHazeMovementComponent::Get(Player).SetAnimationToBeRequested(Feature.Tag);
	}
}