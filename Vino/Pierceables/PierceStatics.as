
import Vino.Pierceables.PierceableComponent;
import Vino.Pierceables.PiercingComponent;

void ForceFinishPiercingWiggle(AActor InActor)
{
	if (InActor == nullptr)
	{
  		PrintError("ForceFinishPiercingWiggle failed because InActor was NULL");
		return;
	}

	UPiercingComponent PiercingComp = GetPiercingComponent(InActor);
	if (PiercingComp == nullptr)
	{
 		PrintError("ForceFinishPiercingWiggle() failed because InActor doesn't have a piercingComponent");
		return;
	}

	PiercingComp.WiggleIntoPierce.ForceFinishWiggle();
}

/* Will detach, push piercing events and enable physics */
UFUNCTION(Category = "PierceStatics")
void UnpierceActors(AActor ActorThatPerformedThePiercing)
{
	if (ActorThatPerformedThePiercing == nullptr)
	{
  		PrintError("UnpierceBothActors() failed because input actor was NULL ");
		return;
	}

	UPiercingComponent PiercingComp = GetPiercingComponent(ActorThatPerformedThePiercing);
	if (PiercingComp == nullptr)
	{
 		PrintError("UnpierceActors() failed because PiercingActor doesn't have a piercingComponent");
		return;
	}

	if (!PiercingComp.IsPierced())
	{
 		// PrintError("UnpierceActors() failed because PiercingActor wasn't pierced to begin with");
		return;
	}

	PiercingComp.WiggleIntoPierce.ForceFinishWiggle();

	AActor PiercedActor = PiercingComp.GetPiercedActors().Last();
	if(PiercedActor != nullptr)
	{
		UPierceableComponent PierceableComp = GetPierceableComponent(PiercedActor);
		if (PierceableComp != nullptr)
		{
			if (!PierceableComp.IsPierced())
			{
				PrintError("UnpierceActors() failed because Pierced actor wasn't pierced");
				return;
			}
			PierceableComp.PushUnpiercingEvent(ActorThatPerformedThePiercing);
		}
	}

	PiercingComp.PushUnpiercingEvent(PiercedActor);

	ActorThatPerformedThePiercing.DetachFromActor
	(
		EDetachmentRule::KeepWorld,
		EDetachmentRule::KeepWorld,
		EDetachmentRule::KeepWorld
	);

	PiercingComp.EnableAndApplyPhysicsSettings();
}

UFUNCTION(BlueprintPure, Category = "PierceStatics")
bool IsMayPiercedBy(AActor Piercer) 
{
	return IsPiercedBy(Game::GetMay(), Piercer);
}

UFUNCTION(BlueprintPure, Category = "PierceStatics")
bool IsPiercedBy(AActor PiercedActor, AActor Piercer) 
{
	UPierceableComponent PierceableComp = GetPierceableComponent(PiercedActor);
	if (PierceableComp == nullptr)
		return false;
	
	return PierceableComp.IsPiercedBy(Piercer);
}


UFUNCTION(BlueprintPure, Category = "PierceStatics")
bool IsPierced(AActor InActor) 
{
	if (InActor == nullptr)
	{
		PrintError("IsPierced() failed because input actors were null");
		return false;
	}

	UPierceableComponent PierceableComp = GetPierceableComponent(InActor);
	if (PierceableComp != nullptr)
		return PierceableComp.IsPierced();

	UPiercingComponent PiercingComp = GetPiercingComponent(InActor);
	if (PiercingComp != nullptr)
		return PiercingComp.IsPierced();

	return false;
}

UFUNCTION(BlueprintPure, Category = "PierceStatics")
UPierceableComponent GetPierceableComponent(AActor InActor)
{
	if (InActor == nullptr)
		return nullptr;

	return Cast<UPierceableComponent>(InActor.GetComponentByClass(UPierceableComponent::StaticClass()));
}

UFUNCTION(BlueprintPure, Category = "PierceStatics")
UPiercingComponent GetPiercingComponent(AActor InActor)
{
	if (InActor == nullptr)
		return nullptr;

	return Cast<UPiercingComponent>(InActor.GetComponentByClass(UPiercingComponent::StaticClass()));
}

UFUNCTION(Category = "PierceStatics")
bool IsActorPierceable(AActor InActor) 
{
	if (InActor == nullptr)
		return false;

	TArray<UPrimitiveComponent> Prims;
	InActor.GetComponentsByClass(Prims);
	for (auto Prim : Prims)
	{ 
		if (Prim.HasTag(ComponentTags::Piercable))
			return true;
	}
	return false;
}

UFUNCTION(Category = "PierceStatics")
bool IsComponentPierceable(UPrimitiveComponent InPrimitiveComponent)
{
	return InPrimitiveComponent.HasTag(ComponentTags::Piercable);
}


