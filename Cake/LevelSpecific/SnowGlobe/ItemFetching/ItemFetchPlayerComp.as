// enum EDistanceDropOffState
// {
// 	OutOfRange,
// 	InRange
// };

class UItemFetchPlayerComp : UActorComponent
{
	bool bInRange;

	bool bCanDropOff;

	bool bHoldingItem;

	UObject DropOffPoint;

	UObject ItemPickUp;
	
	// EDistanceDropOffState DistanceState;
}