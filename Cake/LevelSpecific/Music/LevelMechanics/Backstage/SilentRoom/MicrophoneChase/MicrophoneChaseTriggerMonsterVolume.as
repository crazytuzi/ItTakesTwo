import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneMonsterSpline;
import Cake.LevelSpecific.Music.LevelMechanics.Backstage.SilentRoom.MicrophoneChase.MicrophoneMonster;

event void FMonsterTriggerDebugTimeTest();
class AMicrophoneChaseTriggerMonsterVolume : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	UBoxComponent BoxCollision;
	default BoxCollision.ShapeColor = FColor::Red;
	default BoxCollision.LineThickness = 20.f;

	UPROPERTY()
	AMicrophoneMonsterSpline SplineToActivate;

	UPROPERTY()
	AMicrophoneMonster MicrophoneMonster;

	UPROPERTY()
	FMonsterTriggerDebugTimeTest MonsterTriggerDebugTimeTest;

	bool bHasBeenTriggered = false;

	UPROPERTY(BlueprintReadOnly)
	float SecondsForMonsterToReachEndOfSpline = 0.f;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		BoxCollision.OnComponentBeginOverlap.AddUFunction(this, n"OnTrigger");
	}

	UFUNCTION(BlueprintOverride)
	void ConstructionScript()
	{
		if (SplineToActivate == nullptr)
			return;
		
		SecondsForMonsterToReachEndOfSpline = SplineToActivate.Spline.GetSplineLength() / SplineToActivate.Speed;
	}

	UFUNCTION()
	void OnTrigger(UPrimitiveComponent OverlappedComponent, AActor OtherActor, 
    UPrimitiveComponent OtherComponent, int OtherBodyIndex, 
    bool bFromSweep, FHitResult& Hit)
	{
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OtherActor);
		
		if (Player == nullptr || bHasBeenTriggered)
			return;
		
		bHasBeenTriggered = true;
		MicrophoneMonster.ActivateMonsterSpline(SplineToActivate);
		MonsterTriggerDebugTimeTest.Broadcast();
	}
}