
import Cake.LevelSpecific.Music.LevelMechanics.Classic.SideContent.PopupBook.InteractiveBookPawn;
import Vino.Interactions.InteractionComponent;


import void SetInteractiveBookManager(AInteractiveBookManager Manager, UInteractionComponent Interaction, AHazePlayerCharacter Player) from "Cake.LevelSpecific.Music.LevelMechanics.Classic.SideContent.PopupBook.InteractiveBookPlayer";

class AInteractiveBookManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;
	default RootComp.bVisualizeComponent = true;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent LeftInteraction;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent LeftMoveAmount;
	
	UPROPERTY()
	TArray<AInteractiveBookPawn> LeftPawns;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UInteractionComponent RightInteraction;

	UPROPERTY(DefaultComponent)
	UHazeSmoothSyncFloatComponent RightMoveAmount;

	UPROPERTY()
	TArray<AInteractiveBookPawn> RightPawns;

	UPROPERTY()
	UHazeCapabilitySheet InteractionSheet;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent PlayMovementAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent StopMovementAudioEvent;

	//UPROPERTY(Category = "Audio Events")
	//UAkAudioEvent SweetenerAudioEvent;

	UFUNCTION(BlueprintOverride)
    void ConstructionScript()
	{
		LeftInteraction.OnActivated.AddUFunction(this, n"OnInteractionEntered");
		RightInteraction.OnActivated.AddUFunction(this, n"OnInteractionEntered");
	}

	UInteractionComponent GetOtherInteraction(UInteractionComponent Comp)
	{
		if (Comp == LeftInteraction)
			return RightInteraction;
		else
			return LeftInteraction;
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnInteractionEntered(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		Comp.Disable(n"Entered");

		// Need to disable the other interaction too so we can sync point enable it later to prevent actor channel desync
		// when spamming back and forth between one and the other.
		GetOtherInteraction(Comp).DisableForPlayer(Player, n"EnteredOtherInteraction");

		Player.AddCapabilitySheet(InteractionSheet, EHazeCapabilitySheetPriority::Interaction, this);
		SetInteractiveBookManager(this, Comp, Player);
	}

	void OnInteractionLeft(UInteractionComponent Comp, AHazePlayerCharacter Player)
	{
		Comp.EnableAfterFullSyncPoint(n"Entered");
		GetOtherInteraction(Comp).EnableForPlayerAfterFullSyncPoint(Player, n"EnteredOtherInteraction");

		SetInteractiveBookManager(nullptr, nullptr, Player);		
		Player.RemoveCapabilitySheet(InteractionSheet, this);
	}
}