import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.Train.CourtyardTrainCarriage;
import Vino.Interactions.InteractionComponent;
import Vino.Camera.Components.CameraMatchDirectionComponent;
import Vino.Camera.Components.CameraSpringArmComponent;
import Vino.Tutorial.TutorialStatics;
import Peanuts.Animation.Features.PlayRoom.LocomotionFeatureTrainRide;

class ACourtyardTrainCarriageRidable : ACourtyardTrainCarriage
{
	UPROPERTY(DefaultComponent, Attach = Mesh)
	UInteractionComponent InteractionComp;
	default InteractionComp.bUseLazyTriggerShapes = true;

	UPROPERTY(DefaultComponent, Attach = Mesh)
	UCameraMatchDirectionComponent MatchDirectionComponent;

	UPROPERTY()
	TPerPlayer<ULocomotionFeatureTrainRide> PlayerFeatures;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InteractionComp.OnActivated.AddUFunction(this, n"OnInteractionActivated");
	}

	UFUNCTION(NotBlueprintCallable)
	private void OnInteractionActivated(UInteractionComponent UsedInteraction, AHazePlayerCharacter Player)
	{
		Player.SetCapabilityAttributeObject(n"Carriage", this);
		Player.SetCapabilityAttributeObject(n"TrainInteraction", UsedInteraction);

		UsedInteraction.Disable(n"InUse");

		Online::UnlockAchievement(Player, n"RideTrain");		
		OnCarriageRidden.Broadcast(Player);
	}

	void CancelCarriageInteraction(AHazePlayerCharacter Player, UInteractionComponent UsedInteraction)
	{
		UsedInteraction.EnableAfterFullSyncPoint(n"InUse");
	}
}