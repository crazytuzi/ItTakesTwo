import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfiePosePlayerComp;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieStage;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraActor;
import Vino.PlayerHealth.PlayerHealthStatics;
import Vino.Movement.Capabilities.JumpTo.CharacterJumpToCapability;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfiePoseBase;

class ASelfiePoseTogetherInteractionPoint : ASelfiePoseBase
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UInteractionComponent InteractionCompMay;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UInteractionComponent InteractionCompCody;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent MoveToLocationDefault;

	UPROPERTY(DefaultComponent, Attach = "Root")
	USceneComponent MoveToLocationCody;

	UPROPERTY(Category = "Setup")
	ASelfieCameraActor SelfieCam;

	UPROPERTY(Category = "Setup")
	ASelfieStage SelfieStage;

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

	UPROPERTY(Category = "Poses")
	TPerPlayer<UAnimSequence> AnimMHTogether;

	UPROPERTY(Category = "Setup")
	TPerPlayer<EHazeMovementMethod> MovementMethod;
	default MovementMethod[0] = EHazeMovementMethod::SmoothTeleport;
	default MovementMethod[1] = EHazeMovementMethod::SmoothTeleport;

	UPROPERTY(Category = "Setup")
	bool bUseBothMoveToLocations;

	UPROPERTY(Category = "Setup")
	bool bTogetherPose;

	TPerPlayer<bool> bPlayerMovementBlocked;
	TPerPlayer<bool> bPlayerIn;

	float AnimBlendTime = 0.4f;

	UFUNCTION()
	void BindFunctions() override
	{
		InteractionCompMay.DisableForPlayer(Game::Cody, n"NotForYouCody");
		InteractionCompCody.DisableForPlayer(Game::May, n"NotForYouMay");

		InteractionCompMay.OnActivated.AddUFunction(this, n"OnInteraction");
		InteractionCompCody.OnActivated.AddUFunction(this, n"OnInteraction");

		OnStageTurnStarted.AddUFunction(this, n"StageTurnStartedDisable");
		OnStageTurnCompleted.AddUFunction(this, n"StageTurnCompletedEnable");
	}

	UFUNCTION()
	void StageTurnStartedDisable()
	{
		OnInteractionCancelled(Game::May);
		OnInteractionCancelled(Game::Cody);
		InteractionCompMay.Disable(n"StageTurning");
		InteractionCompCody.Disable(n"StageTurning");
	}

	UFUNCTION()
	void StageTurnCompletedEnable()
	{
		InteractionCompMay.EnableAfterFullSyncPoint(n"StageTurning");
		InteractionCompCody.EnableAfterFullSyncPoint(n"StageTurning");
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		if (bPlayerIn[0] && !bPlayerMovementBlocked[0] && !Game::May.IsAnyCapabilityActive(n"CharacterJumpToCapability"))
			SetMovementDisabled(Game::May, true);
		
		if (bPlayerIn[1] && !bPlayerMovementBlocked[1] && !Game::Cody.IsAnyCapabilityActive(n"CharacterJumpToCapability"))
			SetMovementDisabled(Game::Cody, true);
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
		Player.OtherPlayer.DisableOutlineByInstigator(this);
		
		//No callback for when movement transition begins on interaction component. Handling this manually so that together animations can 
		//occur simultaneously as the player moves to the interaction point
		FHazeJumpToData JumpData;
		JumpData.SmoothTeleportRange = 0.f;
		JumpData.AdditionalHeight = 25.f;

		switch (MovementMethod[Player])
		{
			case EHazeMovementMethod::JumpTo: 
				JumpData.TargetComponent = InteractComp;
				JumpTo::ActivateJumpTo(Player, JumpData);
			break;
			
			case EHazeMovementMethod::SmoothTeleport:
				SetMovementDisabled(Player, true);
				Player.SmoothSetLocationAndRotation(InteractComp.WorldLocation, InteractComp.WorldRotation);
			break;
		}

		USelfiePosePlayerComp PlayerComp = USelfiePosePlayerComp::Get(Player);

		PlayerComp.OnPlayerCancelledPoseEvent.Clear();
		PlayerComp.OnPlayerCancelledPoseEvent.AddUFunction(this, n"OnInteractionCancelled");
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.2f;

		SelfieCam.Camera.ActivateCamera(Player, Blend, this);
		SelfieCam.TakeImageArea.AddSelfieImagePlayer(Player);

		bPlayerIn[Player] = true;

		if (bTogetherPose)
		{
			if (bPlayerIn[0] && bPlayerIn[1])
				SetAsTogetherPose();
			else if (bPlayerIn[0])
				SetAsCentralPose(Game::May);
			else if (bPlayerIn[1])
				SetAsCentralPose(Game::Cody);
		}
		else
		{
			SetAsCentralPose(Player);
		}

		InteractComp.Disable(n"SelfiePosing");
	}

	UFUNCTION()
	void SetMovementDisabled(AHazePlayerCharacter Player, bool bValue)
	{
		if (bValue && !bPlayerMovementBlocked[Player])
		{
			Player.TriggerMovementTransition(this);
			Player.BlockCapabilities(CapabilityTags::Movement, this);
			bPlayerMovementBlocked[Player] = true;
		}
		else if (!bValue && bPlayerMovementBlocked[Player])
		{
			Player.UnblockCapabilities(CapabilityTags::Movement, this);
			bPlayerMovementBlocked[Player] = false;
		}
	}

	UFUNCTION()
	void SetAsTogetherPose()
	{
		Game::May.PlaySlotAnimation(bLoop = true, BlendTime = AnimBlendTime, Animation = AnimMHTogether[0]);
		Game::Cody.PlaySlotAnimation(bLoop = true, BlendTime = AnimBlendTime, Animation = AnimMHTogether[1]);
	}

	UFUNCTION()
	void SetAsCentralPose(AHazePlayerCharacter Player)
	{
		if (Player.IsMay())
			Player.PlaySlotAnimation(bLoop = true, BlendTime = AnimBlendTime, Animation = AnimMHSolo[0]);
		else
			Player.PlaySlotAnimation(bLoop = true, BlendTime = AnimBlendTime, Animation = AnimMHSolo[1]);
	}

	UFUNCTION()
	void OnInteractionCancelled(AHazePlayerCharacter Player)
	{
		if (!bPlayerIn[Player])
			return;
			
		if (Player.IsMay())
			Player.PlayerHazeAkComp.HazePostEvent(MayExitInteractionAudioEvent);
		else
			Player.PlayerHazeAkComp.HazePostEvent(CodyExitInteractionAudioEvent);

		Player.RemoveCapabilitySheet(PlayerCapabilitySheet);
		Player.StopAllSlotAnimations(AnimBlendTime);

		USelfiePosePlayerComp PlayerComp = USelfiePosePlayerComp::Get(Player);
		PlayerComp.HidePlayerCancel(Player);
		Player.OtherPlayer.EnableOutlineByInstigator(this);

		SelfieCam.Camera.DeactivateCamera(Player, 1.5f);
		SelfieCam.TakeImageArea.RemoveSelfieImagePlayer(Player);
		SelfieCam.TakeImageArea.TakeImageSequenceDeactivated(Player);

		Player.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		
		bPlayerIn[Player] = false;

		GetPlayerInteraction(Player).EnableAfterFullSyncPoint(n"SelfiePosing");

		if (bPlayerIn[Player.OtherPlayer])
			SetAsCentralPose(Player.OtherPlayer);

		SetMovementDisabled(Player, false);
		
		FHazeJumpToData JumpData;

		switch (MovementMethod[Player])
		{
			case EHazeMovementMethod::JumpTo: 

				if (bUseBothMoveToLocations)
				{
					JumpData.AdditionalHeight = -10.f;

					if (Player.IsMay())
						JumpData.TargetComponent = MoveToLocationDefault;
					else
						JumpData.TargetComponent = MoveToLocationCody;

					JumpTo::ActivateJumpTo(Player, JumpData);
				}
				else
				{
					JumpData.TargetComponent = MoveToLocationDefault;
					JumpData.AdditionalHeight = -15.f;
					JumpTo::ActivateJumpTo(Player, JumpData);
				}
			break;
			
			case EHazeMovementMethod::SmoothTeleport: 

				if (bUseBothMoveToLocations)
				{
					if (Player.IsMay())
						Player.SmoothSetLocationAndRotation(MoveToLocationDefault.WorldLocation, MoveToLocationDefault.WorldRotation);
					else
						Player.SmoothSetLocationAndRotation(MoveToLocationCody.WorldLocation, MoveToLocationCody.WorldRotation);
				}
				else
				{
					Player.SmoothSetLocationAndRotation(MoveToLocationDefault.WorldLocation, MoveToLocationDefault.WorldRotation);
				}
			break;
		}
	}

	UInteractionComponent GetPlayerInteraction(AHazePlayerCharacter Player)
	{
		if (Player.IsMay())
			return InteractionCompMay;
			
		return InteractionCompCody;
	}
}