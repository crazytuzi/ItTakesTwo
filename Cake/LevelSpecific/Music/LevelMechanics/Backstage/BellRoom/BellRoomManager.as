import Cake.LevelSpecific.Music.LevelMechanics.Backstage.BellRoom.BellRoomBell;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.BellRoom.BellRoomPlatform;
class ABellRoomManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	TArray<ABellRoomBell> BellArray;
	TArray<ABellRoomPlatform> BellRoomPlatformArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		GetAllActorsOfClass(BellArray);
		GetAllActorsOfClass(BellRoomPlatformArray);

		for (ABellRoomBell Bell : BellArray)
		{
			Bell.BellRoomBellRung.AddUFunction(this, n"BellRoomBellRung");
		}	
	}

	UFUNCTION()
	void BellRoomBellRung(EBellTone BellTone)
	{
		for (ABellRoomPlatform Platform : BellRoomPlatformArray)
		{
			if (Platform.ConnectedBellTone == BellTone)
				Platform.PlayTimeline();
		}
	}
}