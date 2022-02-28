import Peanuts.Animation.Features.ClockWork.LocomotionFeatureClockWorkFishingMinigame;
import Cake.LevelSpecific.Clockwork.Fishing.PlayerFishingComponent;
import Peanuts.Animation.AnimationStatics;
import Cake.LevelSpecific.Clockwork.Fishing.RodBaseComponent;
import Cake.LevelSpecific.Clockwork.Fishing.RodBase;

class UClockWorkFishingMinigameAnimInstance : UHazeFeatureSubAnimInstance
{

    UPROPERTY(BlueprintReadOnly, NotEditable)
    ULocomotionFeatureClockWorkFishingMinigame LocomotionFeature;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float TurnInput;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTransform TurningRightHandIKOfsset;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector TurningAlignIKOffset;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	EFishingState FishingState;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float AnticipationExplicitTime;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float ThrowStartTime;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	float ReelInPosition;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FVector CrankIKSocketPosition;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	FTransform ReelingInRightHandOffset;



	float ReelingInCrankPostion;
	UPlayerFishingComponent FishingComp;
	URodBaseComponent RodBaseComp;
	USkeletalMeshComponent RodBaseSkelMesh;

	FTransform CrankOffset;

    // On Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{
		// Valid check the actor
		if (OwningActor == nullptr)
			return;
        
        LocomotionFeature = Cast<ULocomotionFeatureClockWorkFishingMinigame>(GetFeatureAsClass(ULocomotionFeatureClockWorkFishingMinigame::StaticClass()));
		if (LocomotionFeature == nullptr)
			return;


		// Calculate IK values for an IK setup with roll
		FTransform AlignBoneTransform;
		FTransform RightFootTransform;
		Animation::GetAnimBoneTransform(AlignBoneTransform, LocomotionFeature.TurningIKRef.Sequence, n"Align");
		Animation::GetAnimBoneTransform(RightFootTransform, LocomotionFeature.TurningIKRef.Sequence, n"RightFoot_IK");
		TurningAlignIKOffset = AlignBoneTransform.Location - RightFootTransform.Location;

		TurningRightHandIKOfsset = GetIkBoneOffset(LocomotionFeature.TurningIKRef, 0.f, n"Align", n"RightHand");

		FishingComp = UPlayerFishingComponent::Get(OwningActor);
		const ARodBase RodBase = Cast<ARodBase>(FishingComp.RodBase);
		
		RodBaseComp = RodBase.RodBaseComp;
		RodBaseSkelMesh = RodBase.BaseSkeleton;


		// Testing for stuff
		ReelingInRightHandOffset = GetIkBoneOffset(LocomotionFeature.ReelingInIKRef, 0.f, n"RightHand_IK", n"RightHand");


    }
    
    // On Tick Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
        // Valid check the actor
		if (FishingComp == nullptr)
            return;

		

		TurnInput = FishingComp.TargetRotationInput;
		FishingState = FishingComp.FishingState;
		
		if (FishingState == EFishingState::WindingUp)
		{
			AnticipationExplicitTime = RodBaseComp.RodStickRotation.Pitch / 25.f;
			ThrowStartTime = (1.f - AnticipationExplicitTime) / 4.5f;
		}
		else if (FishingState == EFishingState::Reeling || FishingState == EFishingState::Hauling || FishingState == EFishingState::HoldingCatch)
		{
			ReelInPosition = ((1.f- FishingComp.AlphaPlayerReel) * FishingComp.StoredCastPower) / FishingComp.MaxCastPower;
			CrankIKSocketPosition = RodBaseSkelMesh.GetSocketTransform(n"Crank_IK_Socket").Location;
		}

		

    }

    //Can Transition From
    UFUNCTION(BlueprintOverride)
    bool CanTransitionFrom()
    {
        return true;
    }

}