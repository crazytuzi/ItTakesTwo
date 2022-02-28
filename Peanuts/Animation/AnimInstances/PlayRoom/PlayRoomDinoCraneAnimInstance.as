import Cake.LevelSpecific.PlayRoom.GoldBerg.Dino.DinoCrane;
import Peanuts.Animation.AnimationStatics;

class UPlayRoomDinoCraneAnimInstance : UHazeAnimInstanceBase
{

	// Animations
	UPROPERTY(BlueprintReadOnly, Category = "Animations")
    FHazePlaySequenceData Idle;

    UPROPERTY(BlueprintReadOnly, Category = "Animations|Movement")
    FHazePlaySequenceData MhBodyOnly;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Movement")
    FHazePlayBlendSpaceData Movement;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Movement")
    FHazePlayBlendSpaceData Rotation;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlayBlendSpaceData CraneLift;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData GrabEmpty;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData GrabEnter;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData GrabRelease;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlayBlendSpaceData GrabMh;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData EatPlayer;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData EatPlayerAndSlammer;

	UPROPERTY(BlueprintReadOnly, Category = "Animations|Grab")
    FHazePlaySequenceData EatSlammerGrabAdd;


	// NeckAngels
	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "CraneAngels|Current")
	FRotator BaseYaw;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "CraneAngels|Current")
	FRotator BasePitch;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "CraneAngels|Current")
	FRotator Neck;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "CraneAngels|Current")
	FRotator Neck1;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "CraneAngels|Current")
	FRotator Neck2;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "CraneAngels|Current")
	FRotator HeadPitch;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "CraneAngels|Current")
	FRotator HeadYaw;


	// Previous NeckAngels
	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "CraneAngels|Previous")
	FRotator PreviousBaseYaw;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "CraneAngels|Previous")
	FRotator PreviousBasePitch;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "CraneAngels|Previous")
	FRotator PreviousNeck;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "CraneAngels|Previous")
	FRotator PreviousNeck1;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "CraneAngels|Previous")
	FRotator PreviousNeck2;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "CraneAngels|Previous")
	FRotator PreviousHeadPitch;

	UPROPERTY(BlueprintReadOnly, NotEditable, Category = "CraneAngels|Previous")
	FRotator PreviousHeadYaw;


	// Variables
	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector LocalVelocity;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FRotator WheelRotation;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float RotationRate;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float VerticalHeadSpeed;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHasRidingPlayer;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bGrabbedPlatform;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bGrabAir;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bGrabbedChanged;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float GrabbingBlendTime;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bPlayGrabAdditive;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bEatOtherPlayer;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bEatingOtherPlayer;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float GrabChangedTrueBlendTime = 0.f;

	bool bIsEatingOtherPlayer;

	ADinoCrane DinoCrane;
	AHazePlayerCharacter May;
	AHazePlayerCharacter Cody;
	FRotator ActorRotation;
	float HeadZLoaction;

    // On Initialize
	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        DinoCrane = Cast<ADinoCrane>(OwningActor);
		UpdateCraneAngels();
		VerticalHeadSpeed = 0.f;
		Game::GetMayCody(May, Cody);
    }

    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (DinoCrane == nullptr)
            return;

		// Only continue if there is a player riding the DinoCrane
		bHasRidingPlayer = (DinoCrane.RidingPlayer != nullptr);
		if (!bHasRidingPlayer)
		{
			LocalVelocity = FVector::ZeroVector;
			RotationRate = 0.f;
			return;
		}
			

		// Get the actors velocity
		LocalVelocity = OwningActor.GetActorLocalVelocity();

		
		// Calculate wheel rotation
		if (LocalVelocity.Size() > SMALL_NUMBER)
		{
			WheelRotation = FMath::RInterpTo(WheelRotation, LocalVelocity.Rotation(), DeltaTime, 6.f);
		} 
		else 
		{
			// Wheel rotation while only rotating the crane in place
			WheelRotation.Yaw = Math::FWrap(WheelRotation.Yaw - ((OwningActor.ActorRotation - ActorRotation).Normalized.Yaw), 0.f, 360.f);
		}
		ActorRotation = OwningActor.ActorRotation;



		// Check if player is grabbing
		bEatOtherPlayer = GetAnimBoolParam(n"DinoCraneEatingOtherPlayer", true);
		if (bEatOtherPlayer)
		{
			System::SetTimer(this, n"StartEatingPlayer", 0.25f, false);
			bIsEatingOtherPlayer = true;
		}
			
		bGrabAir = GetAnimBoolParam(n"DinoCraneBiting", true);
		bGrabbedChanged = SetBooleanWithValueChangedWatcher(bGrabbedPlatform, (DinoCrane.GrabbedPlatform != nullptr)) || bEatOtherPlayer;
		if (bGrabbedChanged)
		{
			// Grabing state changed, update previous angels
			GrabbingBlendTime = bGrabbedPlatform || bEatOtherPlayer ? 0.25f :  0.5f;
			PreviousBaseYaw.Roll = BaseYaw.Roll;
			PreviousBasePitch.Pitch = BasePitch.Pitch;
			PreviousNeck.Pitch = Neck.Pitch;
			PreviousNeck1.Pitch = Neck1.Pitch;
			PreviousNeck2.Pitch = Neck2.Pitch;
			PreviousHeadPitch.Pitch = HeadPitch.Pitch;
			PreviousHeadYaw.Roll = HeadYaw.Roll;
			GrabChangedTrueBlendTime = 0.f;
			
		}

		// Update the crane angels
		UpdateCraneAngels(DeltaTime);
		

		// Play grab additive anim on the head / neck
		if (bGrabbedPlatform || bGrabAir || bEatOtherPlayer)
		{
			bPlayGrabAdditive = true;
		}
		else if (bPlayGrabAdditive)
		{
			if (TopLevelGraphRelevantStateName == n"Exit")
				bPlayGrabAdditive = false;
		}


		// Rotation Rate
		if (!bGrabbedPlatform && !bIsEatingOtherPlayer)
			RotationRate = (OwningActor.ActorRotation - DinoCrane.RidingPlayer.GetPlayerViewRotation()).Normalized.Yaw;
		else
			RotationRate = 0.f;

    }


	// Update the crane angels
	UFUNCTION()
	void UpdateCraneAngels(float DeltaTime = 1.f)
	{
		if (DinoCrane == nullptr)
			return;
		const FDinoCraneAngles Angels = DinoCrane.CraneAngles;
		BaseYaw.Roll = Angels.BaseYaw;
		BasePitch.Pitch = Angels.BasePitch;
		Neck1.Pitch = FMath::Clamp(Angels.Neck1, -140.f, 0.f);
		Neck2.Pitch = Angels.Neck2;
		HeadPitch.Pitch = Angels.HeadPitch;
		HeadYaw.Roll = Angels.HeadYaw;
		if (DeltaTime != 0.f)
			VerticalHeadSpeed = FMath::Clamp(((Neck.Pitch - Angels.Neck) / DeltaTime) / -40.f, -1.f, 1.f);
		Neck.Pitch = Angels.Neck;
	}

	// Stop playing the grab additive
    UFUNCTION()
	void StopPlayingGrabAdditive()
	{
		bPlayGrabAdditive = false;
	}

	UFUNCTION()
	void StartEatingPlayer()
	{
		bEatingOtherPlayer = true;
	}

	UFUNCTION()
	void AnimNotify_StopEatingPlayer()
	{
		bGrabbedChanged = false;
		bEatingOtherPlayer = false;
		bPlayGrabAdditive = false;
		bIsEatingOtherPlayer = false;
		GrabChangedTrueBlendTime = 0.5f;
	}

}