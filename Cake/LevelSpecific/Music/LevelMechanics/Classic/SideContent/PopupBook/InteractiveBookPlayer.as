import Cake.LevelSpecific.Music.LevelMechanics.Classic.SideContent.PopupBook.InteractiveBookManager;
import Vino.Animations.LockIntoAnimation;
import Vino.Tutorial.TutorialStatics;
import Peanuts.Audio.AudioStatics;


void SetInteractiveBookManager(AInteractiveBookManager Manager, UInteractionComponent Interaction, AHazePlayerCharacter Player)
{
	auto BookComp = UInteractiveBookPlayerComponent::Get(Player);
	BookComp.Manager = Manager;
	BookComp.ActiveInteraction = Interaction;
}

UCLASS()
class UInteractiveBookPlayerComponent : UActorComponent
{
	UPROPERTY(Category = "Animation")
	UBlendSpace PlayerBlendSpace;

	UPROPERTY(Category = "Animation")
	FVector InteractionOffset;

	// How long time it will take to move the slide
	UPROPERTY(Category = "Animation")
	float MoveTime = 0.8f;

	UPROPERTY(Category = "Text")
	FText ExitText;

	AInteractiveBookManager Manager;
	UInteractionComponent ActiveInteraction;
}


class UInteractiveBookPlayerCapability : UHazeCapability
{
    default CapabilityTags.Add(CapabilityTags::Interaction);
    default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = ECapabilityTickGroups::BeforeMovement;

	AHazePlayerCharacter Player;
	UInteractiveBookPlayerComponent BookComponent;
	UHazeMovementComponent MoveComponent;
	UHazeSmoothSyncFloatComponent SyncComponent;
	TArray<AInteractiveBookPawn> Pawns;

	bool bPlayerHasExit = false;
	bool bIsShowingTutorial = false;
	FHazeAcceleratedFloat AcceleratedValue;

	UFUNCTION(BlueprintOverride)
	void Setup(FCapabilitySetupParams SetupParams)
	{
		Player = Cast<AHazePlayerCharacter>(Owner);
		BookComponent = UInteractiveBookPlayerComponent::Get(Player);
		MoveComponent = UHazeMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	EHazeNetworkActivation ShouldActivate() const
	{		
		return EHazeNetworkActivation::ActivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
    EHazeNetworkDeactivation ShouldDeactivate() const
	{	
		if(!bPlayerHasExit)
			return EHazeNetworkDeactivation::DontDeactivate;

		return EHazeNetworkDeactivation::DeactivateUsingCrumb;
	}

	UFUNCTION(BlueprintOverride)
    void OnActivated(FCapabilityActivationParams ActivationParams)
    {	
		bPlayerHasExit = false;
		LockIntoAnimation(Player, this);
		Player.BlockCapabilities(n"Collision", this);
		ShowCancelPrompt(Player, this);
		Player.TriggerMovementTransition(this);

		FTransform InteractionTransform = BookComponent.ActiveInteraction.GetWorldTransform();
		InteractionTransform.AddToTranslation(InteractionTransform.TransformVector(BookComponent.InteractionOffset));
		Player.SetActorTransform(InteractionTransform);
		PerformMoveToGround();

		if(BookComponent.ActiveInteraction == BookComponent.Manager.LeftInteraction)
		{
			SyncComponent = BookComponent.Manager.LeftMoveAmount;
			Pawns = BookComponent.Manager.LeftPawns;
		}
		else
		{
			SyncComponent = BookComponent.Manager.RightMoveAmount;
			Pawns = BookComponent.Manager.RightPawns;
		}

		SyncComponent.OverrideControlSide(Player);
		AcceleratedValue.SnapTo(SyncComponent.Value); 

		bIsShowingTutorial = true;
		FTutorialPrompt TutorialPrompt;
		TutorialPrompt.DisplayType = ETutorialPromptDisplay::LeftStick_UpDown;
		ShowTutorialPrompt(Player, TutorialPrompt, this);
		Player.BlockMovementSyncronization(this);

		Player.PlayBlendSpace(BookComponent.PlayerBlendSpace);

		Player.ApplyIdealDistance(400.f, FHazeCameraBlendSettings(2.f), this);
		Player.ApplyCameraOffsetOwnerSpace(FVector(0.f, 0.f, 80.f), FHazeCameraBlendSettings(), this);

		Player.PlayerHazeAkComp.HazePostEvent(BookComponent.Manager.PlayMovementAudioEvent);
    }

	UFUNCTION(BlueprintOverride)
	void OnDeactivated(FCapabilityDeactivationParams DeactivationParams)
	{
		bPlayerHasExit = false;
		UnlockFromAnimation(Player, this);
		Player.UnblockCapabilities(n"Collision", this);
		RemoveCancelPromptByInstigator(Player, this);
		Player.StopBlendSpace();
		Player.UnblockMovementSyncronization(this);
		Player.PlayerHazeAkComp.HazePostEvent(BookComponent.Manager.StopMovementAudioEvent);

		if(DeactivationParams.DeactivationReason == ECapabilityStatusChangeReason::Natural
			&& MoveComponent.CanCalculateMovement())
		{
			FTransform InteractionTransform = BookComponent.ActiveInteraction.GetWorldTransform();
			Player.MeshOffsetComponent.FreezeAndResetWithTime(0.25f);
			InteractionTransform.AddToTranslation(InteractionTransform.TransformVector(FVector(-80.f, 0.f, 0.f)));
			Player.SetActorTransform(InteractionTransform);
			PerformMoveToGround();
		}

		if(bIsShowingTutorial)
			RemoveTutorialPromptByInstigator(Player, this);
		bIsShowingTutorial = false;
		SyncComponent = nullptr;

		// This needs to be last, since this will remove the capability sheet
		BookComponent.Manager.OnInteractionLeft(BookComponent.ActiveInteraction, Player);

		Player.ClearIdealDistanceByInstigator(this);
		Player.ClearCameraOffsetOwnerSpaceByInstigator(this);
		Player.ConsumeButtonInputsRelatedTo(ActionNames::Cancel);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(HasControl())
		{
			if(WasActionStarted(ActionNames::Cancel) && GetActiveDuration() > 0.25f)
			{
				bPlayerHasExit = true;
			}
			else
			{
				FVector Input = GetAttributeVector(AttributeVectorNames::MovementRaw);
				if(bIsShowingTutorial && FMath::Abs(Input.X) > KINDA_SMALL_NUMBER)
				{
					NetHideTutorial();
				}

				float WantedSyncValue = 1.f - ((Input.X + 1) * 0.5f);
				SyncComponent.Value = AcceleratedValue.AccelerateTo(WantedSyncValue, BookComponent.MoveTime, DeltaTime);
			}
		}	

		Player.SetBlendSpaceValues(0.f, SyncComponent.Value);
		for(auto Pawn : Pawns)
		{
			Pawn.SetMoveCurrentMoveAmount(SyncComponent.Value);
		}

		float NormalizedVelocity = HazeAudio::NormalizeRTPC01(FMath::Abs(AcceleratedValue.Velocity), 0.f, 1.8f);

		Player.PlayerHazeAkComp.SetRTPCValue("Rtpc_World_SideContent_Music_InteractivePictureBook_Velocity", NormalizedVelocity);
	}

	UFUNCTION(NetFunction)
	void NetHideTutorial()
	{
		if(!bIsShowingTutorial)
			return;

		bIsShowingTutorial = false;
		RemoveTutorialPromptByInstigator(Player, this);
	}

	void PerformMoveToGround()
	{
		if(MoveComponent.CanCalculateMovement())
		{
			FHazeFrameMovement FrameMove = MoveComponent.MakeFrameMovement(n"LandOnGround");
			FrameMove.OverrideGroundedState(EHazeGroundedState::Grounded);
			FrameMove.OverrideStepDownHeight(500.f);
			MoveComponent.Move(FrameMove);
		}
	}
}