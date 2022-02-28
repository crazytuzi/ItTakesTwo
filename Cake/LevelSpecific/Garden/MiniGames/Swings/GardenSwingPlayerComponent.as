import Cake.LevelSpecific.Garden.MiniGames.Swings.GardenSwingsActor;

UCLASS()
class UGardenSwingPlayerComponent : UActorComponent
{
	UPROPERTY(NotEditable)
	AGardenSwingsActor Swings;
	UPROPERTY(NotEditable)
	UGardenSingleSwingComponent CurrentSwing;

	UPROPERTY(NotEditable)
	FVector2D RawInput;
	bool bInAir = false;
	bool bAwaitingScore = false;

	UPROPERTY(NotEditable)
	bool bFailed = false;
	UPROPERTY(NotEditable)
	bool bInFailedRange = false;
	
	ULocomotionFeatureSwingingMinigame AnimFeature;

	bool bPlayerFinishedAnimations;
	
	UFUNCTION(BlueprintCallable)
	void EndedTransitionFromAnimations()
	{
		bPlayerFinishedAnimations = true;
		// Swings.PlayerFinishedAnimations(Cast<AHazePlayerCharacter>(Owner));
	}
}

void InitGardenSwinging(AHazePlayerCharacter Player, AGardenSwingsActor Swings, UGardenSingleSwingComponent PlayerSwing, ULocomotionFeatureSwingingMinigame AnimationFeature)
{
	auto Comp = UGardenSwingPlayerComponent::GetOrCreate(Player);
	Comp.Swings = Swings;
	Comp.AnimFeature = AnimationFeature;
	Comp.CurrentSwing = PlayerSwing;
}


// UGardenSwingPlayerComponent GetGardenSwingingComponent(AGardenSwingsActor Swing)
// {
// 	if (Swing.CurrentPlayer == nullptr)
// 		return nullptr;
// 	return UGardenSwingPlayerComponent::GetOrCreate(Swing.CurrentPlayer);
// }
