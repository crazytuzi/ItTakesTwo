event void FJumpedFromActorEvent(AHazePlayerCharacter PlayerJumping, UPrimitiveComponent Primitive);
delegate void FActorJumpedFromDelegate(AHazePlayerCharacter Player, UPrimitiveComponent Primitive);

UFUNCTION()
void BindOnActorJumpedFrom(AHazeActor Actor, FActorJumpedFromDelegate Delegate)
{
    UFloorJumpCallbackComponent FloorJumpComp = UFloorJumpCallbackComponent::GetOrCreate(Actor);
    if (FloorJumpComp != nullptr)
    {
        FloorJumpComp.OnActorJumpedFrom.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
    }
}

UCLASS(HideCategories = " ComponentReplication Activation Cooking Collision")
class UFloorJumpCallbackComponent : UActorComponent
{  
	UPROPERTY()
	FJumpedFromActorEvent OnActorJumpedFrom;

	void JumpFromActor(AHazePlayerCharacter& PlayerJumping, UPrimitiveComponent Primitive)
	{
		if (PlayerJumping.HasControl())
			NetBroadcast(PlayerJumping, Primitive);
	}
	
	UFUNCTION(NetFunction)
	void NetBroadcast(AHazePlayerCharacter Player, UPrimitiveComponent Primitive)
	{
		OnActorJumpedFrom.Broadcast(Player, Primitive);
	}
};