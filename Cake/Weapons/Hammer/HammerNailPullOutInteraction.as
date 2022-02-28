
import Vino.Interactions.ScriptInteractionBase;
import Vino.Animations.OneShotAnimation;
import Vino.Animations.LockIntoAnimation;
import Vino.Pierceables.PierceStatics;
import Cake.Weapons.Nail.NailWeaponStatics;
import Cake.Weapons.Nail.NailWeaponActor;
import Cake.Weapons.Nail.NailSocketDefinition;
import Cake.Weapons.Hammer.HammerWeaponStatics;
import Cake.Weapons.Hammer.HammerWeaponActor;
import Cake.Weapons.Hammer.HammerSocketDefinition;

event void FPullOutNailEvent(AHazePlayerCharacter Player, AHammerNailPullOutInteraction Interaction);
event void FNailReachedOtherPlayerEvent(AHazePlayerCharacter PlayerCatchingNail, ANailWeaponActor Nail);

/*
		This is a copy of OneShotInteraction which also plays 
		a one shot animation on the nail.

		!!! before you rewrite this: 

		* Don't use a dummy nail mesh. It will not work with the animation oskar has made.
		* the placement can be read from the animation, but automating it isn't necessary. 
			We only have 2 instances of these actors in the game
*/ 

UCLASS(abstract)
class AHammerNailPullOutInteraction : AScriptInteractionBase
{
 	UPROPERTY(Category = "One Shot Animation", meta = (ShowOnlyInnerProperties))
	FHazePlaySlotAnimationParams AnimationNailSuccess;

 	UPROPERTY(Category = "One Shot Animation", meta = (ShowOnlyInnerProperties))
	FOneShotAnimationSettings AnimationPlayerSuccess;

 	UPROPERTY(Category = "One Shot Animation", meta = (ShowOnlyInnerProperties))
	FHazePlaySlotAnimationParams AnimationNailFail;

    UPROPERTY(Category = "One Shot Animation", meta = (ShowOnlyInnerProperties))
	FOneShotAnimationSettings AnimationPlayerFail;

	/* Executed when the interaction first triggers. */
	UPROPERTY(Category = "One Shot Interaction")
	FPullOutNailEvent OnOneShotActivated;

	/* Executed when the one shot animation for this interaction has finished blending in. */
	UPROPERTY(Category = "One Shot Interaction")
	FPullOutNailEvent OnOneShotBlendedIn;

	/* Executed when the one shot animation for this interaction has finished playing and has started blending out. */
	UPROPERTY(Category = "One Shot Interaction")
	FPullOutNailEvent OnOneShotBlendingOut;

	UPROPERTY(Category = "One Shot Interaction")
	FNailReachedOtherPlayerEvent OnCatchingPulledOutNail;

	UPROPERTY(Category = "NOT MISC")
	TSubclassOf<ANailWeaponActor> NailToEquipClass;

	// Place a nail weapon in the level and set the reference here
	UPROPERTY(Category = "NOT MISC")
	ANailWeaponActor NailToPullOut = nullptr;

	// The actor that is currently playing the oneshot
	AHazePlayerCharacter ActivePlayer;

 	UFUNCTION(BlueprintOverride, NotBlueprintCallable)
	void BeginPlay()
	{
		Super::BeginPlay();

		if (NailToPullOut == nullptr)
		{
			PrintError(GetName() + " NaillToPullOut has not been set");
			return;
		}

		/* 	we'll switch to using the ABP in the level BP upon catching the nail
			(yes, I know it's ugly but this will save Oskar a headache)
			@TODO: we can also check if the nail is unequipped and refactor the ABP 
			statemachine to cover this case */
		NailToPullOut.Mesh.SetAnimationMode(EAnimationMode::AnimationSingleNode);

		DisableNail();
	}

    void EndInteraction()
    {
        ActivePlayer.StopAnimation(BlendTime = 0.2f);
		NailToPullOut.StopAnimation(BlendTime = 0.2f);

		// the delegates should set the activePlayer to nullptr when the animation stops
        ensure(ActivePlayer == nullptr);
    }

	/* Override of OnTriggerComponentActivated() from AHazeInteractionActor, called when the player hits a button. */
	UFUNCTION(NotBlueprintCallable, BlueprintOverride)
	void OnTriggerComponentActivated(UHazeTriggerComponent Trigger, AHazePlayerCharacter Player)
	{
        // We could still be in this interaction on this side
        if (ActivePlayer != nullptr)
            EndInteraction();

		if (NailToPullOut == nullptr)
		{
			PrintError("NaillToPullOut has not been set");
			return;
		}

		// We enable it in order to wake up the ABP 
		// (the nail is disabled, but not renderingwise)
		EnableNail();

		AlignPlayerWithAlignBone(Player, AnimationPlayerSuccess.GetAnimationFor(Player));

		// Disable the trigger while the oneshot is actively playing
		TriggerComponent.Disable(n"OneShotPlaying");
		LockIntoAnimation(Player, this);

		// Tell anything bound to us that we've started playing
		ActivePlayer = Player;
		OnOneShotActivated.Broadcast(Player, this);

		// play success animation
		if (HasHammerEquipped(Player))
		{
			FOneShotAnimationEvents Events;
			Events.OnBlendedIn.BindUFunction(this, n"SuccessAnimationBlendedIn");
			Events.OnBlendingOut.BindUFunction(this, n"SuccessAnimationBlendingOut");
			PlayOneShotAnimation(Player, AnimationPlayerSuccess, Events);

			FHazeAnimationDelegate OnBlendingIn_Nail;
			FHazeAnimationDelegate OnBlendingOut_Nail;
			NailToPullOut.Mesh.PlaySlotAnimation(OnBlendingIn_Nail, OnBlendingOut_Nail, AnimationNailSuccess);
		}
		// play fail animation
		else 
		{
			FOneShotAnimationEvents Events;
			Events.OnBlendedIn.BindUFunction(this, n"FailAnimationBlendedIn");
			Events.OnBlendingOut.BindUFunction(this, n"FailAnimationBlendingOut");
			PlayOneShotAnimation(Player, AnimationPlayerFail, Events);

			FHazeAnimationDelegate OnBlendingIn_Nail;
			FHazeAnimationDelegate OnBlendingOut_Nail;
			NailToPullOut.Mesh.PlaySlotAnimation(OnBlendingIn_Nail, OnBlendingOut_Nail, AnimationNailFail);
		}
	}

	UFUNCTION(NotBlueprintCallable)
	void FailAnimationBlendedIn()
	{
		ActivePlayer.BlockCapabilities(n"NailSwing", this);
	}

	UFUNCTION(NotBlueprintCallable)
	void FailAnimationBlendingOut()
	{
		AHazePlayerCharacter PreviousPlayer = ActivePlayer;
		ActivePlayer = nullptr;
		TriggerComponent.Enable(n"OneShotPlaying");
		UnlockFromAnimation(PreviousPlayer, this);
		PreviousPlayer.UnblockCapabilities(n"NailSwing", this);

		DisableNail();
	}

	UFUNCTION(NotBlueprintCallable)
	void SuccessAnimationBlendedIn()
	{
		ActivePlayer.BlockCapabilities(n"NailSwing", this);
		OnOneShotBlendedIn.Broadcast(ActivePlayer, this);
	}

	UFUNCTION(NotBlueprintCallable)
	void SuccessAnimationBlendingOut()
	{
		AHazePlayerCharacter PreviousPlayer = ActivePlayer;

		// Re-enable the trigger with the same tag that we disabled it with
		ActivePlayer = nullptr;
		TriggerComponent.Enable(n"OneShotPlaying");
		UnlockFromAnimation(PreviousPlayer, this);

		// Tell anything bound to us that we've started blending out
		OnOneShotBlendingOut.Broadcast(PreviousPlayer, this);

		DisableInteraction(n"Nail is equipped. Job is done");
		PreviousPlayer.UnblockCapabilities(n"NailSwing", this);

		if(Game::GetCody().HasControl())
		{
			SpawnExtractedNail();
		}

	}

	UFUNCTION(NetFunction)
	void SpawnExtractedNail()
	{
		ANailWeaponActor ExtractedNail = SpawnNailWeapon(Game::GetCody(), NailToEquipClass);

		ExtractedNail.SetActorTransform(NailToPullOut.GetActorTransform());

		// Blueprint will subscribe to this event and play event animations
		OnCatchingPulledOutNail.Broadcast(Game::GetCody(), ExtractedNail);

		DisableNail(false);
	}

	void DisableNail(bool bRenderWhileDisabled = true)
	{
		auto DisableComp = UHazeDisableComponent::GetOrCreate(NailToPullOut);
		DisableComp.bRenderWhileDisabled = bRenderWhileDisabled;
		NailToPullOut.DisableActor(this);
	}

	void EnableNail()
	{
		NailToPullOut.EnableActor(this);
	}

	// Place player at the location the animation wants us to be. 
	void AlignPlayerWithAlignBone(AHazePlayerCharacter InPlayer, UAnimSequence Animation)
	{
		UMeshComponent NailMesh = NailToPullOut.Mesh;
		const FTransform NailMeshWorldTransform = NailMesh.GetWorldTransform();
		const FVector NailMeshWorldLocation = NailMeshWorldTransform.GetLocation();
		const FRotator NailMeshWorldRotation = (-NailMesh.GetUpVector()).ToOrientationRotator();
		FTransform LocalAnimAlignBoneTransform;
		Animation::GetAnimAlignBoneTransform(LocalAnimAlignBoneTransform, Animation);
 		FVector AlignLocation = NailMeshWorldLocation - NailMeshWorldRotation.RotateVector(LocalAnimAlignBoneTransform.GetLocation());
		FRotator AlignRotation = NailMeshWorldRotation;
		InPlayer.SmoothSetLocationAndRotation(AlignLocation, AlignRotation);
// 		InPlayer.MakeCorrectionToActorTransform(AlignLocation, AlignRotation);
	}

};