import Cake.LevelSpecific.SnowGlobe.Swimming.AI.AnglerFish.Volumes.FishHidingPlaceSpline;

class UUnderwaterHidingComponent : UActorComponent
{
	bool bIsHiding;
	bool bExitDone;

	AFishHidingPlaceSpline ActiveHidingPlace;
	AFishHidingPlaceSpline LastHidingPlace;

	FVector HidingLocation;

	TArray<AFishHidingPlaceSpline> AvailableHidingPlaces;
}

void AddHidingPlace(AActor Owner, AFishHidingPlaceSpline HidingPlace)
{
	auto HidingComp = UUnderwaterHidingComponent::Get(Owner);
	if (HidingComp == nullptr)
		return;
		HidingComp.AvailableHidingPlaces.AddUnique(HidingPlace);
}

void RemoveHidingPlace(AActor Owner, AFishHidingPlaceSpline HidingPlace)
{
	auto HidingComp = UUnderwaterHidingComponent::Get(Owner);
	if (HidingComp == nullptr)
		return;
		HidingComp.AvailableHidingPlaces.Remove(HidingPlace);
}
