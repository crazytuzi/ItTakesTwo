import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraActor;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieStage;
import Vino.PlayerHealth.PlayerHealthStatics;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfiePosePlayerComp;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfiePoseBase;

class ASelfiePoseSingleInteractionPoint : ASelfiePoseBase
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UInteractionComponent InteractionComp;

	UPROPERTY(Category = "Setup")
	ASelfieCameraActor SelfieCam;

	UPROPERTY(Category = "Setup")
	ASelfieStage SelfieStage;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent JumpToLocation;

	AHazePlayerCharacter CurrentPlayer;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MayEnterInteractionAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodyEnterInteractionAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MayExitInteractionAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent CodyExitInteractionAudioEvent;

	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet PlayerCapabilitySheet;

	UPROPERTY(Category = "Poses")
	TPerPlayer<UAnimSequence> AnimMHSolo;

	bool bPlayerMovementBlocked;

	UPROPERTY(Category = "Setup")
	EHazeMovementMethod MovementMethod;

	void BindFunctions() override
	{
		InteractionComp.OnActivated.AddUFunction(this, n"OnInteraction");
		
		OnStageTurnStarted.AddUFunction(this, n"StageTurnStartedDisable");
		OnStageTurnCompleted.AddUFunction(this, n"StageTurnCompletedEnable");
	}

	UFUNCTION()
	void StageTurnStartedDisable()
	{
		if (CurrentPlayer != nullptr)
			OnInteractionCancelled(CurrentPlayer);
		
		InteractionComp.Disable(n"StageTurning");
	}

	UFUNCTION()
	void StageTurnCompletedEnable()
	{
		InteractionComp.EnableAfterFullSyncPoint(n"StageTurning");
	}

	UFUNCTION()
	void OnInteraction(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		CurrentPlayer = Player;
		if (Player.IsMay())
			Player.PlayerHazeAkComp.HazePostEvent(MayEnterInteractionAudioEvent);
		else	
			Player.PlayerHazeAkComp.HazePostEvent(CodyEnterInteractionAudioEvent);
			
		Player.AttachToActor(SelfieStage, NAME_None, EAttachmentRule::KeepWorld);
		Player.AddCapabilitySheet(PlayerCapabilitySheet);

		if (!bPlayerMovementBlocked)
		{
			Player.TriggerMovementTransition(this);
			Player.BlockCapabilities(CapabilityTags::Movement, this);
			bPlayerMovementBlocked = true;
		}

		Player.OtherPlayer.DisableOutlineByInstigator(this);
		USelfiePosePlayerComp PlayerComp = USelfiePosePlayerComp::Get(Player);

		PlayerComp.OnPlayerCancelledPoseEvent.Clear();
		PlayerComp.OnPlayerCancelledPoseEvent.AddUFunction(this, n"OnInteractionCancelled");

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.2f;

		SelfieCam.Camera.ActivateCamera(Player, Blend, this);
		SelfieCam.TakeImageArea.AddSelfieImagePlayer(Player);

		if (Player.IsMay())
			Player.PlaySlotAnimation(bLoop = true, BlendTime = 0.3f, Animation = AnimMHSolo[0]);
		else
			Player.PlaySlotAnimation(bLoop = true, BlendTime = 0.3f, Animation = AnimMHSolo[1]);

		InteractComp.Disable(n"Selfie Posing");
	}

	UFUNCTION()
	void OnInteractionCancelled(AHazePlayerCharacter Player)
	{
		CurrentPlayer = nullptr;

		if (Player.IsMay())
			Player.PlayerHazeAkComp.HazePostEvent(MayExitInteractionAudioEvent);
		else	
			Player.PlayerHazeAkComp.HazePostEvent(CodyExitInteractionAudioEvent);
		
		Player.RemoveCapabilitySheet(PlayerCapabilitySheet);

		if (bPlayerMovementBlocked)
		{
			bPlayerMovementBlocked = false;
			Player.UnblockCapabilities(CapabilityTags::Movement, this);
		}

		Player.StopAllSlotAnimations(0.5f);
		Player.OtherPlayer.EnableOutlineByInstigator(this);
		
		SelfieCam.Camera.DeactivateCamera(Player, 1.5f);
		SelfieCam.TakeImageArea.RemoveSelfieImagePlayer(Player);
		SelfieCam.TakeImageArea.TakeImageSequenceDeactivated(Player);

		USelfiePosePlayerComp PlayerComp = USelfiePosePlayerComp::Get(Player);
		PlayerComp.HidePlayerCancel(Player);

		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		InteractionComp.EnableAfterFullSyncPoint(n"Selfie Posing");
	}
}