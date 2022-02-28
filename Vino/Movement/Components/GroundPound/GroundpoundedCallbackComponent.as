event void FGroundPoundedActorEvent(AHazePlayerCharacter PlayerGroundPoundingActor);
delegate bool FGroundPoundCallbackCanBeTriggeredEval(AHazePlayerCharacter EnteringPlayer, UPrimitiveComponent Floor)const;

delegate void FActorGroundPoundedDelegate(AHazePlayerCharacter Player);

UFUNCTION()
void BindOnActorGroundPounded(AActor Actor, FActorGroundPoundedDelegate Delegate)
{
    UGroundPoundedCallbackComponent GroundPoundComp = UGroundPoundedCallbackComponent::GetOrCreate(Actor);
    if (GroundPoundComp != nullptr)
    {
        GroundPoundComp.OnActorGroundPounded.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
    }
}

UCLASS(HideCategories = " ComponentReplication Activation Cooking Collision")
class UGroundPoundedCallbackComponent : UActorComponent
{  
	UPROPERTY(Category = "Ground Pound")
	FGroundPoundedActorEvent OnActorGroundPounded;

	UPROPERTY(Category = "Ground Pound")
	FGroundPoundCallbackCanBeTriggeredEval Evaluate;

	bool CanTriggerEvent(AHazePlayerCharacter FromPlayer, UPrimitiveComponent Floor) const
	{
		if(!Evaluate.IsBound())
			return true;

		return Evaluate.Execute(FromPlayer, Floor);
	}
};
