import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfiePosePlayerComp;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieStage;
import Cake.LevelSpecific.Tree.SelfieCamera.SelfieCameraActor;
import Vino.PlayerHealth.PlayerHealthStatics;

class ASelfiePoseInteractionPoint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY(DefaultComponent, Attach = "Root")
	UInteractionComponent InteractionComp;

	TArray<ASelfieCameraActor> SelfieCamArray;
	ASelfieCameraActor SelfieCam;

	ASelfieStage SelfieStage;

	AHazePlayerCharacter CurrentPlayer;

	UPROPERTY(Category = "Capabilities")
	UHazeCapabilitySheet PlayerCapabilitySheet;

	UPROPERTY(Category = "Poses")
	TPerPlayer<UAnimSequence> AnimEnter;

	UPROPERTY(Category = "Poses")
	TPerPlayer<UAnimSequence> AnimMH;

	UPROPERTY(Category = "Poses")
	TPerPlayer<UAnimSequence> AnimExit;

	FOnPlayerDied PlayerDiedDelegate;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(SelfieCamArray);
		SelfieStage = GetSelfieStage();

		if (SelfieCamArray.Num() > 0)
			SelfieCam = SelfieCamArray[0];

		InteractionComp.OnActivated.AddUFunction(this, n"OnInteraction");
	}

	UFUNCTION()
	void OnInteraction(UInteractionComponent InteractComp, AHazePlayerCharacter Player)
	{
		CurrentPlayer = Player;
		CurrentPlayer.AttachToActor(SelfieStage, NAME_None, EAttachmentRule::KeepWorld);

		CurrentPlayer.AddCapabilitySheet(PlayerCapabilitySheet);

		USelfiePosePlayerComp PlayerComp = USelfiePosePlayerComp::Get(CurrentPlayer);
		PlayerComp.OnPlayerCancelledPoseEvent.Clear();
		PlayerComp.OnPlayerCancelledPoseEvent.AddUFunction(this, n"OnInteractionCancelled");
		
		if (HasControl())
		{
			PlayerDiedDelegate.BindUFunction(this, n"PlayerDied");
			BindOnPlayerDiedEvent(PlayerDiedDelegate);
		}

		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 1.2f;

		SelfieCam.Camera.ActivateCamera(CurrentPlayer, Blend, this);
		SelfieCam.TakeImageArea.AddSelfieImagePlayer(CurrentPlayer);

		FHazeAnimationDelegate EnterBlendingOut;
		EnterBlendingOut.BindUFunction(this, n"StartMHLoop");

		if (CurrentPlayer.IsMay())
			CurrentPlayer.PlaySlotAnimation(BlendTime = 0.4f, Animation = AnimEnter[0], OnBlendingOut = EnterBlendingOut);
		else
			CurrentPlayer.PlaySlotAnimation(BlendTime = 0.4f, Animation = AnimEnter[1], OnBlendingOut = EnterBlendingOut);

		InteractionComp.Disable(n"Selfie Posing");
	}

	UFUNCTION()
	void StartMHLoop()
	{
		if (CurrentPlayer == nullptr)
			return;

		if (CurrentPlayer.IsMay())
			CurrentPlayer.PlaySlotAnimation(bLoop = true, BlendTime = 0.3f, Animation = AnimMH[0]);
		else
			CurrentPlayer.PlaySlotAnimation(bLoop = true, BlendTime = 0.3f, Animation = AnimMH[1]);
	}

	UFUNCTION()
	void OnInteractionCancelled()
	{
		if (CurrentPlayer == nullptr)
			return;

		CurrentPlayer.RemoveCapabilitySheet(PlayerCapabilitySheet);

		FHazeAnimationDelegate ExitBlendingOut;
		ExitBlendingOut.BindUFunction(this, n"FinishedExit");

		if (CurrentPlayer.IsMay())
			CurrentPlayer.PlaySlotAnimation(BlendTime = 0.4f, Animation = AnimEnter[0], OnBlendingOut = ExitBlendingOut);
		else
			CurrentPlayer.PlaySlotAnimation(BlendTime = 0.4f, Animation = AnimEnter[1], OnBlendingOut = ExitBlendingOut);
	}

	UFUNCTION()
	void FinishedExit()
	{
		if (CurrentPlayer == nullptr)
			return;
			
		CurrentPlayer.StopAllSlotAnimations(0.2f);

		InteractionComp.EnableAfterFullSyncPoint(n"Selfie Posing");

		SelfieCam.Camera.DeactivateCamera(CurrentPlayer, 1.5f);
		SelfieCam.TakeImageArea.RemoveSelfieImagePlayer(CurrentPlayer);
		SelfieCam.TakeImageArea.TakeImageSequenceDeactivated(CurrentPlayer);

		CurrentPlayer.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);
		PlayerDiedDelegate.Clear();

		CurrentPlayer = nullptr;
	}

	UFUNCTION(NetFunction)
	void PlayerDied(AHazePlayerCharacter Player)
	{
		OnInteractionCancelled();
		PlayerDiedDelegate.Clear();
	}
}