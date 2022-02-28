import Vino.Interactions.InteractionComponent;
import Peanuts.Spline.SplineComponent;
import Cake.LevelSpecific.PlayRoom.VOBanks.CastleCourtyardVOBank;
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.StuckCharacter.CourtyardStuckCharacterLocation;

event void FOnStuckCharacterButtonMashComplete(AHazePlayerCharacter Player);
event void FOnStuckCharacterPlayerCancelled(AHazePlayerCharacter Player);

class ACourtyardStuckCharacterInteraction : AHazeActor
{
	UPROPERTY(DefaultComponent)
	USceneComponent Root;
	default Root.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent, Attach = Root)
	UInteractionComponent InteractionComp;
	default InteractionComp.bStartDisabled = true;
	default InteractionComp.StartDisabledReason = n"Empty";
	
	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayMayPullEffortAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopMayPullEffortAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayCodyPullEffortAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopCodyPullEffortAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayStruggleAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopStruggleAudioEvent;

	UPROPERTY()
	ACourtyardStuckCharacterInteraction TargetInteraction;

	UPROPERTY()
	ACourtyardStuckCharacterLocation CharacterLocation;

	UPROPERTY()
	TSubclassOf<UHazeCapability> PlayerCapability;
	
	UPROPERTY(Category = Animations)
	FStuckCharacterAnimations CharacterAnimations;

	UPROPERTY(Category = Animations)
	TPerPlayer<FStuckCharacterPlayerAnimations> PlayerAnimations;	

	UPROPERTY()
	FOnStuckCharacterButtonMashComplete OnStuckCharacterButtonMashComplete;
	UPROPERTY()
	FOnStuckCharacterPlayerCancelled OnStuckCharacterPlayerCancelled;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"OnInteractionActivated");

		if (PlayerCapability.IsValid())
			Capability::AddPlayerCapabilityRequest(PlayerCapability);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		if (PlayerCapability.IsValid())
			Capability::RemovePlayerCapabilityRequest(PlayerCapability);
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnInteractionActivated(UInteractionComponent UsedInteraction, AHazePlayerCharacter Player)
	{
		Player.SetCapabilityAttributeObject(n"StuckCharacterInteraction", this);
		UsedInteraction.Disable(n"InUse");
		
		if (Player.IsMay())
		{
			Player.PlayerHazeAkComp.HazePostEvent(PlayMayPullEffortAudioEvent);
			Player.PlayerHazeAkComp.HazePostEvent(PlayStruggleAudioEvent);
		}
		else
		{
			Player.PlayerHazeAkComp.HazePostEvent(PlayCodyPullEffortAudioEvent);
			Player.PlayerHazeAkComp.HazePostEvent(PlayStruggleAudioEvent);
		}
	}

	void CancelInteraction(AHazePlayerCharacter Player)
	{
		InteractionComp.Enable(n"InUse");
		
		if (Player.IsMay())
		{
			Player.PlayerHazeAkComp.HazePostEvent(StopMayPullEffortAudioEvent);
			Player.PlayerHazeAkComp.HazePostEvent(StopStruggleAudioEvent);
		}
		else
		{
			Player.PlayerHazeAkComp.HazePostEvent(StopCodyPullEffortAudioEvent);
			Player.PlayerHazeAkComp.HazePostEvent(StopStruggleAudioEvent);
		}
		
		OnStuckCharacterPlayerCancelled.Broadcast(Player);
	}

	void CompletedInteraction(AHazePlayerCharacter Player)
	{
		InteractionComp.Disable(n"Empty");
		InteractionComp.Enable(n"InUse");

		CharacterLocation.CharacterLandedNiagaraComp.Activate();
		
		if (Player.IsMay())
		{
			Player.PlayerHazeAkComp.HazePostEvent(StopMayPullEffortAudioEvent);
			Player.PlayerHazeAkComp.HazePostEvent(StopStruggleAudioEvent);
		}
		else
		{
			Player.PlayerHazeAkComp.HazePostEvent(StopCodyPullEffortAudioEvent);
			Player.PlayerHazeAkComp.HazePostEvent(StopStruggleAudioEvent);
		}
		
		OnStuckCharacterButtonMashComplete.Broadcast(Player);
	}
}

struct FStuckCharacterPlayerAnimations
{
	UPROPERTY()
	UAnimSequence Enter;

	UPROPERTY()
	UAnimSequence MH;

	UPROPERTY()
	UAnimSequence Cancel;

	UPROPERTY()
	UAnimSequence Throw;
}

struct FStuckCharacterAnimations
{
	UPROPERTY()
	UAnimSequence MH;

	UPROPERTY()
	UAnimSequence Struggle;

	UPROPERTY()
	UAnimSequence Release;
}