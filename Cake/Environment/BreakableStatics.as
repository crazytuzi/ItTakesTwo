import Cake.Environment.BreakableComponent;
import Cake.Environment.Breakable;

// Regular Hit
UFUNCTION()
bool HitBreakableActor(AHazeActor Actor, FBreakableHitData HitData)
{
	auto BreakableComponent = UBreakableComponent::Get(Actor);
	if(BreakableComponent != nullptr)
	{
		BreakableComponent.Hit(HitData);
		return true;
	}
	return false;
}

// Break Immedietly
UFUNCTION()
bool BreakBreakableActorWithDefault(AHazeActor Actor)
{
	FBreakableHitData HitData = FBreakableHitData();
	HitData.DirectionalForce = FVector::ZeroVector;
	HitData.HitLocation = FVector::ZeroVector;
	HitData.ScatterForce = 0.0f;
	return BreakBreakableActor(Actor, HitData);
}

UFUNCTION()
bool BreakBreakableActor(AHazeActor Actor, FBreakableHitData HitData)
{
	auto BreakableComponent = UBreakableComponent::Get(Actor);
	if(BreakableComponent == nullptr)
		return false;

	FBreakableHitData NewHitData;

	bool UseDefault = false;
	if(HitData.HitLocation == FVector::ZeroVector && HitData.DirectionalForce == FVector::ZeroVector && HitData.ScatterForce == 0.0f)
	{
		UseDefault = true;
	}

	NewHitData.DirectionalForce = HitData.DirectionalForce;
	NewHitData.HitLocation = HitData.HitLocation;
	NewHitData.ScatterForce = HitData.ScatterForce;
	NewHitData.NumberOfHits = HitData.NumberOfHits;
	if(UseDefault)
	{
		NewHitData.DirectionalForce = BreakableComponent.DefaultDirectionalForce;
		NewHitData.HitLocation = BreakableComponent.DefaultHitLocation;
		NewHitData.ScatterForce = BreakableComponent.DefaultScatterForce;
		NewHitData.NumberOfHits = 1;
		NewHitData.HitLocation = Actor.GetActorTransform().TransformPosition(NewHitData.HitLocation);
	}

	BreakableComponent.Break(NewHitData);
	return true;
}

// Check an array of haze actors and return all of the breakable components found
UFUNCTION(BlueprintPure)
TArray<ABreakableActor> GetBreakableActorsFromArray(TArray<AHazeActor> HazeActors)
{
	TArray<ABreakableActor> ValidBreakables;

	for (AHazeActor Actor : HazeActors)
    {
		ABreakableActor Breakable = Cast<ABreakableActor>(Actor);
       
        if (Breakable == nullptr)
            continue;

        ValidBreakables.AddUnique(Breakable);                
    }

	return ValidBreakables;
}

// Check an array of haze actors and return all of the breakable components found
UFUNCTION(BlueprintPure)
TArray<UBreakableComponent> GetBreakableComponentsFromArray(TArray<AHazeActor> HazeActors)
{
	TArray<UBreakableComponent> ValidBreakables;

	for (AHazeActor Actor : HazeActors)
    {
		UBreakableComponent BreakableComponent = UBreakableComponent::Get(Actor);
       
        if (BreakableComponent == nullptr)
            continue;

        ValidBreakables.AddUnique(BreakableComponent);                
    }

	return ValidBreakables;
}
