import Peanuts.Animation.Features.SnowGlobe.LocomotionFeatureSnowGlobeWindWalk;
import Cake.LevelSpecific.SnowGlobe.WindWalk.WindWalkComponent;
import Peanuts.Animation.AnimationStatics;

class USnowGlobeWindWalkAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureSnowGlobeWindWalk LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator RootRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector Velocity;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float WindDirection;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bSkipEnter;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bUsingMagnet;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bEnableRootRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTransform LeftHandIKOffset;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTransform RightHandIKOffset;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTransform OtherMagnetTransform;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTransform MagnetOffset;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsTopTotemPlayer;

	UWindWalkComponent WindWalkComp;
	AHazePlayerCharacter OtherPlayer;

	float CustomBlendTime = 0.15f;
	bool bExitingABP;
	bool bAllowedExit;


    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;

        LocomotionFeature = Cast<ULocomotionFeatureSnowGlobeWindWalk>(GetFeatureAsClass(ULocomotionFeatureSnowGlobeWindWalk::StaticClass()));
		WindWalkComp = UWindWalkComponent::Get(OwningActor);
		if (WindWalkComp == nullptr) 
			return;

		WindDirection = GetRelativeWindDirection();
		SetAnimFloatParam(n"BlendToMovement", 0.2f);

		OtherPlayer = (Game::GetCody() == OwningActor) ? Game::GetMay() : Game::GetCody();

		CustomBlendTime = 0.15;
		bEnableRootRotation = false;
		bExitingABP = false;
		bAllowedExit = false;
		bSkipEnter = GetAnimBoolParam(n"SkipWindWalkEnter", true);
		if (bSkipEnter)
			CustomBlendTime = .6f;

		if (GetAnimBoolParam(n"FromWindWalkDash", true))
		{
			CustomBlendTime = 0.15f;
			bEnableRootRotation = !LocomotionFeature.bIsTotemRiding;
			return;
		}

		RootRotation = GetWantedRootRotation();

		if (!bEnableRootRotation)
		{
			System::SetTimer(this, n"EnableRootRotation", 0.03f, false);
		}

		// IK
		bIsTopTotemPlayer = LocomotionFeature.bIsTotemRiding;
		if (!bIsTopTotemPlayer)
		{
			LeftHandIKOffset = GetIkBoneOffset(LocomotionFeature.IKRef, 0.f, n"Backpack", n"LeftHand");
			RightHandIKOffset = GetIkBoneOffset(LocomotionFeature.IKRef, 0.f, n"Backpack", n"RightHand");
		}
		else
		{
			MagnetOffset = GetIkBoneOffset(LocomotionFeature.IKRef, 0.f, n"Align", n"Backpack");
		}

    }
    

	// Get Blend Time
	UFUNCTION(BlueprintOverride)
	float GetBlendTime() const
	{
		return CustomBlendTime;
	}
	

    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (WindWalkComp == nullptr)
            return;

		WindDirection = CircularBlendspaceInterpolation(WindDirection, GetRelativeWindDirection(), DeltaTime, 0.f, 360.f, 3.5f);
		bUsingMagnet = (WindWalkComp.ActiveMagnetLocation != FVector::ZeroVector) && !IsMagnetStrafeRequested();

		if (bIsTopTotemPlayer)
		{
			Velocity = GetAnimVectorParam(n"TotemVelocity", true);
			OtherMagnetTransform = OtherPlayer.Mesh.GetSocketTransform(n"Backpack");
		}
		else
		{
			RootRotation = FMath::RInterpTo(RootRotation, GetWantedRootRotation(), DeltaTime, 10.f);
			Velocity = GetActorLocalVelocity(OwningActor);
			OtherPlayer.SetAnimVectorParam(n"TotemVelocity", Velocity);
		}

		if (bExitingABP)
		{
			if (LocomotionAnimationTag == n"WindWalk")
				bExitingABP = false;
		}

    }


    // Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
		if (!bExitingABP)
		{
			System::SetTimer(this, n"AllowExit", 0.15f, false);
			bExitingABP = true;
		}

		bEnableRootRotation = false;
		if (TopLevelGraphRelevantStateName == n"Walking" && bAllowedExit)
        	return true;

		if (IsMagnetStrafeRequested() && bAllowedExit)
			return true;

		return (LocomotionAnimationTag != n"Movement");
    }


	// On Transistion From
	UFUNCTION(BlueprintOverride)
    void OnTransitionFrom(UHazeFeatureSubAnimInstance NewSubAnimInstance)
    {
		// If we're going into magnet strafe, skip the start anim
		if (IsMagnetStrafeRequested())
		{
			SetAnimBoolParam(n"SkipMagnetEquip", true);
			SetAnimFloatParam(n"MagnetEquipBlend", 0.4f);
		}

    }


	// Called once the ABP has entered the "Magnet" state
	UFUNCTION()
	void AnimNotify_EnteredMagnetState()
	{
		bSkipEnter = false;
	}
	

	// Get the direction the wind is blowing relative to the actor
	UFUNCTION(BlueprintPure)
	float GetRelativeWindDirection()
	{
		FRotator DeltaRotation = (WindWalkComp.GetWindForce().Rotation() - OwningActor.GetActorRotation());
		DeltaRotation.Normalize();

		if (DeltaRotation.Yaw < 0.f) 
			return DeltaRotation.Yaw + 360.f;
		
		return DeltaRotation.Yaw;
	}


	// Enable the root rotation
	UFUNCTION()
	void EnableRootRotation()
	{
		bEnableRootRotation = !bIsTopTotemPlayer;
	}

	// Check if the manget strafe moveset is beeing requested
	UFUNCTION(BlueprintPure)
	bool IsMagnetStrafeRequested()
	{
		return (LocomotionAnimationTag == n"MagnetStrafe" ||
			LocomotionAnimationTag == n"MagnetStrafeTotem");
	}


	// Get the wanted rotation to align the character with the ground/slope
	UFUNCTION(BlueprintPure)
	FRotator GetWantedRootRotation()
	{
		return Math::MakeRotFromZX(WindWalkComp.GroundNormal, OwningActor.ActorForwardVector);
	}

	// Get the wanted rotation to align the character with the ground/slope
	UFUNCTION()
	void AllowExit()
	{
		bAllowedExit = true;
	}


}