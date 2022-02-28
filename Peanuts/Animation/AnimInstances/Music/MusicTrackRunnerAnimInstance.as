import Peanuts.Animation.Features.Music.LocomotionFeatureMusicTrackRunner;
import Cake.LevelSpecific.Music.LevelMechanics.Classic.SideContent.TrackRunnerPlayerComponent;
import Peanuts.Animation.AnimationStatics;

class UMusicTrackRunnerAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureMusicTrackRunner Feature;

	UPROPERTY(BlueprintReadOnly)
	bool bRun;

	UPROPERTY(BlueprintReadOnly)
	bool bDashLeft;

	UPROPERTY(BlueprintReadOnly)
	bool bDashRight;

	UPROPERTY(BlueprintReadOnly)
	bool bJump;

	UPROPERTY(BlueprintReadOnly)
	bool bImpact;

	bool bREFjump;
	bool bREFdashL;
	bool bREFdashR;
	bool bREFimpact;
	

	UTrackRunnerPlayerComponent TrackRunnerPlayerComponent;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        Feature = Cast<ULocomotionFeatureMusicTrackRunner>(GetFeatureAsClass(ULocomotionFeatureMusicTrackRunner::StaticClass()));
		TrackRunnerPlayerComponent = Cast<UTrackRunnerPlayerComponent>(OwningActor.GetComponentByClass(UTrackRunnerPlayerComponent::StaticClass()));
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (OwningActor == nullptr)
            return;
		if(TrackRunnerPlayerComponent == nullptr)
			return;

		bRun = TrackRunnerPlayerComponent.bRun;
		bJump = SetBooleanWithValueChangedWatcher(bREFjump, TrackRunnerPlayerComponent.bJump, EHazeBoolValueChangeWatcher::FalseToTrue);
		bDashLeft = SetBooleanWithValueChangedWatcher(bREFdashL, TrackRunnerPlayerComponent.bDashLeft, EHazeBoolValueChangeWatcher::FalseToTrue);
		bDashRight = SetBooleanWithValueChangedWatcher(bREFdashR, TrackRunnerPlayerComponent.bDashRight, EHazeBoolValueChangeWatcher::FalseToTrue);
		bImpact = SetBooleanWithValueChangedWatcher(bREFimpact, TrackRunnerPlayerComponent.bImpact, EHazeBoolValueChangeWatcher::FalseToTrue);
    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }

}