
import Vino.Combustible.CombustibleComponent;

UFUNCTION(Category = "CombustionStatics")
bool IsActorCombustible(AActor InActor) 
{
	if (InActor == nullptr)
		return false;

	return UCombustibleComponent::Get(InActor) != nullptr;
// 	TArray<UPrimitiveComponent> Prims;
// 	UPrimitiveComponent::GetAll(InActor, Prims);
// 	for (auto Prim : Prims)
// 	{ 
// 		if (Prim.HasTag(ComponentTags::Piercable))
// 			return true;
// 	}
// 	return false;
}

UFUNCTION(Category = "CombustionStatics")
bool IsComponentCombustible(UPrimitiveComponent InPrimitiveComponent)
{
	if (InPrimitiveComponent.GetOwner() == nullptr)
		return false;

	return UCombustibleComponent::Get(InPrimitiveComponent.GetOwner()) != nullptr;
// 	return InPrimitiveComponent.HasTag(ComponentTags::Piercable);
}
