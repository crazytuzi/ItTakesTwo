import Vino.Interactions.DoubleInteractionActor;
import Peanuts.Audio.AudioStatics;

event void SwitchActivated();

class AShedPowerSwitchActor : AHazeActor
{
	UPROPERTY(RootComponent, DefaultComponent)
	USceneComponent Root;

	UPROPERTY()
	SwitchActivated OnSwitchStartPullDown;

	UPROPERTY()
	SwitchActivated OnStartCutscene;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	USkeletalMeshComponent LeverRoot;

	UPROPERTY()
	ADoubleInteractionActor DoubleInteraction;

	UPROPERTY()
	AHazeSkeletalMeshActor LeverMesh;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent OnePlayerOnSwitchAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StoppedUsingSwitchAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent DoubleInteractStartedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SwitchActivatedAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent SwitchBuzzAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent ReactivateLeverAudioEvent;

	UPROPERTY()
	UAnimSequence LeverMH;

	UPROPERTY()
	UAnimSequence LeverSuccess;

	UPROPERTY()
	UAnimSequence LeverReset;

	UPROPERTY()
	UAnimSequence CodyLeverSuccess;

	UPROPERTY()
	UAnimSequence MayLeverSuccess;

	UPROPERTY()
	FHazeTimeLike LeverDownTimeLike;

	UPROPERTY()
	FHazeTimeLike LeverUpTimeLike;

	int PlayersOnLever;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DoubleInteraction.OnDoubleInteractionCompleted.AddUFunction(this, n"SwitchActivated");
		DoubleInteraction.OnLeftInteractionReady.AddUFunction(this, n"OnPlayerJumpedOnLever");
		DoubleInteraction.OnRightInteractionReady.AddUFunction(this, n"OnPlayerJumpedOnLever");
		DoubleInteraction.OnPlayerCanceledDoubleInteraction.AddUFunction(this, n"OnPlayerReleased");
		DoubleInteraction.LeftInteraction.SetExclusiveForPlayer(EHazePlayer::May);
		DoubleInteraction.RightInteraction.SetExclusiveForPlayer(EHazePlayer::Cody);
		HazeAkComp.HazePostEvent(SwitchBuzzAudioEvent);
	}

	UFUNCTION()
	void LeverUpTimeLikeUpdate(float Alpha)
	{
		FRotator Rotation = LeverMesh.GetActorRotation();
		Rotation.Pitch = Alpha;
		LeverMesh.SetActorRotation(Rotation);
	}

	UFUNCTION()
	void OnPlayerJumpedOnLever(AHazePlayerCharacter Player)
	{
		FHazePlaySlotAnimationParams Params;
		Params.bLoop = true;
		Params.Animation = LeverMH;
		LeverMesh.PlaySlotAnimation(Params);

		if (PlayersOnLever < 1)
		{
			Player.AttachToActor(LeverMesh, AttachmentRule = EAttachmentRule::KeepWorld);
			LeverDownTimeLike.PlayFromStart();
			LeverDownTimeLike.BindUpdate(this, n"LeverTimeLikeUpdate");
		}
		if (PlayersOnLever > 0)
		{
			LeverDownTimeLike.Stop();
		}

		if (PlayersOnLever == 0)
		{
			HazeAudio::SetPlayerPanning(HazeAkComp, Player);
			HazeAkComp.HazePostEvent(OnePlayerOnSwitchAudioEvent);
		}

		PlayersOnLever++;
	}

	UFUNCTION()
	void LeverTimeLikeUpdate(float Alpha)
	{
		FRotator Rotation = LeverMesh.GetActorRotation();
		Rotation.Pitch = Alpha;

		LeverMesh.SetActorRotation(Rotation);
	}

	UFUNCTION()
	void OnPlayerReleased(AHazePlayerCharacter Player, UInteractionComponent Interaction, bool bIsLeftInteraction)
	{
		Player.DetachFromActor();
		LeverMesh.StopAnimation();

		if (PlayersOnLever == 1)
		{
			LeverDownTimeLike.Stop();
			Player.AttachToActor(LeverMesh, AttachmentRule = EAttachmentRule::KeepWorld);
			LeverUpTimeLike.PlayFromStart();
			LeverUpTimeLike.BindUpdate(this, n"LeverUpTimeLikeUpdate");
			HazeAudio::SetPlayerPanning(HazeAkComp, Player);
			HazeAkComp.HazePostEvent(StoppedUsingSwitchAudioEvent);
		}

		PlayersOnLever--;
	}

	UFUNCTION()
	void SwitchActivated()
	{
		for (auto Player : Game::GetPlayers())
		{
			Player.DetachFromActor();
			
		}
		for (auto Player : Game::GetPlayers())
		{
			if (Player.IsCody())
			{
				Player.TeleportActor(DoubleInteraction.RightInteraction.WorldLocation, DoubleInteraction.RightInteraction.WorldRotation);
			}
			else
			{
				Player.TeleportActor(DoubleInteraction.LeftInteraction.WorldLocation, DoubleInteraction.LeftInteraction.WorldRotation);
			}
		}

		HazeAkComp.HazePostEvent(DoubleInteractStartedAudioEvent);
		FHazeAnimationDelegate AnimDelegateBlendout;
		FHazeAnimationDelegate AnimDelegateBlendin;
		AnimDelegateBlendout.BindUFunction(this, n"SuccessDone");
		Game::GetCody().PlayEventAnimation(AnimDelegateBlendin, AnimDelegateBlendout, CodyLeverSuccess);
		Game::GetMay().PlayEventAnimation(AnimDelegateBlendin, AnimDelegateBlendin, MayLeverSuccess);

		OnSwitchStartPullDown.Broadcast();

		FHazePlaySlotAnimationParams Params;
		Params.bLoop = false;
		Params.Animation = LeverSuccess;
		LeverMesh.PlaySlotAnimation(Params);

		DoubleInteraction.LeftInteraction.Disable(n"Lever");
		DoubleInteraction.RightInteraction.Disable(n"Lever");
	}

	UFUNCTION()
	void SnapToInactive()
	{
		FHazePlaySlotAnimationParams Params;
		Params.bLoop = false;
		Params.Animation = LeverSuccess;
		Params.bPauseAtEnd = true;
		LeverMesh.PlaySlotAnimation(Params);

		DoubleInteraction.LeftInteraction.Disable(n"Lever");
		DoubleInteraction.RightInteraction.Disable(n"Lever");
	}

	UFUNCTION()
	void ReactivateLever(bool PlayAnimation = false)
	{
		if (!PlayAnimation)
		{
			DoubleInteraction.LeftInteraction.Enable(n"Lever");
			DoubleInteraction.RightInteraction.Enable(n"Lever");
		}
		
		PlayersOnLever = 0;
		UHazeAkComponent::HazePostEventFireForget(ReactivateLeverAudioEvent, this.GetActorTransform());

		if (PlayAnimation)
		{
			FHazeAnimationDelegate AnimFinishedDelegate;
			AnimFinishedDelegate.BindUFunction(this, n"ReactivateAnimFinished");
			FHazePlaySlotAnimationParams Params;
			Params.bLoop = false;
			Params.Animation = LeverReset;
			LeverMesh.PlaySlotAnimation(FHazeAnimationDelegate(), AnimFinishedDelegate, Params);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void ReactivateAnimFinished()
	{
		DoubleInteraction.LeftInteraction.Enable(n"Lever");
		DoubleInteraction.RightInteraction.Enable(n"Lever");
	}

	UFUNCTION()
	void SuccessDone()
	{
		OnStartCutscene.Broadcast();
		HazeAkComp.HazePostEvent(SwitchActivatedAudioEvent);
	}
}