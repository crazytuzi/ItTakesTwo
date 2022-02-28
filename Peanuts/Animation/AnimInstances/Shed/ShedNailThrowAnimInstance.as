
// Imports
import Cake.Weapons.Nail.NailWielderComponent;
import Peanuts.Animation.AnimationStatics;

class ULocomotionFeatureNailStrafeMovement : UHazeLocomotionFeatureBase
{
    default Tag = n"Movement";

    UPROPERTY(Category = "Movement")
    FHazePlayBlendSpaceData MovementBS;

	UPROPERTY(Category = "Aiming")
    FHazePlayBlendSpaceData Unequip;

	UPROPERTY(Category = "Aiming")
    FHazePlayBlendSpaceData Equip;

	UPROPERTY(Category = "Aiming")
    FHazePlayBlendSpaceData Aim_MH;

	UPROPERTY(Category = "Aiming")
    FHazePlaySequenceData Throw;

	UPROPERTY(Category = "Aiming")
    FHazePlaySequenceData ThrowLast;

	UPROPERTY(Category = "Aiming")
    FHazePlayBlendSpaceData Catch;

	UPROPERTY(Category = "Aiming")
    FHazePlaySequenceData CatchedNailRightHand;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData WallMh;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData WallMhSubMerged;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData QuiverMh;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData QuiverMh2;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData QuiverMh3;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData Flying;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData CatchedNail;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData CatchedNail2;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData CatchedNail3;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData UnequipNail;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData UnequipNail2;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData UnequipNail3;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData EquipNail;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData EquipNail2;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData EquipNail3;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData Wiggle;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData Recall;

	UPROPERTY(Category = "Nail Only")
    FHazePlaySequenceData Unequipped;
};

class UShedNailThrowAnimInstance : UHazeFeatureSubAnimInstance 
{

	UPROPERTY(BlueprintReadOnly)
	UNailWielderComponent NailWielderComp; 
	
	UPROPERTY(BlueprintReadOnly, NotEditable)
	ULocomotionFeatureNailStrafeMovement Feature;

	// Variables
	UPROPERTY(BlueprintReadOnly, NotEditable)
	float Speed = 0.0f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bAim = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bCatch = false;
	
	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bLocalCatch = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bThrow = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bLocalThrow = false;

	UPROPERTY()
	bool bCanExit = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsMoving = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bRecallingSingleNail = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bRecallingAllNails = false;

	// float because the currently used AimSpace is only 1D //Sydney
	UPROPERTY(BlueprintReadOnly)
	float AimSpace_Pitch = 0.f;

	// How fast the player is rotating 
	UPROPERTY(BlueprintReadOnly)
	float AimRotationSpeed = 0.f;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bEquip = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bUnequip = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	int NailEquipIndex = -1;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bHasNailEquippedToHand = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsNailEquippedToHand = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bNoNailsEquipped = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bFirstNail = false;

	UPROPERTY(BlueprintReadOnly, NotEditable)
	bool bIsNailEquippedAtAll = false;

	// UPROPERTY(BlueprintReadOnly, NotEditable)
	// FTransform NailSocketPos;

	// AHazePlayerCharacter player;

	UPROPERTY()
	bool bCodyEquip = false;

	// Initialize
	UFUNCTION(BlueprintOverride)	
	void BlueprintInitializeAnimation()
	{		
		if(OwningActor == nullptr)
			return;

		// player = Cast<AHazePlayerCharacter>(OwningActor);
		Feature = Cast<ULocomotionFeatureNailStrafeMovement>(GetFeatureAsClass(ULocomotionFeatureNailStrafeMovement::StaticClass()));
		NailWielderComp = UNailWielderComponent::GetOrCreate(OwningActor);
		bCanExit = false;
		SetAnimBoolParam(n"GoToStop", false);
		SetAnimBoolParam(n"GoToMovement", false);
		SetAnimBoolParam(n"GoToMovementVar2", false);
		SetAnimBoolParam(n"GoToMovementDefault", true);
	}

	UFUNCTION(BlueprintOverride)
	float GetBlendTimeOutToMovement() const
	{
		return GetAnimFloatParamConst(n"BlendToMovement");
	}

	// Update
	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if(OwningActor == nullptr)
			return;

		Speed = GetAnimationUpdateParams().Speed;		

		bEquip = GetAnimBoolParam(n"NailEquip", true);
		bUnequip = GetAnimBoolParam(n"NailUnequip", true);
		NailEquipIndex = GetAnimIntParam(n"AssignedIndex", true);
		bNoNailsEquipped = GetAnimBoolParam(n"NoNailsEquipped", true);
		bHasNailEquippedToHand = GetAnimBoolParam(n"NailEquippedToHand", true);
		bIsNailEquippedToHand = NailWielderComp.HasNailEquippedToHand(); 
		bIsNailEquippedAtAll = NailWielderComp.HasNailsEquipped();


		AimRotationSpeed = GetAnimFloatParam(n"AimRotationSpeed", true);

		bThrow = GetAnimBoolParam(n"NailThrow", true);
		bCatch = GetAnimBoolParam(n"NailCatch", true);
		bAim= GetAnimBoolParam(n"NailAiming", true);

		bLocalCatch = MovementName::IsFeatureTagEqualTo(GetAnimationUpdateParams().LocomotionTag, n"NailCatch");
		bLocalThrow = MovementName::IsFeatureTagEqualTo(GetAnimationUpdateParams().LocomotionTag, n"NailThrow");

		bRecallingAllNails = GetAnimBoolParam(n"RecallingAllNails", true);
		bRecallingSingleNail = GetAnimBoolParam(n"RecallingSingleNail", true);

		AimSpace_Pitch = GetAnimFloatParam(n"AimSpacePitch", true);
		AimSpace_Pitch = FMath::Clamp(AimSpace_Pitch, -45,45);

		bFirstNail = (NailWielderComp.GetNumNailsEquipped() == 1 && bCatch);
		//Print(""+NailWielderComp.NailEquippedToHand);
		//NailSocketPos = player.Mesh.GetSocketTransform(n"NailSocket");
		//Print(""+player);

		if(Speed < 3){
			bIsMoving = false;
		}
		else{
			bIsMoving = true;
		}		

	}

}