import Vino.Movement.Components.ImpactCallback.ActorImpactedCallbackComponent;

UFUNCTION()
void BindOnUpImpactedByPlayer(AHazeActor ImpactedActor, FActorImpactedByPlayerDelegate Delegate)
{
    if(ImpactedActor != nullptr)
    {		
		UActorImpactedCallbackComponent Comp = UActorImpactedCallbackComponent::GetOrCreate(ImpactedActor);
        if(Comp != nullptr)
        {
			Comp.OnActorUpImpactedByPlayer.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UFUNCTION()
void BindOnForwardImpactedByPlayer(AHazeActor ImpactedActor, FActorImpactedByPlayerDelegate Delegate)
{
    if(ImpactedActor != nullptr)
    {
        UActorImpactedCallbackComponent Comp = UActorImpactedCallbackComponent::GetOrCreate(ImpactedActor);
        if(Comp != nullptr)
        {
			Comp.OnActorForwardImpactedByPlayer.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UFUNCTION()
void BindOnDownImpactedByPlayer(AHazeActor ImpactedActor, FActorImpactedByPlayerDelegate Delegate)
{
    if(ImpactedActor != nullptr)
    {
        UActorImpactedCallbackComponent Comp = UActorImpactedCallbackComponent::GetOrCreate(ImpactedActor);
        if(Comp != nullptr)
        {
			Comp.OnActorDownImpactedByPlayer.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UFUNCTION()
void BindOnUpImpactEndedByPlayer(AHazeActor ImpactedActor, FActorNoLongerImpactingByPlayerDelegate Delegate)
{
    if(ImpactedActor != nullptr)
    {		
		UActorImpactedCallbackComponent Comp = UActorImpactedCallbackComponent::GetOrCreate(ImpactedActor);
        if(Comp != nullptr)
        {
			Comp.OnUpImpactEndingPlayer.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UFUNCTION()
void BindOnForwardImpactEndedByPlayer(AHazeActor ImpactedActor, FActorNoLongerImpactingByPlayerDelegate Delegate)
{
    if(ImpactedActor != nullptr)
    {		
		UActorImpactedCallbackComponent Comp = UActorImpactedCallbackComponent::GetOrCreate(ImpactedActor);
        if(Comp != nullptr)
        {
			Comp.OnForwardImpactEndingPlayer.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UFUNCTION()
void BindOnDownImpactEndedByPlayer(AHazeActor ImpactedActor, FActorNoLongerImpactingByPlayerDelegate Delegate)
{
    if(ImpactedActor != nullptr)
    {		
		UActorImpactedCallbackComponent Comp = UActorImpactedCallbackComponent::GetOrCreate(ImpactedActor);
        if(Comp != nullptr)
        {
			Comp.OnDownImpactEndingPlayer.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UFUNCTION()
void BindOnUpImpacted(AHazeActor ImpactedActor, FActorImpactedDelegate Delegate)
{
    if(ImpactedActor != nullptr)
    {		
		UActorImpactedCallbackComponent Comp = UActorImpactedCallbackComponent::GetOrCreate(ImpactedActor);
        if(Comp != nullptr)
        {
			Comp.OnActorUpImpacted.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UFUNCTION()
void BindOnForwardImpacted(AHazeActor ImpactedActor, FActorImpactedDelegate Delegate)
{
    if(ImpactedActor != nullptr)
    {
        UActorImpactedCallbackComponent Comp = UActorImpactedCallbackComponent::GetOrCreate(ImpactedActor);
        if(Comp != nullptr)
        {
			Comp.OnActorForwardImpacted.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UFUNCTION()
void BindOnDownImpacted(AHazeActor ImpactedActor, FActorImpactedDelegate Delegate)
{
    if(ImpactedActor != nullptr)
    {
        UActorImpactedCallbackComponent Comp = UActorImpactedCallbackComponent::GetOrCreate(ImpactedActor);
        if(Comp != nullptr)
        {
			Comp.OnActorDownImpacted.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UFUNCTION()
void BindOnUpImpactEnded(AHazeActor ImpactedActor, FActorNoLongerImpactingDelegate Delegate)
{
    if(ImpactedActor != nullptr)
    {		
		UActorImpactedCallbackComponent Comp = UActorImpactedCallbackComponent::GetOrCreate(ImpactedActor);
        if(Comp != nullptr)
        {
			Comp.OnUpImpactEnding.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UFUNCTION()
void BindOnForwardImpactEnded(AHazeActor ImpactedActor, FActorNoLongerImpactingDelegate Delegate)
{
    if(ImpactedActor != nullptr)
    {
        UActorImpactedCallbackComponent Comp = UActorImpactedCallbackComponent::GetOrCreate(ImpactedActor);
        if(Comp != nullptr)
        {
			Comp.OnForwardImpactEnding.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}

UFUNCTION()
void BindOnDownImpactEnded(AHazeActor ImpactedActor, FActorNoLongerImpactingDelegate Delegate)
{
    if(ImpactedActor != nullptr)
    {
        UActorImpactedCallbackComponent Comp = UActorImpactedCallbackComponent::GetOrCreate(ImpactedActor);
        if(Comp != nullptr)
        {
			Comp.OnDownImpactEnding.AddUFunction(Delegate.GetUObject(), Delegate.GetFunctionName());
        }
    }
}