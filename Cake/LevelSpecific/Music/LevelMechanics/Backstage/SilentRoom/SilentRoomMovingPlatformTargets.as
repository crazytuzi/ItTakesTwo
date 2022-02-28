class ASilentRoomMovingPlatformTarget : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	int MoveOrder = 1;
}