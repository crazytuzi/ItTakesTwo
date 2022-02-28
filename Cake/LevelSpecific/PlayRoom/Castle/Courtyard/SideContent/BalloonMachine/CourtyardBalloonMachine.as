
import Cake.LevelSpecific.PlayRoom.Castle.Courtyard.SideContent.BalloonMachine.CourtyardBalloon;
class ACourtyardBalloonMachine : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UStaticMeshComponent Mesh;

	UPROPERTY(DefaultComponent)
	USceneComponent BalloonSpawnPoint;

	UPROPERTY(DefaultComponent)
	UHazeAkComponent HazeAkComp;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent MachineStartAudioEvent;

	UPROPERTY(Category = "Audio Events")
	UAkAudioEvent InflateAudioEvent;

#if EDITOR
	UPROPERTY(DefaultComponent, Attach = BalloonSpawnPoint)
	UStaticMeshComponent DebugBalloon;
	default DebugBalloon.bHiddenInGame = true;
	default DebugBalloon.SetCollisionEnabled(ECollisionEnabled::NoCollision);
#endif

	bool bActive = false;

	UPROPERTY()
	ACourtyardBalloon Balloon;

	UFUNCTION()
	void ActivateBalloonMachine()
	{
		if (!HasControl())
			return;

		NetActivateBalloonMachine();
	}

	UFUNCTION(NetFunction)
	void NetActivateBalloonMachine()
	{
		bActive = true;
		HazeAkComp.HazePostEvent(MachineStartAudioEvent);
	}	
}