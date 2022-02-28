import Vino.Interactions.ThreeShotInteraction;

class AThreeShotInteractionJumpTo : AThreeShotInteraction
{
	AHazePlayerCharacter CurrentPlayer;
	
	UPROPERTY()
	float AdditionalHeight = 165;

  	void StartAnimation(AHazePlayerCharacter Player) override
	{
		FHazeJumpToData JumpData;
		JumpData.AdditionalHeight = AdditionalHeight;
		JumpData.Transform = this.GetActorTransform();
		FHazeDestinationEvents OnFinished;
		OnFinished.OnDestinationReached.BindUFunction(this, n"StartAnimationSuper");
		CurrentPlayer = Player;
		JumpTo::ActivateJumpTo(Player, JumpData, OnFinished);
  	}

   	void LockPlayerIntoAnimation(AHazePlayerCharacter Player) override{}

	UFUNCTION()
	void StartAnimationSuper(AHazeActor Actor)
	{
		Super::LockPlayerIntoAnimation(CurrentPlayer);
		Super::StartAnimation(CurrentPlayer);
	}
};