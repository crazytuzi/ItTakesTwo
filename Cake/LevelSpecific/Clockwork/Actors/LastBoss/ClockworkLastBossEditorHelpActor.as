import Cake.LevelSpecific.Clockwork.Actors.LastBoss.ClockworkLastBossMovingObject;
import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.SwingingPendulumEvent.ClockworkLastBossSmasher;
class AClockworkLastBossEditorHelpActor : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	bool bShowIntroState = false;
	bool bShowRewindSmashState = false;

	UFUNCTION(CallInEditor)
	void ToggleIntroState()
	{
		bShowIntroState = !bShowIntroState;

		TArray<AClockworkLastBossMovingObject> ObjArray;
		GetAllActorsOfClass(ObjArray);

		for(AClockworkLastBossMovingObject Obj : ObjArray)
		{
			if (Obj.ClockworkMoveNumber == EClockworkMoveNumber::Move01 || 
				Obj.ClockworkMoveNumber == EClockworkMoveNumber::Move02	||
				Obj.ClockworkMoveNumber == EClockworkMoveNumber::Move03)
			{
				Obj.SelectedKey = bShowIntroState ? 0 : Obj.KeyCount - 1;
				Obj.bScrubKeys = false;
				Obj.Editor_MoveComponentsToSelectedKey();
			}
		}
	}

	UFUNCTION(CallInEditor)
	void ToggleRewindSmasherState()
	{
		bShowRewindSmashState = !bShowRewindSmashState;

		TArray<AClockworkLastBossMovingObject> ObjArray;
		GetAllActorsOfClass(ObjArray);

		for(AClockworkLastBossMovingObject Obj : ObjArray)
		{
			if (Obj.ClockworkMoveNumber == EClockworkMoveNumber::Move05 || 
				Obj.ClockworkMoveNumber == EClockworkMoveNumber::Move06	||
				Obj.ClockworkMoveNumber == EClockworkMoveNumber::Move07)
			{
				Obj.SelectedKey = bShowRewindSmashState ? 0 : Obj.KeyCount - 1;
				Obj.bScrubKeys = false;
				Obj.Editor_MoveComponentsToSelectedKey();
			}
		}
	}	
}