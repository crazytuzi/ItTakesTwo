import Cake.LevelSpecific.Clockwork.Townsfolk.TownsfolkActor;
import Vino.Interactions.InteractionComponent;
import Vino.Animations.ThreeShotAnimation;
import Vino.Tutorial.TutorialStatics;

class ATownsfolkMountableAnimal : ATownsfolkActor
{
	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;
	default InteractionComp.bUseLazyTriggerShapes = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent PlayerAttachmentPoint;

	UPROPERTY(Category = "Animations", meta = (ShowOnlyInnerProperties))
	FThreeShotAnimationSettings AnimSettings;
	default AnimSettings.BlendTime = 0.f;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayMountedAudioEvent;
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopMountedAudioEvent;

	UPROPERTY()
	float SpeedMultiplier = 5.f;

	AHazePlayerCharacter MountedPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();

		InteractionComp.OnActivated.AddUFunction(this, n"InteractionActivated");
	}

	UFUNCTION(NotBlueprintCallable)
	void InteractionActivated(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		MountedPlayer = Player;
		InteractionComp.Disable(n"Mounted");
		FThreeShotAnimationEvents Events;
		Events.OnMHBlendingOut.BindUFunction(this, n"CancelInteraction");
		FThreeShotAnimationSettings Settings;
		Settings = AnimSettings;
		if (Player.IsMay())
			Settings.BlendTime = 0.3f;
		else
			Settings.BlendTime = 0.2f;
		PlayThreeShotAnimation(Player, Settings, Events);
		MountedPlayer.PlayerHazeAkComp.HazePostEvent(PlayMountedAudioEvent);
		Player.AttachToComponent(PlayerAttachmentPoint);
		
		WalkSpeed *= SpeedMultiplier;

		Player.ShowCancelPrompt(this);
	}

	UFUNCTION(NotBlueprintCallable)
	void CancelInteraction()
	{
		MountedPlayer.DetachFromActor(EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld, EDetachmentRule::KeepWorld);

		InteractionComp.EnableAfterFullSyncPoint(n"Mounted");
		MountedPlayer.PlayerHazeAkComp.HazePostEvent(StopMountedAudioEvent);
		
		WalkSpeed /= SpeedMultiplier;

		MountedPlayer.RemoveCancelPromptByInstigator(this);
		MountedPlayer.SetSlotAnimationPlayRate(AnimSettings.May_EndAnimation, 3.5f);
	}
}