//Basic Noise Emitter which registers with the Perception Component. More Functionality can be added.
class UHazeNoiseEmitter : UActorComponent
{
    void MakeNoise(AHazeActor NoiseMaker, float Loudness)
    {
        if (NoiseMaker == nullptr || Loudness <= 0.f)
	    {
		    return;
	    }

	    UHazeGameInstance GameInstance = Game::GetHazeGameInstance();
	    if (!ensure(GameInstance != nullptr))
		    return;

	    UHazeAIManager AIManager = GameInstance.GetAIManager();
	    if (!ensure(AIManager != nullptr))
		    return;

	    AIManager.NotifyPereceptionComponent(NoiseMaker, Loudness);
    }
}