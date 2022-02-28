import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneMonster;

class UMicrophoneMonsterSplineRegion : UHazeSplineRegionComponent
{
	UFUNCTION(BlueprintOverride)
	void OnRegionEntered(AHazeActor EnteringActor)
	{
		AMicrophoneMonster Monster = Cast<AMicrophoneMonster>(EnteringActor);
		Monster.EnterExitLane();
	}
}
