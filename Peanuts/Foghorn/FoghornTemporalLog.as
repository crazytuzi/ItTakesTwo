import Peanuts.Foghorn.FoghornManager;
import Rice.TemporalLog.TemporalLogComponent;

class UFoghornTemporalLog : UTemporalLogAction
{
	void Log(AHazeActor Actor, UTemporalLogComponent Log) const
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(Actor);
		if (Player != nullptr && Player.IsMay())
		{
			UFoghornManagerComponent FoghornManager = UFoghornManagerComponent::Get(Actor);
			UTemporalLogObject LogObject = Log.LogObject(n"Foghorn", FoghornManager, bLogProperties = false);

			FoghornManager.DebugTemporalLog(LogObject);
		}
	}
};