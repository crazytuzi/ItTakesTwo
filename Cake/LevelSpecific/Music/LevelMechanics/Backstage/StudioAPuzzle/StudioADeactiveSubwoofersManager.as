// import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioAPuzzle.StudioABlockingPlatform;
// import Cake.LevelSpecific.Music.LevelMechanics.CymbalButton;
// import Cake.LevelSpecific.Music.LevelMechanics.Backstage.StudioAPuzzle.StudioAPushingSpeaker;

// class AStudioADeactivateSubwoofersManager : AHazeActor
// {
// 	UPROPERTY(DefaultComponent, RootComponent)
// 	UBillboardComponent Root;

// 	UPROPERTY()
// 	ACymbalButton CymbalButton;

// 	TArray<AStudioABlockingPlatform> BlockingPlatformArray;
// 	TArray<AStudioAPushingSpeaker> PushingSpeakerArray;

// 	UFUNCTION(BlueprintOverride)
// 	void BeginPlay()
// 	{
// 		CymbalButton.OnButtonActivated.AddUFunction(this, n"ButtonActivated");
// 		SetReferences();
// 	}

// 	UFUNCTION()
// 	void SetReferences()
// 	{
// 		TArray<AStudioABlockingPlatform> TempPlatformArray;
// 		AStudioABlockingPlatform::GetAll(TempPlatformArray);

// 		for (AStudioABlockingPlatform Platform : TempPlatformArray)
// 		{
// 			BlockingPlatformArray.Add(Platform);
// 		}
		
// 		TArray<AStudioAPushingSpeaker> TempSpeakerArray;
// 		AStudioAPushingSpeaker::GetAll(PushingSpeakerArray);

// 		for (AStudioAPushingSpeaker Speaker : TempSpeakerArray)
// 		{
// 			PushingSpeakerArray.Add(Speaker);
// 		}
// 	}

// 	UFUNCTION()
// 	void ButtonActivated(bool bButtonActive)
// 	{
// 		for (AStudioABlockingPlatform Platform : BlockingPlatformArray)
// 		{
// 			Platform.MovePlatform(bButtonActive);
// 			Platform.SetBlockingPlatformDisabled(bButtonActive);
// 		}

// 		for (AStudioAPushingSpeaker Speaker : PushingSpeakerArray)
// 		{
// 			Speaker.SetSpeakerActive(!bButtonActive);
// 		}
// 	}
// }