import Peanuts.Triggers.PlayerTrigger;
import Cake.LevelSpecific.SnowGlobe.SnowAngel.SnowAngelDyingSnowFolk;

class ASnowAngelDyingSnowFolkTrigger : APlayerTrigger
{
	UPROPERTY()
	ASnowAngelDyingSnowFolk DyingSnowFolk;

	void EnterTrigger(AActor Actor) override
    {
		if (DyingSnowFolk == nullptr)
			return; 

		DyingSnowFolk.bIsDead = true;
		DyingSnowFolk.HazeAkComp.HazePostEvent(DyingSnowFolk.StopDyingAudioEvent);
    }

    void LeaveTrigger(AActor Actor) override
    {


    }

}