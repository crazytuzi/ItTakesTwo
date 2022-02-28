import Cake.LevelSpecific.Music.MusicalChairs.MusicalChairsActor;

UCLASS()
class UMusicalChairsPlayerComponent : UActorComponent
{
	UPROPERTY(NotEditable)
	AMusicalChairsActor MusicalChairs; 

	bool bPressedButton = false;

	bool bRequestLocomotion = false;

	UPROPERTY()
	bool bRunning = false;

	UPROPERTY()
	bool bWonRound = false;

	UPROPERTY()
	bool bFailedRound = false;

	UPROPERTY()
	bool bExploded = false;

	UFUNCTION(BlueprintCallable)
	void EndedTransitionFromAnimations()
	{
		MusicalChairs.PlayerFinishedAnimations(Cast<AHazePlayerCharacter>(Owner));
	}
}

void InitMusicalChairsComp(AHazePlayerCharacter Player, AMusicalChairsActor MusicalChairsActor)
{
	auto Comp = UMusicalChairsPlayerComponent::GetOrCreate(Player);
	Comp.MusicalChairs = MusicalChairsActor;
}
