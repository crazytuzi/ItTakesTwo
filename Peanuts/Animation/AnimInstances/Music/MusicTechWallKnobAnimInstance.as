import Peanuts.Animation.Features.Music.LocomotionFeatureMusicCodyTechWallKnobs;
import Peanuts.Animation.AnimationStatics;

class UMusicTechWallKnobAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureMusicCodyTechWallKnobs LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FRotator LeftDiskRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    FRotator RightDiskLocation;
	
	UPROPERTY(BlueprintReadOnly, NotEditable)
    float LeftDiskAnimTime;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    float RightDiskAnimTime;

	UPROPERTY(BlueprintReadOnly, NotEditable)
    bool bPlayExit;

	bool bHasControl = false;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureMusicCodyTechWallKnobs>(GetFeatureAsClass(ULocomotionFeatureMusicCodyTechWallKnobs::StaticClass()));

		// Check if host or remote
		AHazePlayerCharacter Player = Cast<AHazePlayerCharacter>(OwningActor);
		if (Player != nullptr)
			bHasControl = Player.HasControl();

		bPlayExit = false;

		// Set initial rotation
		LeftDiskRotation.Yaw = 220.f;
		LeftDiskAnimTime = LeftDiskRotation.Yaw / 360.f;
		RightDiskLocation.Yaw = 300.f;
		RightDiskAnimTime = RightDiskLocation.Yaw / 360.f;
    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (LocomotionFeature == nullptr)
            return;

		if (bHasControl)
		{
			CalculateValuesOnControlSide(DeltaTime);
		}
		else
		{
			CalculateValuesOnRemoteSide(DeltaTime);
		}

    }
	
	// Get all values if player is remote
	UFUNCTION()
	void CalculateValuesOnRemoteSide(float DeltaTime)
	{
		LeftDiskRotation.Yaw = -GetAnimFloatParam(n"LeftWheelRotation", true) * 7.f;
		LeftDiskRotation.Yaw = Math::FWrap(LeftDiskRotation.Yaw, 0.f, 360.f);
		LeftDiskAnimTime = LeftDiskRotation.Yaw / 360.f;

		RightDiskLocation.Yaw = -GetAnimFloatParam(n"RightWheelRotation", true) * 7.f;
		RightDiskLocation.Yaw = Math::FWrap(RightDiskLocation.Yaw, 0.f, 360.f);
		RightDiskAnimTime = RightDiskLocation.Yaw  / 360.f;
	}

	// Get all values if player is host
	UFUNCTION()
	void CalculateValuesOnControlSide(float DeltaTime)
	{
		const FVector LeftStickInput = GetAnimVectorParam(n"LeftStickInput", true);
		const FVector RightStickInput = GetAnimVectorParam(n"RightStickInput", true);

		const bool bUsingLeftStick = (LeftStickInput.Size() > .5f);
		const bool bUsingRighttStick = (RightStickInput.Size() > .5f);

		if (bUsingLeftStick)
		{
			const float WantedDiskRotation = -LeftStickInput.Rotation().Yaw + 180.f;
			LeftDiskRotation.Yaw = CircularBlendspaceInterpolation(LeftDiskRotation.Yaw, WantedDiskRotation, DeltaTime, 0.f, 360.f, 7.5f);
			LeftDiskAnimTime = LeftDiskRotation.Yaw / 360.f;
		}

		if (bUsingRighttStick)
		{
			const float WantedDiskRotation = -RightStickInput.Rotation().Yaw + 180.f;
			RightDiskLocation.Yaw = CircularBlendspaceInterpolation(RightDiskLocation.Yaw, WantedDiskRotation, DeltaTime, 0.f, 360.f, 7.5f);
			RightDiskAnimTime = RightDiskLocation.Yaw  / 360.f;
		}
	}


    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
		bPlayExit = true;
        return true;
    }

}