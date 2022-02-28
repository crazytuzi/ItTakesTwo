import Cake.LevelSpecific.Music.LevelMechanics.Backstage.TutorialRoom.BackstageTapeRecorderWall;
import Peanuts.Animation.AnimationStatics;

class UMusicBackStageTapeRecorderWallAnimInstance : UHazeAnimInstanceBase
{

    UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Mh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData MhLeftCutOff;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData MhRightCutOff;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData MhBothCutOff;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData Shout;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
	FHazePlaySequenceData ShoutRightBandBroken;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData SongOfLife;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData FallDown;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData BandBreak;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData BandBreakLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData BandBreakRight;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData BandBreakFinalLeft;

	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData BandBreakFinalRight;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bLeftBandCutOff;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bRightBandCutOff;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bBandsCutOff;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bSongOfLifeActive;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bShoutHitThisTick;
	bool bShoutReaction;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayingShoutReaction;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bFallDown;

	ABackstageTapeRecorderWall TapeRecorderActor;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
		TapeRecorderActor = Cast<ABackstageTapeRecorderWall>(OwningActor);
		bFallDown = false;
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (TapeRecorderActor == nullptr)
			return;

		bFallDown = TapeRecorderActor.bFallDown;
		if (bFallDown)
			return;

		// Left / Right is inverted on the actor (:
		bLeftBandCutOff = TapeRecorderActor.bRightBandCutOff;
		bRightBandCutOff = TapeRecorderActor.bLeftBandCutOff;
		bBandsCutOff =  TapeRecorderActor.bBandsCutOff;

		bSongOfLifeActive = TapeRecorderActor.bSongOfLifeActive;
		bShoutHitThisTick = SetBooleanWithValueChangedWatcher(bShoutReaction, TapeRecorderActor.bWiggle, EHazeBoolValueChangeWatcher::FalseToTrue);
		if (bShoutHitThisTick)
			bPlayingShoutReaction = true;
	
    }

	UFUNCTION()
	void StopPlayingShoutAnim()
	{
		bPlayingShoutReaction = false;
	}
    

}