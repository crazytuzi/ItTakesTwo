
delegate void FGrabbedActorDelegate(AHazePlayerCharacter Player, UPrimitiveComponent GrabbedPrimitive);
event void FGrabbedActorEvent(AHazePlayerCharacter PlayerGrabbingActor, UPrimitiveComponent GrabbedPrimitive);

enum ELedgeReleaseType
{
	LetGo,
	JumpOff,
	ClimbUp,
	JumpUp,
}

struct FLedgeGrabEventTempFix
{
	UPROPERTY()
	ELedgeReleaseType ReleaseType;
}

delegate void FReleasedGrabbedActorDelegate(AHazePlayerCharacter PlayerGrabbingActor, UPrimitiveComponent GrabbedPrimitive, FLedgeGrabEventTempFix ReleaseType);
event void FReleasedGrabbedActorEvent(AHazePlayerCharacter PlayerGrabbingActor, UPrimitiveComponent GrabbedPrimitive, FLedgeGrabEventTempFix ReleaseType);

bool ActorHasTagGrabbable(AHazeActor GrabbableActor)
{
	if (GrabbableActor == nullptr)
		return false;

	TArray<UActorComponent> Primitives = GrabbableActor.GetComponentsByTag(UPrimitiveComponent::StaticClass(), ComponentTags::LedgeGrabbable);
	return (Primitives.Num() > 0);
}

UFUNCTION()
void BindOnLedgeGrabbed(AHazeActor GrabbableActor, FGrabbedActorDelegate Delegate)
{
    if(GrabbableActor != nullptr)
    {
        UGrabbedCallbackComponent Comp = UGrabbedCallbackComponent::GetOrCreate(GrabbableActor);
        if(Comp != nullptr)
        {
			if (!devEnsure(ActorHasTagGrabbable(GrabbableActor), "Actor: " + GrabbableActor.Name + " with grabbable events doesn't seem to have the tag grabbable"))
				return;

			Comp.OnActorGrabbed.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UFUNCTION()
void BindOnLeaveLedge(AHazeActor GrabbableActor, FReleasedGrabbedActorDelegate Delegate)
{
    if(GrabbableActor != nullptr)
    {
        UGrabbedCallbackComponent Comp = UGrabbedCallbackComponent::GetOrCreate(GrabbableActor);
        if(Comp != nullptr)
        {
			if (!devEnsure(ActorHasTagGrabbable(GrabbableActor), "Actor: " + GrabbableActor.Name + " with grabbable events doesn't seem to have the tag grabbable"))
				return;

			Comp.OnActorReleased.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UCLASS(HideCategories = " ComponentReplication Activation Cooking Collision")
class UGrabbedCallbackComponent : UActorComponent
{  
	/*
		Default behaviour is that the callback is synced from the Control side of the player that started wallsliding. You can disable this if you want to, but this should be on for gameplay affecting behaviour.
	*/
	UPROPERTY(Category = "WallSliding")
	bool bCanBeActivedLocallyOnTheRemote = false;

	UPROPERTY(Category = "Grab")
	FGrabbedActorEvent OnActorGrabbed;

	UPROPERTY(Category = "Grab")
	FReleasedGrabbedActorEvent OnActorReleased;

	void GrabActor(AHazePlayerCharacter PlayerGrabbingActor, UPrimitiveComponent GrabbedPrimitive)
	{
		OnActorGrabbed.Broadcast(PlayerGrabbingActor, GrabbedPrimitive);
	}

	void LetGoOfActor(AHazePlayerCharacter PlayerReleasingActor, UPrimitiveComponent GrabbedPrimitive, ELedgeReleaseType ReleaseType)
	{
		FLedgeGrabEventTempFix TempFix;
		TempFix.ReleaseType = ReleaseType;

		OnActorReleased.Broadcast(PlayerReleasingActor, GrabbedPrimitive, TempFix);
	}
};
