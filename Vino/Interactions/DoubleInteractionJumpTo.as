import Vino.Interactions.DoubleInteractionActor;

class ADoubleInteractionJumpTo : ADoubleInteractionActor
{
	default bUsePredictiveAnimation = false;

	default LeftInteraction.MovementSettings.InitializeNoMovement();
	default RightInteraction.MovementSettings.InitializeNoMovement();

	UPROPERTY(EditInstanceOnly, Category = "Interaction Attachment")
	AActor LeftInteractionAttachActor;

	UPROPERTY(EditInstanceOnly, Category = "Interaction Attachment")
	FName LeftInteractionAttachComponent;

	UPROPERTY(EditInstanceOnly, Category = "Interaction Attachment")
	AActor RightInteractionAttachActor;

	UPROPERTY(EditInstanceOnly, Category = "Interaction Attachment")
	float AddtionalJumpHeight = 150.f;

	UPROPERTY(EditInstanceOnly, Category = "Interaction Attachment")
	FName RightInteractionAttachComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		HandleAttachment(LeftInteraction, LeftInteractionAttachActor, LeftInteractionAttachComponent);
		HandleAttachment(RightInteraction, RightInteractionAttachActor, RightInteractionAttachComponent);
	}

	UFUNCTION(BlueprintOverride)
	bool CanInteractionBeCompleted()
	{
		return true;
	}

	void HandleAttachment(USceneComponent Comp, AActor AttachActor, FName AttachComponent)
	{
		if (AttachActor == nullptr)
			return;

		USceneComponent Target;
		if (AttachComponent != NAME_None)
			Target = USceneComponent::Get(AttachActor, AttachComponent);
		else
			Target = AttachActor.RootComponent;

		if (Target != nullptr)
			Comp.AttachToComponent(Target, NAME_None, EAttachmentRule::KeepWorld);
	}

	UFUNCTION(BlueprintOverride)
	void OnStartedInteracting(AHazePlayerCharacter Player, UInteractionComponent UsedInteraction)
	{
		FHazeJumpToData Settings;
		Settings.TargetComponent = UsedInteraction;
		Settings.AdditionalHeight = AddtionalJumpHeight;

		FHazeDestinationEvents Events;
		Events.OnDestinationReached.BindUFunction(this, n"JumpToCompleted");
		JumpTo::ActivateJumpTo(Player, Settings, Events);
	}

	UFUNCTION()
	void JumpToCompleted(AHazeActor Actor)
	{
		// Start the regular threeshot animation that the double interaction uses
		StartAnimation(Cast<AHazePlayerCharacter>(Actor));
	}
};