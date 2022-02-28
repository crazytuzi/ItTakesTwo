import Peanuts.Triggers.PlayerTrigger;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.MusicTechWall.MusicTechRoomManager;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.FallingTruss;

event void FLaunchFromTrussManagerSignature();

class ALaunchFromTrussManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	bool bHasTriggeredEvent = false;

	AMusicTechRoomManager MusicTechRoomManager;

	UPROPERTY()
	FLaunchFromTrussManagerSignature StartSequence;

	UPROPERTY()
	APlayerTrigger StartTrussSlideTrigger;

	UPROPERTY()
	APlayerTrigger InsideTrussTrigger;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		InsideTrussTrigger.OnPlayerEnter.AddUFunction(this, n"InsideTrussTriggerEvent");
	}

	UFUNCTION()
	void InsideTrussTriggerEvent(AHazePlayerCharacter Player)
	{
		if (!bHasTriggeredEvent)
		{
			StartSequence.Broadcast();
			bHasTriggeredEvent = true;
		}
	}

	UFUNCTION()
	void SequenceFinished(AMusicTechRoomManager MusicTechRoomManager)
	{
		MusicTechRoomManager.InitMusicTechRoom();
		Game::GetMay().DeactivateCameraByInstigator(this);
		Game::GetCody().DeactivateCameraByInstigator(this);
	}
}