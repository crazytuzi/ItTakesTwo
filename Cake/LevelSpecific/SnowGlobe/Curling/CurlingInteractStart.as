import Vino.Interactions.InteractionComponent;
import Cake.LevelSpecific.SnowGlobe.Curling.StaticsCurling;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingDoor;
import Cake.LevelSpecific.SnowGlobe.Magnetic.Magnets.MagnetGenericComponent;
import Vino.Animations.ThreeShotAnimation;
import Cake.LevelSpecific.Clockwork.LeaveCloneMechanic.TeleportableThreeShotInteraction;
import Vino.Animations.OneShotAnimation;
import Cake.LevelSpecific.SnowGlobe.Curling.CurlingPlayerInteractComponent;

//Create event for binding to activation events on APresentationActorWithHazeMovementComponent
event void FOnMagnetFinishedMovement(ACurlingInteractStart InteractStart, FVector Location, AHazePlayerCharacter Player);

event void FOnLeverPulled(ACurlingInteractStart InteractStart, AHazePlayerCharacter Player);

event void FOnLeverReleased(AHazePlayerCharacter Player);

class ACurlingInteractStart : AHazeActor
{
	UPROPERTY(Category = "Setup")
	ECurlingPlayerTarget PlayerTarget;

	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;
	
	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeSkeletalMeshComponentBase LeverAnimActor;

	UPROPERTY(DefaultComponent, Attach = LeverAnimActor)
	UStaticMeshComponent LeverMesh;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LeverBaseMeshSide1;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent LeverBaseMeshSide2;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent ShuffleAkComp;

	UPROPERTY(Category = "Lever Animations")
	UAnimSequence LeverStart;
	UPROPERTY(Category = "Lever Animations")
	UAnimSequence LeverMH;
	UPROPERTY(Category = "Lever Animations")
	UAnimSequence LeverEnd;
	
	UPROPERTY(Category = "Audio")
	UAkAudioEvent LeverEnterAudioEvent;

	UPROPERTY(Category = "Audio")
	UAkAudioEvent LeverExitAudioEvent;

	UPROPERTY(Category = "Setup")
	AHazeActor TubeLookAt;

	UPROPERTY(Category = "Setup")
	AHazeActor DoorLookAt;

	UPROPERTY(Category = "Setup")
	UMaterialInstance MatRed;

	UPROPERTY(Category = "Setup")
	UMaterialInstance MatBlue;

	UPROPERTY(Category = "Setup")
	UHazeCapabilitySheet PlayerInteractSheet;

	FOnLeverPulled OnLeverPulled;

	FOnLeverReleased OnLeverReleased; 

	float MaxPitchValue = 75.f;

	FHazeConstrainedPhysicsValue PhysicsValue;

	UCurlingPlayerInteractComponent PlayerInteractComp;

	bool bCancelBlocked;

	void PlayStartLeverAnim()
	{
		FHazeAnimationDelegate OnLeverBlendingIn;
		FHazeAnimationDelegate OnLeverBlendingOut;

		FHazePlaySlotAnimationParams Params;
		Params.Animation = LeverStart;
		LeverAnimActor.PlaySlotAnimation(OnLeverBlendingIn, OnLeverBlendingOut, Params);
	}

	UFUNCTION()
	void PlayMHLeverAnim()
	{
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;

		FHazePlaySlotAnimationParams Params;
		Params.Animation = LeverMH;
		LeverAnimActor.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, Params);
	}

	void PlayExitLeverAnim()
	{
		FHazeAnimationDelegate OnBlendingIn;
		FHazeAnimationDelegate OnBlendingOut;

		FHazePlaySlotAnimationParams Params;
		Params.Animation = LeverEnd;
		LeverAnimActor.PlaySlotAnimation(OnBlendingIn, OnBlendingOut, Params);
	}

	UFUNCTION()
	void SetTutorialState()
	{
		PlayerInteractComp.InteractionState = EInteractionState::Tutorial;
	}

	void AudioLeverAction(AHazePlayerCharacter Player)
	{
		Player.PlayerHazeAkComp.HazePostEvent(LeverEnterAudioEvent);
	}

	void AudioLeverCancelAction(AHazePlayerCharacter Player)
	{
		Player.PlayerHazeAkComp.HazePostEvent(LeverExitAudioEvent);
	}
}