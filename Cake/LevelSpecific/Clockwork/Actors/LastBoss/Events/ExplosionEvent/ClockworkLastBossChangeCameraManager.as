import Cake.LevelSpecific.Clockwork.Actors.LastBoss.Events.ExplosionEvent.ClockworkLastBossChangeCameraVolume;
class AClockworkLastBossChangeCameraManager : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBillboardComponent Root;

	UPROPERTY()
	TArray<AClockworkLastBossChangeCameraVolume> VolumeArray;

	UPROPERTY()
	TArray<AHazeCameraActor> CamArray;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		for (AClockworkLastBossChangeCameraVolume Volume : VolumeArray)
		{
			// Volume.OnChangeCam.AddUFunction(this, n"CamChange");
			// Volume.OnEndCam.AddUFunction(this, n"EndCam");
		}
	} 

	UFUNCTION()
	void CamChange(int CamID)
	{
		FHazeCameraBlendSettings Blend;
		Blend.BlendTime = 0.5f;
		CamArray[CamID - 1].ActivateCamera(Game::GetMay(), Blend, this);
	}

	UFUNCTION()
	void EndCam(int CamID)
	{
		//CamArray[CamID - 1].DeactivateCamera(Game::GetMay());
	}
}