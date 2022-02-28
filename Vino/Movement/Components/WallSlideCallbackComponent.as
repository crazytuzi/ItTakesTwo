delegate void FPlayerStartedWallSlidingOnActorDelegate(AHazePlayerCharacter WallSlidingPlayer, UPrimitiveComponent PrimitiveSlidingOn);
event void FPlayerStartedWallSlidingOnActorEvent(AHazePlayerCharacter WallSlidingPlayer, UPrimitiveComponent PrimitiveSlidingOn);

delegate void FPlayerStoppedWallSlidingOnActorDelegate(AHazePlayerCharacter WallSlidingPlayer, UPrimitiveComponent PrimitiveStoppedSlidingOn, bool bJumpedOff);
event void FPlayerStoppedWallSlidingOnActorEvent(AHazePlayerCharacter WallSlidingPlayer, UPrimitiveComponent PrimitiveStoppedSlidingOn, bool bJumpedOff);

UFUNCTION()
void BindOnStartedWallSliding(AHazeActor ActorToBindTo, FPlayerStartedWallSlidingOnActorDelegate Delegate)
{
	if (!ensure(ActorToBindTo != nullptr))
		return;

	UPlayerWallSlidingOnCallbackComponent CallbackComp = UPlayerWallSlidingOnCallbackComponent::GetOrCreate(ActorToBindTo);
	if (!ensure(CallbackComp != nullptr))
		return;

	CallbackComp.OnStartedWallSlidingOn.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
}

UFUNCTION()
void BindOnStopeddWallSliding(AHazeActor ActorToBindTo, FPlayerStoppedWallSlidingOnActorDelegate Delegate)
{
	if (!ensure(ActorToBindTo != nullptr))
		return;

	UPlayerWallSlidingOnCallbackComponent CallbackComp = UPlayerWallSlidingOnCallbackComponent::GetOrCreate(ActorToBindTo);
	if (!ensure(CallbackComp != nullptr))
		return;

	CallbackComp.OnStoppedWallSlidingOn.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
}

UCLASS(HideCategories = " ComponentReplication Activation Cooking Collision")
class UPlayerWallSlidingOnCallbackComponent : UActorComponent
{
	/*
		Default behaviour is that the callback is synced from the Control side of the player that started wallsliding. You can disable this if you want to, but this should be on for gameplay affecting behaviour.
	*/
	UPROPERTY(Category = "WallSliding")
	bool bCanBeActivedLocallyOnTheRemote = false;

	UPROPERTY(Category = "WallSliding")
	FPlayerStartedWallSlidingOnActorEvent OnStartedWallSlidingOn;

	UPROPERTY(Category = "WallSliding")
	FPlayerStoppedWallSlidingOnActorEvent OnStoppedWallSlidingOn;


	UFUNCTION(NetFunction)
	void NetStartedWallSlidingOnActor(AHazePlayerCharacter HazePlayer, UPrimitiveComponent WallSlidingOn)
	{
		OnStartedWallSlidingOn.Broadcast(HazePlayer, WallSlidingOn);
	}

	UFUNCTION(NetFunction)
	void NetStoppedWallSlidingOnActor(AHazePlayerCharacter HazePlayer, UPrimitiveComponent WallSlidingOn, bool bJumpedOff)
	{
		OnStoppedWallSlidingOn.Broadcast(HazePlayer, WallSlidingOn, bJumpedOff);
	}

	void PlayerStartedSlidingOnActor(AHazePlayerCharacter HazePlayer, UPrimitiveComponent WallSlidingOn)
	{
		if (bCanBeActivedLocallyOnTheRemote)
		{
			OnStartedWallSlidingOn.Broadcast(HazePlayer, WallSlidingOn);
		}
		else
		{
			if (HazePlayer.HasControl())
				NetStartedWallSlidingOnActor(HazePlayer, WallSlidingOn);
		}
	}

	void PlayerStoppedSlidingOnActor(AHazePlayerCharacter HazePlayer, UPrimitiveComponent WallLeaving, bool bJumpedOff)
	{
		if (bCanBeActivedLocallyOnTheRemote)
		{
			OnStoppedWallSlidingOn.Broadcast(HazePlayer, WallLeaving, bJumpedOff);
		}
		else
		{
			if (HazePlayer.HasControl())
				NetStoppedWallSlidingOnActor(HazePlayer, WallLeaving, bJumpedOff);
		}
	}

};
