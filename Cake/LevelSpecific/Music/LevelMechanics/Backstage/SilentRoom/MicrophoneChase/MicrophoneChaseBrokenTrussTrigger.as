import Cake.Environment.Breakable;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneMonster;
event void FTrussBroke();
class AMicrophoneChaseBrokenTrussTrigger : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent Box;

	UPROPERTY()
	AActor TrussToBreak;

	UPROPERTY()
	bool bShouldPlayCameraShake = false;

	UPROPERTY()
	TSubclassOf<UCameraShakeBase> CamShake;

	bool bHasTriggered = false;
	
	UPROPERTY()
	TArray<ABreakableActor> BreakableArray;

	UPROPERTY()
	FTrussBroke TrussBrokeEvent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Box.OnComponentBeginOverlap.AddUFunction(this, n"BoxOverlap");
	}

	UFUNCTION()
	void BoxOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AMicrophoneMonster Monster = Cast<AMicrophoneMonster>(OtherActor);
		if (Monster == nullptr || bHasTriggered)
			return;

		TrussBrokeEvent.Broadcast();
		
		bHasTriggered = true;

		if (bShouldPlayCameraShake)
			Game::GetCody().PlayCameraShake(CamShake);

		if (TrussToBreak != nullptr)
			TrussToBreak.DestroyActor();
		
		if (BreakableArray.Num() > 0)
		{
			FBreakableHitData HitData;
			for(auto Break : BreakableArray)
				Break.BreakableComponent.Break(HitData);
		}
	}
}